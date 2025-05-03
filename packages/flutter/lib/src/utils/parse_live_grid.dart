part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// A widget that displays a live grid of Parse objects.
class ParseLiveGridWidget<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveGridWidget({
    super.key,
    required this.query,
    this.gridLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.scrollPhysics,
    this.scrollController,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.primary,
    this.reverse = false,
    this.childBuilder,
    this.shrinkWrap = false,
    this.removedItemBuilder, // Note: Not currently used in state logic
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = true,
    this.preloadedColumns,
    this.excludedColumns,
    this.animationController, // Note: Not currently used for item animations
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 5.0,
    this.mainAxisSpacing = 5.0,
    this.childAspectRatio = 0.80,
    this.pagination = false,
    this.pageSize = 20,
    this.nonPaginatedLimit = 1000,
    this.loadMoreOffset = 300.0,
    this.footerBuilder,
    this.cacheSize = 50,
    this.lazyBatchSize = 0, // Note: Not currently used in state logic
    this.lazyTriggerOffset = 500.0, // Note: Not currently used in state logic
    this.offlineMode = false,
    required this.fromJson,
  });

  final sdk.QueryBuilder<T> query;
  final Widget? gridLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final bool reverse;
  final bool shrinkWrap;
  final int cacheSize;

  final ChildBuilder<T>? childBuilder;
  final ChildBuilder<T>? removedItemBuilder;

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;

  final AnimationController? animationController;

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  final bool pagination;
  final int pageSize;
  final int nonPaginatedLimit;
  final double loadMoreOffset;
  final FooterBuilder? footerBuilder;

  final int lazyBatchSize;
  final double lazyTriggerOffset;

  final bool offlineMode;
  final T Function(Map<String, dynamic> json) fromJson;

  @override
  State<ParseLiveGridWidget<T>> createState() => _ParseLiveGridWidgetState<T>();

  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]) {
    if (snapshot.failed) {
      return const Text('Something went wrong!');
    } else if (snapshot.hasData) {
      return ListTile(
        title: Text(
          snapshot.loadedData?.get<String>(sdk.keyVarObjectId) ?? 'Missing Data!',
        ),
        subtitle: index != null ? Text('Item #$index') : null,
      );
    } else {
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }
}

class _ParseLiveGridWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveGridWidget<T>> with ConnectivityHandlerMixin<ParseLiveGridWidget<T>> {
  CachedParseLiveList<T>? _liveGrid;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[];

  late final ScrollController _scrollController;
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  final Set<int> _loadingIndices = {}; // Used for lazy loading specific items

  // --- Implement Mixin Requirements ---
  @override
  Future<void> loadDataFromServer() => _loadData();

  @override
  Future<void> loadDataFromCache() => _loadFromCache();

  @override
  void disposeLiveList() {
    _liveGrid?.dispose();
    _liveGrid = null;
  }

  @override
  String get connectivityLogPrefix => 'ParseLiveGrid';

