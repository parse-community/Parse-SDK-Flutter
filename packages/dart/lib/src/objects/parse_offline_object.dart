part of '../../parse_server_sdk.dart';

/// Outcome of [ParseObjectOffline.syncLocalCacheWithServer].
///
/// Exists so callers get a failure signal without having to read the log: a
/// void return made an unsuccessful `save()` indistinguishable from a clean
/// sync, and unsynced edits could be treated as persisted.
class ParseOfflineSyncResult {
  ParseOfflineSyncResult({
    required this.synced,
    required this.skipped,
    required this.failures,
  });

  /// Objects successfully saved to the server.
  final int synced;

  /// Objects rejected by the `shouldSync` predicate.
  final int skipped;

  /// The objects whose `save()` did not succeed, with the reported error.
  final List<ParseOfflineSyncFailure> failures;

  /// True when at least one object failed to save.
  bool get hasFailures => failures.isNotEmpty;

  @override
  String toString() =>
      'ParseOfflineSyncResult(synced: $synced, skipped: $skipped, '
      'failures: ${failures.length})';
}

/// A single failed save from [ParseObjectOffline.syncLocalCacheWithServer].
class ParseOfflineSyncFailure {
  ParseOfflineSyncFailure(this.object, this.error);

  final ParseObject object;
  final ParseError? error;

  @override
  String toString() =>
      'ParseOfflineSyncFailure(${object.objectId}: ${error?.message})';
}

/// Serialises read-modify-write sequences per cache key.
///
/// Every mutating operation loads the whole map, edits it, then writes the
/// whole map back. Without this, two concurrent calls both read the same
/// starting state and the second write silently discards the first one's
/// change. Reads take the lock too, because [_loadMap] itself writes when it
/// migrates the legacy format.
final Map<String, Future<void>> _offlineCacheLocks = <String, Future<void>>{};

Future<R> _withOfflineCacheLock<R>(
  String cacheKey,
  Future<R> Function() action,
) {
  final Future<void> previous =
      _offlineCacheLocks[cacheKey] ?? Future<void>.value();
  final Completer<void> release = Completer<void>();
  _offlineCacheLocks[cacheKey] = release.future;
  return previous.then((_) => action()).whenComplete(() {
    release.complete();
    // Only drop the entry if nobody queued behind us, otherwise the next
    // waiter would lose its place in the chain.
    if (identical(_offlineCacheLocks[cacheKey], release.future)) {
      _offlineCacheLocks.remove(cacheKey);
    }
  });
}

String _offlineCacheKey(String className) {
  final String? namespace = ParseObjectOffline.cacheNamespace;
  if (namespace == null || namespace.isEmpty) {
    return 'offline_cache_$className';
  }
  // ':' as the separator, and the namespace percent-encoded. Joining with '_'
  // was ambiguous, because class names legitimately contain underscores
  // (_User, _Installation): namespace 'a_b' + class 'c' and namespace 'a' +
  // class 'b_c' both produced 'offline_cache_a_b_c', so two accounts could
  // land in one bucket — exactly what the namespace exists to prevent.
  // Uri.encodeComponent escapes ':' (and '%'), and Parse class names cannot
  // contain ':', so the two halves can never be confused.
  return 'offline_cache_${Uri.encodeComponent(namespace)}:$className';
}

/// Storage key holding the map-format cache for [cacheKey].
///
/// ':' for the same reason as the namespace boundary: with the old
/// `'${cacheKey}_v2'` a class genuinely named `X_v2` produced
/// `offline_cache_X_v2`, which is the live map key of class `X`, so
/// `clearLocalCacheForClass('X_v2')` wiped class `X`.
String _offlineMapKey(String cacheKey) => '$cacheKey:v2';

/// The superseded `_v2` suffix, still read once so existing caches migrate
/// rather than silently emptying.
String _legacyOfflineMapKey(String cacheKey) => '${cacheKey}_v2';

extension ParseObjectOffline on ParseObject {
  /// Namespace applied to every offline cache key, for separating the caches
  /// of different accounts in the same app.
  ///
  /// The cache is plain local storage and [loadFromLocalCache] reads it
  /// directly, so it is NOT subject to the server's access checks. With a
  /// persistent [CoreStore] and no namespace, objects cached by one user stay
  /// readable after switching to another account.
  ///
  /// Set this to a stable per-account value (for example the user's objectId)
  /// on login, and call [clearLocalCacheForNamespace] on logout if the cached
  /// data should not outlive the session. Leave it null for single-account
  /// apps, which keeps the historic key layout.
  static String? cacheNamespace;

  // ─── Single-object operations ────────────────────────────────────────────

