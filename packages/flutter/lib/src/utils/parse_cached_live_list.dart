import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart' as sdk;

/// A cache wrapper for ParseLiveList to improve performance with proper lazy loading support.
class CachedParseLiveList<T extends sdk.ParseObject> {
  /// The original ParseLiveList being wrapped
  final sdk.ParseLiveList<T> _originalLiveList;
  
  /// Internal cache of items indexed by position
  final Map<int, T> _cache = {};
  
  /// Maximum number of items to keep in cache
  final int? _cacheSize;
  
  /// Whether lazy loading is enabled
  final bool _lazyLoading;
  
  CachedParseLiveList(this._originalLiveList, [this._cacheSize, this._lazyLoading = false]);
  
  Stream<sdk.ParseLiveListEvent<sdk.ParseObject>> get stream => _originalLiveList.stream;
  int get size => _originalLiveList.size;
  
  String getIdentifier(int index) => _originalLiveList.getIdentifier(index);
  
  /// Get a stream for the item at the specified index
  Stream<T> getAt(int index) {
    // When lazy loading is enabled, we need to use the original stream
    // and populate our cache with the results
    final stream = _originalLiveList.getAt(index);
    
    return stream.map((item) {
      // Cache the item when it comes through the stream
      _cache[index] = item;
      _trimCacheIfNeeded();
      return item;
    });
  }
  
  /// Get the loaded data at the specified index
  T? getLoadedAt(int index) {
    // Try to get from cache first
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    
    // With lazy loading, the item might not be loaded yet
    // so use the original method
    final item = _originalLiveList.getLoadedAt(index);
    
    // Only cache if we got an actual item
    if (item != null) {
      _cache[index] = item;
      _trimCacheIfNeeded();
    }
    return item;
  }
  
  /// Get the pre-loaded data at the specified index
  T? getPreLoadedAt(int index) {
    // Try to get from cache first
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    
    // If lazy loading is enabled, there might not be pre-loaded data
    final item = _originalLiveList.getPreLoadedAt(index);
    
    // Only cache if we got an actual item
    if (item != null) {
      _cache[index] = item;
      _trimCacheIfNeeded();
    }
    return item;
  }
  
  /// Trims the cache if it exceeds the configured size
  void _trimCacheIfNeeded() {
    if (_cacheSize == null || _cache.length <= _cacheSize!) return;
    
    // Remove oldest entries if cache gets too big
    final keysToRemove = _cache.keys.toList()..sort();
    final numToRemove = _cache.length - _cacheSize!;
    if (numToRemove > 0) {
      for (int i = 0; i < numToRemove; i++) {
        _cache.remove(keysToRemove[i]);
      }
    }
  }
  
  /// Update the cache when an item changes or is added
  void updateCache(int index, T item) {
    _cache[index] = item;
    _trimCacheIfNeeded();
  }
  
  /// Remove an item from the cache
  void removeFromCache(int index) {
    _cache.remove(index);
  }
  
  /// Clear the entire cache
  void clearCache() {
    _cache.clear();
  }
  
  /// Dispose of resources
  void dispose() {
    _originalLiveList.dispose();
    _cache.clear();
  }
}