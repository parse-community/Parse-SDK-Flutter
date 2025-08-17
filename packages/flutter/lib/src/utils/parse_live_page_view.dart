part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// A widget that displays a live list of Parse objects in a PageView.
class ParseLiveListPageView<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveListPageView({
    super.key,
    required this.query,
    this.listLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.pageController,
    this.scrollPhysics,
    this.childBuilder,
    this.onPageChanged,
    this.scrollDirection,
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = false,
    this.preloadedColumns,
    this.excludedColumns,
    this.pagination = false,
    this.pageSize = 20,
    this.paginationThreshold = 3,
    this.loadingIndicator,
    this.cacheSize = 50,
    this.offlineMode = false, // Added offlineMode
    required this.fromJson, // Added fromJson
  });

  final sdk.QueryBuilder<T> query;
  final Widget? listLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;
  final PageController? pageController;
  final ScrollPhysics? scrollPhysics;
  final Axis? scrollDirection;
  final ChildBuilder<T>? childBuilder;
  final void Function(int)? onPageChanged;

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;

  // Pagination properties
  final bool pagination;
  final int pageSize;
  final int paginationThreshold;
  final Widget? loadingIndicator;

  final int cacheSize;
  final bool offlineMode; // Added offlineMode
  final T Function(Map<String, dynamic> json) fromJson; // Added fromJson

  @override
  State<ParseLiveListPageView<T>> createState() =>
      _ParseLiveListPageViewState<T>();
}