  /// Save this object to local storage for offline access.
  Future<void> saveToLocalCache() async {
    if (objectId == null) {
      if (isDebugEnabled()) {
        print(
          'ParseObjectOffline.saveToLocalCache: skipping object with no objectId '
          'for $parseClassName',
        );
      }
      return;
    }
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(parseClassName);
    final String id = objectId!;
    final String encoded = json.encode(toJson(full: true));
    await _withOfflineCacheLock(cacheKey, () async {
      final Map<String, String> map = await _loadMap(store, cacheKey);
      map[id] = encoded;
      await _saveMap(store, cacheKey, map);
    });
    if (isDebugEnabled()) {
      print('ParseObjectOffline: saved $id to cache for $parseClassName');
    }
  }

  /// Remove this object from local storage.
  Future<void> removeFromLocalCache() async {
    if (objectId == null) return;
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(parseClassName);
    final String id = objectId!;
    final bool removed = await _withOfflineCacheLock(cacheKey, () async {
      final Map<String, String> map = await _loadMap(store, cacheKey);
      if (map.remove(id) == null) return false;
      await _saveMap(store, cacheKey, map);
      return true;
    });
    if (removed && isDebugEnabled()) {
      print('ParseObjectOffline: removed $id from cache for $parseClassName');
    }
  }

  /// Partially update a cached object's fields without a full re-encode.
  ///
  /// Returns `true` if the object was found and updated.
  Future<bool> updateInLocalCache(Map<String, dynamic> updates) async {
    if (objectId == null) return false;
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(parseClassName);
    final String id = objectId!;
    return _withOfflineCacheLock(cacheKey, () async {
      final Map<String, String> map = await _loadMap(store, cacheKey);
      final String? existing = map[id];
      if (existing == null) return false;
      try {
        final Map<String, dynamic> obj =
            json.decode(existing) as Map<String, dynamic>;
        // Cached entries are written as `json.encode(toJson(full: true))`, so
        // they hold Parse wire format. Raw values (DateTime, ParseObject,
        // ParseGeoPoint, nested Maps) would either fail to encode here or
        // decode back differently from a server response, so run the caller's
        // values through the same encoder first.
        updates.forEach((String key, dynamic value) {
          obj[key] = parseEncode(value, full: true);
        });
        map[id] = json.encode(obj);
        await _saveMap(store, cacheKey, map);
        if (isDebugEnabled()) {
          print('ParseObjectOffline: updated $id in cache for $parseClassName');
        }
        return true;
      } catch (e) {
        if (isDebugEnabled()) {
          print('ParseObjectOffline.updateInLocalCache: error for $id: $e');
        }
        return false;
      }
    });
  }

  // ─── Batch / static operations ───────────────────────────────────────────

  /// Load a single object by objectId from local storage. O(1) lookup.
  static Future<ParseObject?> loadFromLocalCache(
    String className,
    String objectId,
  ) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    final String? raw = await _withOfflineCacheLock(cacheKey, () async {
      final Map<String, String> map = await _loadMap(store, cacheKey);
      return map[objectId];
    });
    if (raw == null) return null;
    try {
      return ParseObject(
        className,
      ).fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (e) {
      if (isDebugEnabled()) {
        print(
          'ParseObjectOffline.loadFromLocalCache: corrupt entry for $objectId '
          'in $className — $e',
        );
      }
      return null;
    }
  }

