part of '../../parse_server_sdk.dart';



extension ParseObjectOffline on ParseObject {
  /// Save this object to local storage (CoreStore) for offline access.
  Future<void> saveToLocalCache() async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_${parseClassName}';
    List<String> cached = await coreStore.getStringList(cacheKey) ?? [];
    // Remove any existing object with the same objectId
    cached.removeWhere((s) {
      final jsonObj = json.decode(s);
      return jsonObj['objectId'] == objectId;
    });
    cached.add(json.encode(toJson(full: true)));
    await coreStore.setStringList(cacheKey, cached);
  }

  /// Load all objects of this class from local storage.
  static Future<List<ParseObject>> loadAllFromLocalCache(String className) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String cacheKey = 'offline_cache_$className';
    List<String> cached = await coreStore.getStringList(cacheKey) ?? [];
    return cached.map<ParseObject>((s) {
      final jsonObj = json.decode(s);
      return ParseObject(className).fromJson(jsonObj);
    }).toList();
  }
}

// await object.saveToLocalCache();
// final offlineObjects = await ParseObjectOffline.loadAllFromLocalCache('YourClassName');