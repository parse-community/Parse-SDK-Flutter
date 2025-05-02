part of '../../parse_server_sdk.dart';



extension ParseObjectOffline on ParseObject {


  /// Load a single object by objectId from local storage.
  static Future<ParseObject?> loadFromLocalCache(String className, String objectId) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
    for (final s in cached) {
      final jsonObj = json.decode(s);
      if (jsonObj['objectId'] == objectId) {
        return ParseObject(className).fromJson(jsonObj);
      }
    }
    return null;
  }

  /// Save this object to local storage (CoreStore) for offline access.
  Future<void> saveToLocalCache() async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_${parseClassName}';
    final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
    // Remove any existing object with the same objectId
    cached.removeWhere((s) {
      final jsonObj = json.decode(s);
      return jsonObj['objectId'] == objectId;
    });
    cached.add(json.encode(toJson(full: true)));
    await coreStore.setStringList(cacheKey, cached);
  }

   /// Remove this object from local storage (CoreStore).
  Future<void> removeFromLocalCache() async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_${parseClassName}';
    final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
    cached.removeWhere((s) {
      final jsonObj = json.decode(s);
      return jsonObj['objectId'] == objectId;
    });
    await coreStore.setStringList(cacheKey, cached);
  }

  /// Load all objects of this class from local storage.
  static Future<List<ParseObject>> loadAllFromLocalCache(String className) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
   final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
    return cached.map<ParseObject>((s) {
      final jsonObj = json.decode(s);
      return ParseObject(className).fromJson(jsonObj);
    }).toList();
  }


  Future<void> updateInLocalCache(Map<String, dynamic> updates) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_${parseClassName}';
    final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
    for (int i = 0; i < cached.length; i++) {
      final jsonObj = json.decode(cached[i]);
      if (jsonObj['objectId'] == objectId) {
        jsonObj.addAll(updates);
        cached[i] = json.encode(jsonObj);
        break;
      }
    }
    await coreStore.setStringList(cacheKey, cached);
  }

  static Future<void> clearLocalCacheForClass(String className) async {
  final CoreStore coreStore = ParseCoreData().getStore();
  final String cacheKey = 'offline_cache_$className';
  await coreStore.setStringList(cacheKey, []);
}

static Future<bool> existsInLocalCache(String className, String objectId) async {
  final CoreStore coreStore = ParseCoreData().getStore();
  final String cacheKey = 'offline_cache_$className';
  final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
  for (final s in cached) {
    final jsonObj = json.decode(s);
    if (jsonObj['objectId'] == objectId) {
      return true;
    }
  }
  return false;
}
static Future<List<String>> getAllObjectIdsInLocalCache(String className) async {
  final CoreStore coreStore = ParseCoreData().getStore();
  final String cacheKey = 'offline_cache_$className';
  final rawList = await coreStore.getStringList(cacheKey);
    final List<String> cached = rawList == null
        ? []
        : rawList.map((e) => e.toString()).toList();
  return cached.map((s) => json.decode(s)['objectId'] as String).toList();
}

static Future<void> syncLocalCacheWithServer(String className) async {
  final objects = await loadAllFromLocalCache(className);
  for (final obj in objects) {
    await obj.save();
  }
}
}

// await object.saveToLocalCache();
// final offlineObjects = await ParseObjectOffline.loadAllFromLocalCache('YourClassName');