  /// Load every cached object of [className].
  ///
  /// The offline store holds one bucket per class, so callers that only want a
  /// subset (e.g. the messages of ONE conversation) can pass [where] to filter
  /// during the load — non-matching entries are skipped without being added to
  /// the result. Without it, ALL cached objects of the class are returned.
  static Future<List<ParseObject>> loadAllFromLocalCache(
    String className, {
    bool Function(ParseObject object)? where,
  }) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    final Map<String, String> map = await _withOfflineCacheLock(
      cacheKey,
      () => _loadMap(store, cacheKey),
    );
    final List<ParseObject> results = [];
    for (final entry in map.entries) {
      try {
        final ParseObject object = ParseObject(
          className,
        ).fromJson(json.decode(entry.value) as Map<String, dynamic>);
        if (where == null || where(object)) {
          results.add(object);
        }
      } catch (e) {
        if (isDebugEnabled()) {
          print(
            'ParseObjectOffline.loadAllFromLocalCache: skipping corrupt entry '
            '${entry.key} for $className — $e',
          );
        }
      }
    }
    if (isDebugEnabled()) {
      print(
        'ParseObjectOffline: loaded ${results.length} objects from cache for '
        '$className${where != null ? ' (filtered)' : ''}',
      );
    }
    return results;
  }

  /// Save a batch of objects efficiently. O(1) per object — no re-read needed.
  static Future<void> saveAllToLocalCache(
    String className,
    List<ParseObject> objects,
  ) async {
    if (objects.isEmpty) return;
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);

    await _withOfflineCacheLock(cacheKey, () async {
      final Map<String, String> map = await _loadMap(store, cacheKey);
      int added = 0;
      int updated = 0;
      int failed = 0;
      for (final obj in objects) {
        final id = obj.objectId;
        if (id == null) {
          if (isDebugEnabled()) {
            print(
              'ParseObjectOffline.saveAllToLocalCache: skipping object without '
              'objectId for $className',
            );
          }
          continue;
        }
        // Encode each object independently so one bad object (e.g. a value that
        // fails to serialize) can't abort the whole batch and prevent every other
        // item — including a freshly-added one — from being cached.
        try {
          final encoded = json.encode(obj.toJson(full: true));
          map.containsKey(id) ? updated++ : added++;
          map[id] = encoded;
        } catch (e) {
          failed++;
          if (isDebugEnabled()) {
            print(
              'ParseObjectOffline.saveAllToLocalCache: skipping object $id '
              '(createdAt=${obj.createdAt?.toIso8601String()}) for '
              '$className — encode failed: $e',
            );
          }
        }
      }

      await _saveMap(store, cacheKey, map);
      if (isDebugEnabled()) {
        print(
          'ParseObjectOffline: batch saved to $className. '
          'Added: $added, Updated: $updated, Failed: $failed, '
          'Total: ${map.length}',
        );
      }
    });
  }

  /// Returns all cached objectIds for a class. O(1) — no JSON decoding.
  static Future<List<String>> getAllObjectIdsInLocalCache(
    String className,
  ) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    final Map<String, String> map = await _withOfflineCacheLock(
      cacheKey,
      () => _loadMap(store, cacheKey),
    );
    return map.keys.toList();
  }

  /// Returns true if an object with the given id exists in the cache. O(1).
  static Future<bool> existsInLocalCache(
    String className,
    String objectId,
  ) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    final Map<String, String> map = await _withOfflineCacheLock(
      cacheKey,
      () => _loadMap(store, cacheKey),
    );
    return map.containsKey(objectId);
  }

  /// Wipes the entire cache for a class, in the current [cacheNamespace].
  static Future<void> clearLocalCacheForClass(String className) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    await _withOfflineCacheLock(cacheKey, () async {
      // Remove EVERY format. Reads and writes go through the map key, so
      // dropping only the legacy list key left the actual cache fully intact
      // and made this a silent no-op.
      await store.remove(_offlineMapKey(cacheKey));
      await store.remove(_legacyOfflineMapKey(cacheKey));
      // The oldest list-format key is the bare cacheKey — but for a class
      // named 'X_v2' that is 'offline_cache_X_v2', which is also class X's
      // UNMIGRATED map. Removing it blindly would delete X's cache before X
      // ever loaded. A list-format entry is a StringList and a map is a
      // String, so only drop it when it really is a list.
      if (await store.getStringList(cacheKey) != null) {
        await store.remove(cacheKey);
      }
    });
    if (isDebugEnabled()) {
      print('ParseObjectOffline: cleared cache for $className');
    }
  }

  /// Wipes the cache of every [classNames] entry for the current
  /// [cacheNamespace]. Call this on logout when cached data should not outlive
  /// the session.
  ///
  /// The store has no key enumeration, so the classes to clear must be named.
  static Future<void> clearLocalCacheForNamespace(
    List<String> classNames,
  ) async {
    for (final String className in classNames) {
      await clearLocalCacheForClass(className);
    }
  }

  /// Pushes every cached object of [className] to the server.
  ///
  /// Only call this when you know the local copy is authoritative (e.g. after
  /// collecting edits while offline). Objects whose server version may be newer
  /// should be reconciled before calling this.
  ///
  /// Returns a [ParseOfflineSyncResult]; check [ParseOfflineSyncResult.hasFailures]
  /// before treating the local edits as persisted.
  static Future<ParseOfflineSyncResult> syncLocalCacheWithServer(
    String className, {
    bool Function(ParseObject obj)? shouldSync,
  }) async {
    // Loaded via fromJsonForManualObject, NOT fromJson. `fromJson` only fills
    // the object data and records nothing as unsaved, so for an object that
    // already has an objectId `save()` finds `_isDirty(false)` false, never
    // calls `update()`, and returns the `_saveChildren` result — success, with
    // no request sent. This method would then report every object as synced
    // while writing nothing, which is precisely the failure ParseOfflineSyncResult
    // exists to surface. The manual variant registers the fields as unsaved
    // changes so the update actually goes out.
    final List<ParseObject> objects = await _loadAllForSync(className);
    int synced = 0;
    int skipped = 0;
    final List<ParseOfflineSyncFailure> failures = <ParseOfflineSyncFailure>[];
    for (final obj in objects) {
      if (shouldSync != null && !shouldSync(obj)) {
        skipped++;
        continue;
      }
      final response = await obj.save();
      if (response.success) {
        synced++;
      } else {
        failures.add(ParseOfflineSyncFailure(obj, response.error));
        if (isDebugEnabled()) {
          print(
            'ParseObjectOffline.syncLocalCacheWithServer: failed to save '
            '${obj.objectId} — ${response.error?.message}',
          );
        }
      }
    }
    if (isDebugEnabled()) {
      print(
        'ParseObjectOffline: sync complete for $className. '
        'Synced: $synced, Skipped: $skipped, Failed: ${failures.length}',
      );
    }
    return ParseOfflineSyncResult(
      synced: synced,
      skipped: skipped,
      failures: failures,
    );
  }

  // ─── Internal helpers ────────────────────────────────────────────────────

  /// Like [loadAllFromLocalCache], but decodes with `fromJsonForManualObject`
  /// so every cached field is registered as an unsaved change and a later
  /// `save()` actually issues an update. Only used by
  /// [syncLocalCacheWithServer]; normal reads must not mark objects dirty.
  static Future<List<ParseObject>> _loadAllForSync(String className) async {
    final CoreStore store = ParseCoreData().getStore();
    final String cacheKey = _offlineCacheKey(className);
    final Map<String, String> map = await _withOfflineCacheLock(
      cacheKey,
      () => _loadMap(store, cacheKey),
    );
    final List<ParseObject> results = <ParseObject>[];
    for (final entry in map.entries) {
      try {
        results.add(
          ParseObject(className).fromJsonForManualObject(
                json.decode(entry.value) as Map<String, dynamic>,
              )
              as ParseObject,
        );
      } catch (e) {
        if (isDebugEnabled()) {
          print(
            'ParseObjectOffline._loadAllForSync: skipping corrupt entry '
            '${entry.key} for $className — $e',
          );
        }
      }
    }
    return results;
  }

  // The cache is stored as a single JSON-encoded Map<String, String> keyed by
  // objectId. This gives O(1) lookups and avoids scanning every entry for id
  // comparisons. The old format (List<String>) is migrated on first read.
  //
  // Callers must hold the key's lock via _withOfflineCacheLock: the migration
  // branch writes.
  static Future<Map<String, String>> _loadMap(
    CoreStore store,
    String cacheKey,
  ) async {
    // Try the current map key first.
    final String? mapJson = await store.getString(_offlineMapKey(cacheKey));
    if (mapJson != null) {
      try {
        final decoded = json.decode(mapJson) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v as String));
      } catch (_) {}
    }

    // Then the superseded '_v2' suffix, moving it to the ':v2' key so this
    // costs one read once rather than dropping an existing cache.
    final String? legacyMapJson = await store.getString(
      _legacyOfflineMapKey(cacheKey),
    );
    if (legacyMapJson != null) {
      try {
        final decoded = json.decode(legacyMapJson) as Map<String, dynamic>;
        final Map<String, String> moved = decoded.map(
          (k, v) => MapEntry(k, v as String),
        );
        await store.setString(_offlineMapKey(cacheKey), legacyMapJson);
        await store.remove(_legacyOfflineMapKey(cacheKey));
        if (isDebugEnabled()) {
          print(
            'ParseObjectOffline: moved ${moved.length} entries from the _v2 '
            'key to the :v2 key for $cacheKey',
          );
        }
        return moved;
      } catch (_) {}
    }

    // Migrate from old List<String> format.
    final rawList = await store.getStringList(cacheKey);
    if (rawList == null || rawList.isEmpty) return {};
    final Map<String, String> migrated = {};
    for (final s in rawList) {
      try {
        final obj = json.decode(s) as Map<String, dynamic>;
        final id = obj['objectId'] as String?;
        if (id != null) migrated[id] = s;
      } catch (_) {}
    }
    if (migrated.isNotEmpty) {
      // Write migrated data in new format and remove old list.
      await store.setString(_offlineMapKey(cacheKey), json.encode(migrated));
      await store.remove(cacheKey);
      if (isDebugEnabled()) {
        print(
          'ParseObjectOffline: migrated ${migrated.length} entries from list '
          'format to map format for $cacheKey',
        );
      }
    }
    return migrated;
  }

  static Future<void> _saveMap(
    CoreStore store,
    String cacheKey,
    Map<String, String> map,
  ) async {
    await store.setString(_offlineMapKey(cacheKey), json.encode(map));
  }
}