class _ParseLiveListPageViewState<T extends sdk.ParseObject>
    extends State<ParseLiveListPageView<T>> with ConnectivityHandlerMixin<ParseLiveListPageView<T>> {
  CachedParseLiveList<T>? _liveList;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[]; // Local list to manage all items

  // Pagination state
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMoreData = true;
  late PageController _pageController;

  // --- Implement Mixin Requirements ---
  @override
  Future<void> loadDataFromServer() => _loadData();

  @override
  Future<void> loadDataFromCache() => _loadFromCache();

  @override
  void disposeLiveList() {
    _liveList?.dispose();
    _liveList = null;
  }

  @override
  String get connectivityLogPrefix => 'ParseLivePageView';

  @override
  bool get isOfflineModeEnabled => widget.offlineMode;
  // --- End Mixin Requirements ---

  @override
  void initState() {
    super.initState();
    _pageController = widget.pageController ?? PageController();

    // Initialize connectivity and load initial data
    initConnectivityHandler(); // Replaces direct _loadData() call

    // Add listener to detect when to load more pages (only if online)
    if (widget.pagination) {
      _pageController.addListener(_checkForMoreData);
    }
  }

  void _checkForMoreData() {
    // Only check/load more if online
    if (isOffline || !widget.pagination || _isLoadingMore || !_hasMoreData) return;

    // If we're within the threshold of the end, load more data
    if (_pageController.page != null &&
        _items.isNotEmpty &&
        _pageController.page! >= _items.length - widget.paginationThreshold) {
      _loadMoreData();
    }

    // Preload adjacent pages (lazy loading)
    if (_pageController.page != null && widget.lazyLoading) {
      int currentPage = _pageController.page!.round();
      _preloadAdjacentPages(currentPage);
    }
  }

  Future<void> _loadFromCache() async {
    if (!isOfflineModeEnabled) {
      debugPrint('$connectivityLogPrefix Offline mode disabled, skipping cache load.');
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {});
      return;
    }

    debugPrint('$connectivityLogPrefix Loading PageView data from cache...');
    _items.clear();

    try {
      final cached = await sdk.ParseObjectOffline.loadAllFromLocalCache(
        widget.query.object.parseClassName,
      );
      for (final obj in cached) {
        try {
          _items.add(widget.fromJson(obj.toJson(full: true)));
        } catch (e) {
           debugPrint('$connectivityLogPrefix Error deserializing cached object: $e');
        }
      }
      debugPrint('$connectivityLogPrefix Loaded ${_items.length} items from cache for ${widget.query.object.parseClassName}');
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading PageView data from cache: $e');
    }

    _noDataNotifier.value = _items.isEmpty;
    if (mounted) {
      setState(() {});
    }
  }

  /// Loads the data for the live list.
  Future<void> _loadData() async {
    // If offline, attempt to load from cache and exit
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Offline: Skipping server load, relying on cache.');
      if (isOfflineModeEnabled) {
        await loadDataFromCache();
      }
      return;
    }

    // --- Online Loading Logic ---
    debugPrint('$connectivityLogPrefix Loading initial PageView data from server...');
    List<T> itemsToCacheBatch = []; // Prepare list for batch caching

    try {
      // Reset state
      _currentPage = 0;
      _hasMoreData = true;
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {}); // Show loading state

      // Prepare query
      final initialQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(0)
        ..setLimit(widget.pageSize);

      // Fetch from server using ParseLiveList
      final originalLiveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
      );

      final liveList = CachedParseLiveList<T>(originalLiveList, widget.cacheSize, widget.lazyLoading);
      _liveList?.dispose(); // Dispose previous list if any
      _liveList = liveList;

      // Populate _items directly from server data and collect for caching
      if (liveList.size > 0) {
        for (int i = 0; i < liveList.size; i++) {
          final item = liveList.getPreLoadedAt(i);
          if (item != null) {
            _items.add(item);
            // Add the item fetched from server to the cache batch if offline mode is on
            if (widget.offlineMode) {
               itemsToCacheBatch.add(item);
            }
          }
        }
      }

      // --- Update UI FIRST ---
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) {
        setState(() {}); // Display fetched items
      }
      // --- End UI Update ---

      // --- Trigger Background Batch Cache AFTER UI update ---
      if (itemsToCacheBatch.isNotEmpty) {
        // Don't await, let it run in background
        _saveBatchToCache(itemsToCacheBatch);
      }
      // --- End Trigger ---

      // --- Trigger Proactive Cache for Next Page ---
      if (_hasMoreData) { // Only if initial load wasn't empty
         _proactivelyCacheNextPage(1); // Start caching page 1 (index 1)
      }
      // --- End Proactive Cache Trigger ---

      // --- Stream Listener ---
      liveList.stream.listen((event) {
        if (!mounted) return;

        T? objectToCache;

        try { // Wrap event processing
          if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
            final addedItem = event.object;
            setState(() { _items.insert(event.index, addedItem); });
            objectToCache = addedItem;
          } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
            if (event.index >= 0 && event.index < _items.length) {
              final removedItem = _items.removeAt(event.index);
              setState(() {});
              if (widget.offlineMode) {
                removedItem.removeFromLocalCache().catchError((e) {
                   debugPrint('$connectivityLogPrefix Error removing item ${removedItem.objectId} from cache: $e');
                });
              }
            } else {
              debugPrint('$connectivityLogPrefix LiveList Delete Event: Invalid index ${event.index}, list size ${_items.length}');
            }
          } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
            final updatedItem = event.object;
            if (event.index >= 0 && event.index < _items.length) {
              setState(() { _items[event.index] = updatedItem; });
              objectToCache = updatedItem;
            } else {
              debugPrint('$connectivityLogPrefix LiveList Update Event: Invalid index ${event.index}, list size ${_items.length}');
            }
          }

          // Save single updates from stream immediately if offline mode is on
          if (widget.offlineMode && objectToCache != null) {
            objectToCache.saveToLocalCache().catchError((e) {
               debugPrint('$connectivityLogPrefix Error saving stream update for ${objectToCache?.objectId} to cache: $e');
            });
          }

          _noDataNotifier.value = _items.isEmpty;

        } catch (e) {
           debugPrint('$connectivityLogPrefix Error processing stream event: $e');
        }

      }, onError: (error) {
         debugPrint('$connectivityLogPrefix LiveList Stream Error: $error');
         if (mounted) {
            setState(() { /* Potentially update state to show error */ });
         }
      });
      // --- End Stream Listener ---

    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) setState(() {});
    }
  }

  /// Loads more data when approaching the end of available pages
  Future<void> _loadMoreData() async {
    // Prevent loading more if offline, already loading, or no more data
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Cannot load more data while offline.');
      return;
    }
    if (_isLoadingMore || !_hasMoreData) return;

    debugPrint('$connectivityLogPrefix PageView loading more data...');
    setState(() { _isLoadingMore = true; });

    List<T> itemsToCacheBatch = []; // Prepare list for batch caching

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;

      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount)
        ..setLimit(widget.pageSize);

      // Fetch next page from server
      final parseResponse = await nextPageQuery.query();
      debugPrint('$connectivityLogPrefix LoadMore Response: Success=${parseResponse.success}, Count=${parseResponse.count}, Results=${parseResponse.results?.length}, Error: ${parseResponse.error?.message}');

      if (parseResponse.success && parseResponse.results != null) {
        final List<dynamic> rawResults = parseResponse.results!;
        final List<T> results = rawResults.map((dynamic obj) => obj as T).toList();

        if (results.isEmpty) {
          setState(() { _hasMoreData = false; });
        } else {
          // Collect fetched items for caching if offline mode is on
          if (widget.offlineMode) {
            itemsToCacheBatch.addAll(results);
          }

          // --- Update UI FIRST ---
          setState(() { _items.addAll(results); });
          // --- End UI Update ---

          // --- Trigger Background Batch Cache AFTER UI update ---
          if (itemsToCacheBatch.isNotEmpty) {
            // Don't await, let it run in background
            _saveBatchToCache(itemsToCacheBatch);
          }
          // --- End Trigger ---

          // --- Trigger Proactive Cache for Next Page ---
          if (_hasMoreData) { // Check if the current load didn't signal the end
             _proactivelyCacheNextPage(_currentPage + 1); // Start caching page N+1
          }
          // --- End Proactive Cache Trigger ---
        }
      } else {
        // Handle error
        debugPrint('$connectivityLogPrefix Error loading more data: ${parseResponse.error?.message}');
        // Optionally set an error state or retry mechanism
      }
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading more data: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoadingMore = false; });
      }
    }
  }

  // --- Helper to Save Batch to Cache (Handles Fetch if Lazy Loading) ---
  Future<void> _saveBatchToCache(List<T> itemsToSave) async {
    if (itemsToSave.isEmpty || !widget.offlineMode) return;

    debugPrint('$connectivityLogPrefix Saving batch of ${itemsToSave.length} items to cache...');
    Stopwatch stopwatch = Stopwatch()..start();

    List<T> itemsToSaveFinal = [];
    List<Future<void>> fetchFutures = [];

    // First, handle potential fetches if lazy loading is enabled
    if (widget.lazyLoading) {
      for (final item in itemsToSave) {
        // If lazy loading is enabled, assume the item might need fetching before caching.
        // Add a future that fetches the item and then adds it to the final list.
        // The `fetch()` method should ideally handle cases where data is already present efficiently.
        fetchFutures.add(item.fetch().then((_) {
           // Add successfully fetched items to the final list
           itemsToSaveFinal.add(item);
        }).catchError((fetchError) {
           debugPrint('$connectivityLogPrefix Error fetching object ${item.objectId} during batch save pre-fetch: $fetchError');
           // Decide whether to add the item even if fetch failed.
           // Current behavior: Only add successfully fetched items.
           // To add even on error (potentially partial data): itemsToSaveFinal.add(item);
        }));
      }
      // Wait for all necessary fetches to complete
      if (fetchFutures.isNotEmpty) {
         await Future.wait(fetchFutures);
      }
    } else {
      // Not lazy loading, just use the original list
      itemsToSaveFinal = itemsToSave;
    }


    // Now, save the final list (with fetched data if applicable) using the efficient batch method
    if (itemsToSaveFinal.isNotEmpty) {
      try {
        // Ensure we have the className, assuming all items are the same type
        final className = itemsToSaveFinal.first.parseClassName;
        await sdk.ParseObjectOffline.saveAllToLocalCache(className, itemsToSaveFinal);
      } catch (e) {
         debugPrint('$connectivityLogPrefix Error during batch save operation: $e');
      }
    }

    stopwatch.stop();
    // Adjust log message as the static method now prints details
    debugPrint('$connectivityLogPrefix Finished batch save processing in ${stopwatch.elapsedMilliseconds}ms.');
  }
  // --- End Helper ---

  // --- Helper to Proactively Cache the Next Page ---
  Future<void> _proactivelyCacheNextPage(int pageNumberToCache) async {
    // Only run if online, offline mode is on, and pagination is enabled
    if (isOffline || !widget.offlineMode || !widget.pagination) return;

    debugPrint('$connectivityLogPrefix Proactively caching page $pageNumberToCache...');
    final skipCount = pageNumberToCache * widget.pageSize;
    final query = QueryBuilder<T>.copy(widget.query)
      ..setAmountToSkip(skipCount)
      ..setLimit(widget.pageSize);

    try {
      final response = await query.query();
      if (response.success && response.results != null) {
        final List<T> results = (response.results as List).cast<T>();
        if (results.isNotEmpty) {
          // Use the existing batch save helper (it handles lazy fetching if needed)
          // Await is fine here as this whole function runs in the background
          await _saveBatchToCache(results);
        } else {
           debugPrint('$connectivityLogPrefix Proactive cache: Page $pageNumberToCache was empty.');
        }
      } else {
         debugPrint('$connectivityLogPrefix Proactive cache failed for page $pageNumberToCache: ${response.error?.message}');
      }
    } catch (e) {
       debugPrint('$connectivityLogPrefix Proactive cache exception for page $pageNumberToCache: $e');
    }
  }
  // --- End Helper ---

  /// Refreshes the data for the live list.
  Future<void> _refreshData() async {
    debugPrint('$connectivityLogPrefix Refreshing PageView data...');
    disposeLiveList(); // Dispose existing live list before refresh

    // Reload based on connectivity
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Refreshing offline, loading from cache.');
      await loadDataFromCache();
    } else {
      debugPrint('$connectivityLogPrefix Refreshing online, loading from server.');
      await loadDataFromServer(); // Calls the updated _loadData
    }
  }

  /// Preloads adjacent pages for smoother transitions
  void _preloadAdjacentPages(int currentIndex) {
    // Only preload if online and lazy loading is enabled
    if (isOffline || !widget.lazyLoading || _liveList == null) return;

    // Preload current page and next 2-3 pages
    final startIdx = max(0, currentIndex - 1);
    final endIdx = min(_items.length - 1, currentIndex + 3);

    for (int i = startIdx; i <= endIdx; i++) {
      if (i < _liveList!.size) {
        // This triggers lazy loading of these pages via CachedParseLiveList
        _liveList!.getAt(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        // Determine loading state: Online AND _liveList not yet initialized.
        final bool showLoadingIndicator = !isOffline && _liveList == null;

        if (showLoadingIndicator) {
          return widget.listLoadingElement ??
              const Center(child: CircularProgressIndicator());
        }

        if (noData) {
          return widget.queryEmptyElement ??
              const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: widget.scrollDirection ?? Axis.horizontal,
                physics: widget.scrollPhysics,
                // Add 1 for loading indicator if paginating and more data exists
                itemCount: _items.length + (widget.pagination && _hasMoreData ? 1 : 0),
                onPageChanged: (index) {
                  // Preload adjacent pages when page changes (only if online)
                  if (!isOffline && widget.lazyLoading) {
                    _preloadAdjacentPages(index);
                  }

                  // Check if we need to load more data (only if online)
                  if (!isOffline && widget.pagination &&
                      _hasMoreData &&
                      index >= _items.length - widget.paginationThreshold) {
                    _loadMoreData();
                  }

                  // Call the original onPageChanged callback
                  widget.onPageChanged?.call(index);
                },
                itemBuilder: (context, index) {
                  // Show loading indicator for the last item if paginating and more data is available
                  if (widget.pagination && index >= _items.length) {
                    return widget.loadingIndicator ??
                        const Center(child: CircularProgressIndicator());
                  }

                  // Preload adjacent pages for smoother experience (only if online)
                  if (!isOffline) {
                     _preloadAdjacentPages(index);
                  }

                  final item = _items[index];

                  StreamGetter<T>? itemStream;
                  DataGetter<T>? loadedData;
                  DataGetter<T>? preLoadedData;

                  final liveList = _liveList;
                  // Use liveList data only if online, lazy loading, and within bounds
                  if (!isOffline && liveList != null && index < liveList.size && widget.lazyLoading) {
                    itemStream = () => liveList.getAt(index);
                    loadedData = () => liveList.getLoadedAt(index);
                    preLoadedData = () => liveList.getPreLoadedAt(index);
                  } else {
                    // Offline or not lazy loading: Use data directly from _items
                    loadedData = () => item;
                    preLoadedData = () => item;
                  }

                  return ParseLiveListElementWidget<T>(
                    key: ValueKey<String>(item.objectId ?? 'unknown-$index-${item.hashCode}'),
                    stream: itemStream,
                    loadedData: loadedData,
                    preLoadedData: preLoadedData,
                    sizeFactor: const AlwaysStoppedAnimation<double>(1.0),
                    duration: widget.duration,
                    childBuilder: widget.childBuilder ??
                        ParseLiveListWidget.defaultChildBuilder,
                    index: index,
                  );
                },
              ),
              // Show loading indicator overlay when loading more pages
              if (_isLoadingMore)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: widget.loadingIndicator ??
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    disposeConnectivityHandler(); // Dispose mixin resources
    disposeLiveList(); // Dispose live list
    _noDataNotifier.dispose();
    // Remove listener only if we added it
    if (widget.pagination && widget.pageController == null) {
       _pageController.removeListener(_checkForMoreData);
    }
    // Dispose controller only if we created it
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }
}

// --- ParseLiveListElementWidget remains unchanged ---
// (Should be identical to the one in parse_live_list.dart)
// class ParseLiveListElementWidget<T extends sdk.ParseObject> extends StatefulWidget { ... }
// class _ParseLiveListElementWidgetState<T extends sdk.ParseObject> extends State<ParseLiveListElementWidget<T>> { ... }