  @override
  bool get isOfflineModeEnabled => widget.offlineMode;
  // --- End Mixin Requirements ---

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _scrollController = ScrollController();
    } else {
      _scrollController = widget.scrollController!;
    }

    if (widget.pagination || widget.lazyLoading) { // Listen if pagination OR lazy loading is on
      _scrollController.addListener(_onScroll);
    }

    initConnectivityHandler();
  }

  Future<void> _loadFromCache() async {
    if (!isOfflineModeEnabled) {
      debugPrint('$connectivityLogPrefix Offline mode disabled, skipping cache load.');
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {});
      return;
    }

    debugPrint('$connectivityLogPrefix Loading Grid data from cache...');
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
      debugPrint('$connectivityLogPrefix Error loading grid data from cache: $e');
    }

    _noDataNotifier.value = _items.isEmpty;
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    // Handle Pagination
    if (widget.pagination && !isOffline && _loadMoreStatus != LoadMoreStatus.loading && _hasMoreData) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= widget.loadMoreOffset) {
        _loadMoreData();
      }
    }

    // Handle Lazy Loading Trigger
    if (widget.lazyLoading && !isOffline && _liveGrid != null) {
      final visibleMaxIndex = _calculateVisibleMaxIndex(_scrollController.offset);
      // Trigger loading for items slightly beyond the visible range
      final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2;
      if (preloadIndex < _items.length) {
        _triggerBatchLoading(preloadIndex);
      }
    }
  }

  int _calculateVisibleMaxIndex(double offset) {
    if (!mounted || !context.mounted || !context.findRenderObject()!.paintBounds.isFinite) {
      return 0;
    }
    try {
      final itemWidth = (MediaQuery.of(context).size.width - (widget.crossAxisCount - 1) * widget.crossAxisSpacing - (widget.padding?.horizontal ?? 0)) / widget.crossAxisCount;
      final itemHeight = itemWidth / widget.childAspectRatio + widget.mainAxisSpacing;
      if (itemHeight <= 0) return 0; // Avoid division by zero
      final itemsPerRow = widget.crossAxisCount;
      final rowsVisible = (offset + MediaQuery.of(context).size.height) / itemHeight;
      return min((rowsVisible * itemsPerRow).ceil(), _items.length - 1);
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error calculating visible index: $e');
      return _items.isNotEmpty ? _items.length - 1 : 0;
    }
  }

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

  Future<void> _loadMoreData() async {
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Cannot load more data while offline.');
      return;
    }
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    debugPrint('$connectivityLogPrefix Grid loading more data...');
    setState(() { _loadMoreStatus = LoadMoreStatus.loading; });

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
          setState(() {
            _loadMoreStatus = LoadMoreStatus.noMoreData;
            _hasMoreData = false;
          });
          return; // No more items found
        }

        // Collect fetched items for caching if offline mode is on
        if (widget.offlineMode) {
          itemsToCacheBatch.addAll(results);
        }

        // --- Update UI FIRST ---
        setState(() {
          _items.addAll(results);
          _loadMoreStatus = LoadMoreStatus.idle;
        });
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

      } else {
        // Handle query failure
        debugPrint('$connectivityLogPrefix LoadMore Error: ${parseResponse.error?.message}');
        setState(() { _loadMoreStatus = LoadMoreStatus.error; });
      }
    } catch (e) {
      // Handle general error during load more
      debugPrint('$connectivityLogPrefix Error loading more grid data: $e');
      setState(() { _loadMoreStatus = LoadMoreStatus.error; });
    }
  }

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
    debugPrint('$connectivityLogPrefix Loading initial data from server...');
    List<T> itemsToCacheBatch = []; // Prepare list for batch caching

    try {
      // Reset state
      _currentPage = 0;
      _loadMoreStatus = LoadMoreStatus.idle;
      _hasMoreData = true;
      _items.clear();
      _loadingIndices.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {}); // Show loading state

      // Prepare query
      final initialQuery = QueryBuilder<T>.copy(widget.query);
      if (widget.pagination) {
        initialQuery..setAmountToSkip(0)..setLimit(widget.pageSize);
      } else {
        if (!initialQuery.limiters.containsKey('limit')) {
          initialQuery.setLimit(widget.nonPaginatedLimit);
        }
      }

      // Fetch from server using ParseLiveList
      final originalLiveGrid = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
      );

      final liveGrid = CachedParseLiveList<T>(originalLiveGrid, widget.cacheSize, widget.lazyLoading);
      _liveGrid?.dispose(); // Dispose previous list if any
      _liveGrid = liveGrid;

      // Populate _items directly from server data and collect for caching
      if (liveGrid.size > 0) {
        for (int i = 0; i < liveGrid.size; i++) {
          final item = liveGrid.getPreLoadedAt(i);
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
      if (widget.pagination && _hasMoreData) { // Only if pagination is on and initial load wasn't empty
         _proactivelyCacheNextPage(1); // Start caching page 1 (index 1)
      }
      // --- End Proactive Cache Trigger ---

      // --- Stream Listener ---
      liveGrid.stream.listen((event) {
        if (!mounted) return;

        T? objectToCache;

        try { // Wrap event processing
          if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
            final addedItem = event.object as T;
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
            final updatedItem = event.object as T;
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

      // --- Initial Lazy Loading Trigger ---
      if (widget.lazyLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final visibleMaxIndex = _calculateVisibleMaxIndex(0);
          final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2; // Preload a couple of rows ahead
          if (preloadIndex < _items.length) {
            _triggerBatchLoading(preloadIndex);
          }
        });
      }
      // --- End Lazy Loading Trigger ---

    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) setState(() {});
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
        // Check if core data like 'createdAt' is missing, indicating it might need fetching
        if (item.get<DateTime>(sdk.keyVarCreatedAt) == null && item.objectId != null) {
          // Collect fetch futures to run concurrently
          fetchFutures.add(item.fetch().then((_) {
             // Add successfully fetched items to the final list
             itemsToSaveFinal.add(item);
          }).catchError((fetchError) {
             debugPrint('$connectivityLogPrefix Error fetching object ${item.objectId} during batch save pre-fetch: $fetchError');
             // Optionally add partially loaded item anyway? itemsToSaveFinal.add(item);
          }));
        } else {
          // Item data is already available, add directly
          itemsToSaveFinal.add(item);
        }
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

  Future<void> _refreshData() async {
    debugPrint('$connectivityLogPrefix Refreshing Grid data...');
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        // Determine loading state: Online AND _liveGrid not yet initialized.
        final bool showLoadingIndicator = !isOffline && _liveGrid == null;

        if (showLoadingIndicator) {
          return widget.gridLoadingElement ?? const Center(child: CircularProgressIndicator());
        } else if (noData) {
          // Show empty state if not loading AND there are no items.
          return widget.queryEmptyElement ?? const Center(child: Text('No data available'));
        } else {
          // Show the grid if not loading and there are items.
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                Expanded(
                  child: buildAnimatedGrid(), // Use helper for GridView
                ),
                // Show footer only if pagination is enabled and items exist
                if (widget.pagination && _items.isNotEmpty)
                  widget.footerBuilder != null
                      ? widget.footerBuilder!(context, _loadMoreStatus)
                      : _buildDefaultFooter(),
              ],
            ),
          );
        }
      },
    );
  }

  // Builds the default footer based on the load more status
  Widget _buildDefaultFooter() {
    switch (_loadMoreStatus) {
      case LoadMoreStatus.loading:
        return Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            );
      case LoadMoreStatus.noMoreData:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          alignment: Alignment.center,
          child: const Text("No more items to load"),
        );
      case LoadMoreStatus.error:
        return InkWell(
          onTap: _loadMoreData, // Allow retry on tap
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: const Text("Error loading more items. Tap to retry."),
          ),
        );
      case LoadMoreStatus.idle:
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper to build the GridView
  Widget buildAnimatedGrid() {
    // Note: AnimationController is not currently used for item animations here
    // final Animation<double> boxAnimation = widget.animationController != null
    //     ? Tween<double>(begin: 0.0, end: 1.0).animate(...)
    //     : const AlwaysStoppedAnimation<double>(1.0);

    return GridView.builder(
      reverse: widget.reverse,
      padding: widget.padding,
      physics: widget.scrollPhysics,
      controller: _scrollController, // Use state's controller
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      itemCount: _items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemBuilder: (BuildContext context, int index) {
        final item = _items[index];

        // Note: _triggerBatchLoading is called in _onScroll now

        StreamGetter<T>? itemStream;
        DataGetter<T>? loadedData;
        DataGetter<T>? preLoadedData;

        final liveGrid = _liveGrid;
        if (!isOffline && liveGrid != null && index < liveGrid.size) {
          itemStream = () => liveGrid.getAt(index);
          loadedData = () => liveGrid.getLoadedAt(index);
          preLoadedData = () => liveGrid.getPreLoadedAt(index);
        } else {
          // Offline or before _liveGrid ready
          loadedData = () => item;
          preLoadedData = () => item;
        }

        return ParseLiveListElementWidget<T>(
          key: ValueKey<String>(item.objectId ?? 'unknown-$index-${item.hashCode}'), // Ensure unique key
          stream: itemStream,
          loadedData: loadedData,
          preLoadedData: preLoadedData,
          sizeFactor: const AlwaysStoppedAnimation<double>(1.0), // No animation for now
          duration: widget.duration,
          childBuilder: widget.childBuilder ?? ParseLiveGridWidget.defaultChildBuilder,
          index: index,
        );
      },
    );
  }

  // Triggers loading for a range of items (used for lazy loading)
  void _triggerBatchLoading(int targetIndex) {
    if (isOffline || !widget.lazyLoading || _liveGrid == null) return;

    // Determine the range of items to potentially load around the target index
    final batchSize = widget.lazyBatchSize > 0 ? widget.lazyBatchSize : widget.crossAxisCount * 2;
    final startIdx = max(0, targetIndex - batchSize); // Load items before target
    final endIdx = min(_items.length - 1, targetIndex + batchSize); // Load items after target

    for (int i = startIdx; i <= endIdx; i++) {
      // Check bounds, if not already loading, and if data isn't already loaded
      if (i >= 0 && i < _liveGrid!.size && !_loadingIndices.contains(i) && _liveGrid!.getLoadedAt(i) == null) {
        _loadingIndices.add(i); // Mark as loading
        _liveGrid!.getAt(i).first.then((loadedItem) {
          _loadingIndices.remove(i); // Unmark
          if (loadedItem != null && mounted && i < _items.length) {
            // Update the item in the list if it was successfully loaded
            // Note: This might cause a jump if the preloaded data was significantly different
            setState(() { _items[i] = loadedItem; });
          }
        }).catchError((e) {
          _loadingIndices.remove(i); // Unmark on error
          debugPrint('$connectivityLogPrefix Error lazy loading grid item at index $i: $e');
        });
      }
    }
  }

  @override
  void dispose() {
    disposeConnectivityHandler(); // Dispose mixin resources

    // Remove listener only if we added it
    if ((widget.pagination || widget.lazyLoading) && widget.scrollController == null) {
       _scrollController.removeListener(_onScroll);
    }
    // Dispose controller only if we created it
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    _liveGrid?.dispose(); // Dispose live list resources
    _noDataNotifier.dispose(); // Dispose value notifier
    super.dispose();
  }
}

// --- ParseLiveListElementWidget remains unchanged ---
// (Should be identical to the one in parse_live_list.dart)
// class ParseLiveListElementWidget<T extends sdk.ParseObject> extends StatefulWidget { ... }
// class _ParseLiveListElementWidgetState<T extends sdk.ParseObject> extends State<ParseLiveListElementWidget<T>> { ... }