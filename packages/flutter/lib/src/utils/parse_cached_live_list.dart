
import 'dart:collection';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart' as sdk;
import 'package:flutter/foundation.dart';

/// A wrapper around ParseLiveList that provides memory-efficient caching
class CachedParseLiveList<T extends sdk.ParseObject> {
  CachedParseLiveList(this._parseLiveList, this.cacheSize) 
      : _cache = _LRUCache<String, T>(cacheSize);
  
  final sdk.ParseLiveList<T> _parseLiveList;
  final int cacheSize;
  final _LRUCache<String, T> _cache;

  /// Get the stream of events from the underlying ParseLiveList
  Stream<sdk.ParseLiveListEvent<T>> get stream => _parseLiveList.stream;
  
  /// Get the size of the list
  int get size => _parseLiveList.size;
  
  /// Get a loaded object at the specified index
  T? getLoadedAt(int index) {
    final result = _parseLiveList.getLoadedAt(index);
    if (result != null && result.objectId != null) {
      _cache.put(result.objectId!, result);
    }
    return result;
  }
  
  /// Get a pre-loaded object at the specified index
  T? getPreLoadedAt(int index) {
    final objectId = _parseLiveList.idOf(index);
    
    // Try cache first
    if (objectId != 'NotFound' && _cache.contains(objectId)) {
      return _cache.get(objectId);
    }
    
    // Fall back to original method
    final result = _parseLiveList.getPreLoadedAt(index);
    if (result != null && result.objectId != null) {
      _cache.put(result.objectId!, result);
    }
    return result;
  }
  
  /// Get the unique identifier for an object at the specified index
  String getIdentifier(int index) => _parseLiveList.getIdentifier(index);
  
  /// Get a stream of updates for an object at the specified index
  Stream<T> getAt(int index) {
    // We don't cache the stream itself, just the objects
    return _parseLiveList.getAt(index);
  }
  
  /// Clean up resources
  void dispose() {
    _parseLiveList.dispose();
    _cache.clear();
  }
}

/// LRU Cache for efficient memory management
class _LRUCache<K, V> {
  _LRUCache(this.capacity);
  
  final int capacity;
  final Map<K, V> _cache = {};
  final LinkedHashSet<K> _accessOrder = LinkedHashSet<K>();
  
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // Update access order (move to most recently used)
    _accessOrder.remove(key);
    _accessOrder.add(key);
    
    return _cache[key];
  }
  
  bool contains(K key) => _cache.containsKey(key);
  
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      // Already exists, update access order
      _accessOrder.remove(key);
    } else if (_cache.length >= capacity) {
      // At capacity, remove least recently used item
      final K leastUsed = _accessOrder.first;
      _accessOrder.remove(leastUsed);
      _cache.remove(leastUsed);
    }
    
    _cache[key] = value;
    _accessOrder.add(key);
  }
  
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }
}