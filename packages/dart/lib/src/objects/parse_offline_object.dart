part of '../../parse_server_sdk.dart';

extension ParseObjectOffline on ParseObject {
  /// Load a single object by objectId from local storage.
  static Future<ParseObject?> loadFromLocalCache(
    String className,
    String objectId,
  ) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    for (final s in cached) {
      final jsonObj = json.decode(s);
      if (jsonObj['objectId'] == objectId) {
        print('Loaded object $objectId from local cache for $className');
        return ParseObject(className).fromJson(jsonObj);
      }
    }
    return null;
  }

  /// Save this object to local storage (CoreStore) for offline access.
  Future<void> saveToLocalCache() async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$parseClassName';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    // Remove any existing object with the same objectId
    cached.removeWhere((s) {
      final jsonObj = json.decode(s);
      return jsonObj['objectId'] == objectId;
    });
    cached.add(json.encode(toJson(full: true)));
    await coreStore.setStringList(cacheKey, cached);
    print(
      'Saved object ${objectId ?? "(no objectId)"} to local cache for $parseClassName',
    );
  }

  /// Save a list of objects to local storage efficiently.
  static Future<void> saveAllToLocalCache(
    String className,
    List<ParseObject> objectsToSave,
  ) async {
    if (objectsToSave.isEmpty) return;

    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final List<String> cachedStrings = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );

    // Use a Map for efficient lookup and update of existing objects
    final Map<String, String> objectMap = {};
    for (final s in cachedStrings) {
      try {
        final jsonObj = json.decode(s);
        final objectId = jsonObj['objectId'] as String?;
        if (objectId != null) {
          objectMap[objectId] = s; // Store the original JSON string
        }
      } catch (e) {
        print('Error decoding cached object string during batch save: $e');
      }
    }

    int added = 0;
    int updated = 0;

    // Update the map with the new objects
    for (final obj in objectsToSave) {
      final objectId = obj.objectId;
      if (objectId != null) {
        if (objectMap.containsKey(objectId)) {
          updated++;
        } else {
          added++;
        }
        // Encode the new object data and replace/add it in the map
        objectMap[objectId] = json.encode(obj.toJson(full: true));
      } else {
        print(
          'Skipping object without objectId during batch save for $className',
        );
      }
    }

    // Convert the map values back to a list and save
    final List<String> updatedCachedStrings = objectMap.values.toList();
    await coreStore.setStringList(cacheKey, updatedCachedStrings);
    print(
      'Batch saved to local cache for $className. Added: $added, Updated: $updated, Total: ${updatedCachedStrings.length}',
    );
  }

  /// Remove this object from local storage (CoreStore).
  Future<void> removeFromLocalCache() async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$parseClassName';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    cached.removeWhere((s) {
      final jsonObj = json.decode(s);
      return jsonObj['objectId'] == objectId;
    });
    await coreStore.setStringList(cacheKey, cached);
    print(
      'Removed object ${objectId ?? "(no objectId)"} from local cache for $parseClassName',
    );
  }

  /// Load all objects of this class from local storage.
  static Future<List<ParseObject>> loadAllFromLocalCache(
    String className,
  ) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    print('Loaded ${cached.length} objects from local cache for $className');
    return cached.map<ParseObject>((s) {
      final jsonObj = json.decode(s);
      return ParseObject(className).fromJson(jsonObj);
    }).toList();
  }

  Future<void> updateInLocalCache(Map<String, dynamic> updates) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$parseClassName';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    for (int i = 0; i < cached.length; i++) {
      final jsonObj = json.decode(cached[i]);
      if (jsonObj['objectId'] == objectId) {
        jsonObj.addAll(updates);
        cached[i] = json.encode(jsonObj);
        break;
      }
    }
    await coreStore.setStringList(cacheKey, cached);
    print(
      'Updated object ${objectId ?? "(no objectId)"} in local cache for $parseClassName',
    );
  }

  static Future<void> clearLocalCacheForClass(String className) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    await coreStore.setStringList(cacheKey, []);
    print('Cleared local cache for $className');
  }

  static Future<bool> existsInLocalCache(
    String className,
    String objectId,
  ) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    for (final s in cached) {
      final jsonObj = json.decode(s);
      if (jsonObj['objectId'] == objectId) {
        print('Object $objectId exists in local cache for $className');
        return true;
      }
    }
    print('Object $objectId does not exist in local cache for $className');
    return false;
  }

  static Future<List<String>> getAllObjectIdsInLocalCache(
    String className,
  ) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final List<String> cached = await _getStringListAsStrings(
      coreStore,
      cacheKey,
    );
    print('Fetched all objectIds from local cache for $className');
    return cached.map((s) => json.decode(s)['objectId'] as String).toList();
  }

  static Future<void> syncLocalCacheWithServer(String className) async {
    final objects = await loadAllFromLocalCache(className);
    for (final obj in objects) {
      await obj.save();
    }
    print('Synced local cache with server for $className');
  }

  static Future<List<String>> _getStringListAsStrings(
    CoreStore coreStore,
    String cacheKey,
  ) async {
    final rawList = await coreStore.getStringList(cacheKey);
    if (rawList == null) return [];
    return List<String>.from(rawList.map((e) => e.toString()));
  }
}
