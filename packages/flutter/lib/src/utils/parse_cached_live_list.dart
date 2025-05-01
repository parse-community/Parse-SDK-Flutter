import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart' as sdk;

/// A cache wrapper for ParseLiveList to improve performance when working with large datasets.
///
/// This class wraps a ParseLiveList and provides caching functionality to reduce
/// the number of expensive operations when repeatedly accessing the same items.
/// 
/// The cache size can be configured to limit memory usage.
class CachedParseLiveList<T extends sdk.ParseObject> {
  /// The original ParseLiveList being wrapped
  final sdk.ParseLiveList<T> _originalLiveList;
  
  /// Internal cache of items indexed by position
  final Map<int, T> _cache = {};
  
  /// Maximum number of items to keep in cache
  final int? _cacheSize;
  
  /// Creates a new cached wrapper around a ParseLiveList
  /// 
  /// [originalLiveList] is the ParseLiveList to wrap
  /// [cacheSize] is the maximum number of items to keep in cache (null for unlimited)
  CachedParseLiveList(this._originalLiveList, [this._cacheSize]);
  
  /// Access the underlying stream of events from the ParseLiveList
  Stream<sdk.ParseLiveListEvent<sdk.ParseObject>> get stream => _originalLiveList.stream;
  
  /// Get the number of items in the list
  int get size => _originalLiveList.size;
  
  /// Get the identifier for an item at the specified index
  String getIdentifier(int index) => _originalLiveList.getIdentifier(index);
  
  /// Get a stream for the item at the specified index
  /// The returned item will be cached for future access
  Stream<T> getAt(int index) {
    final stream = _originalLiveList.getAt(index);
    return stream.map((item) {
      // Cache the item when it comes through the stream
      _cache[index] = item;
      _trimCacheIfNeeded();
      return item;
    });
  }
  
  /// Get the loaded data at the specified index
  /// Returns from cache if available, otherwise from the original list
  T? getLoadedAt(int index) {
    // Try to get from cache first
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    
    // Fall back to original implementation
    final item = _originalLiveList.getLoadedAt(index);
    if (item != null) {
      _cache[index] = item;
      _trimCacheIfNeeded();
    }
    return item;
  }
  
  /// Get the pre-loaded data at the specified index
  /// Returns from cache if available, otherwise from the original list
  T? getPreLoadedAt(int index) {
    // Try to get from cache first
    if (_cache.containsKey(index)) {
      return _cache[index];
    }
    
    // Fall back to original implementation
    final item = _originalLiveList.getPreLoadedAt(index);
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