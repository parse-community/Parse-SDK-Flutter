part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// The type of function that builds a child widget for a ParseLiveList element.
typedef ChildBuilder<T extends sdk.ParseObject> =
    Widget Function(
      BuildContext context,
      sdk.ParseLiveListElementSnapshot<T> snapshot, [
      int? index,
    ]);

/// The type of function that returns the stream to listen for updates from.
typedef StreamGetter<T extends sdk.ParseObject> = Stream<T> Function();

/// The type of function that returns the loaded data for a ParseLiveList element.
typedef DataGetter<T extends sdk.ParseObject> = T? Function();

/// Represents the status of the load more operation
enum LoadMoreStatus { idle, loading, noMoreData, error }

/// Footer builder for pagination
typedef FooterBuilder =
    Widget Function(BuildContext context, LoadMoreStatus loadMoreStatus);

/// A widget that displays a live list of Parse objects.
class ParseLiveListWidget<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveListWidget({
    super.key,
    required this.query,
    this.listLoadingElement,
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
    this.removedItemBuilder,
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = true,
    this.preloadedColumns,
    this.excludedColumns,
    this.pagination = false,
    this.pageSize = 20,
    this.nonPaginatedLimit = 1000,
    this.paginationLoadingElement,
    this.footerBuilder,
    this.loadMoreOffset = 200.0,
    this.cacheSize = 50,
    this.offlineMode = false,
    required this.fromJson,
  });

  final sdk.QueryBuilder<T> query;
  final Widget? listLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;
  final ScrollPhysics? scrollPhysics;
  final ScrollController? scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final bool? primary;
  final bool reverse;
  final bool shrinkWrap;

  final ChildBuilder<T>? childBuilder;
  final ChildBuilder<T>?
  removedItemBuilder; // Note: removedItemBuilder is not currently used in the state logic

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;

  final bool pagination;
  final Widget? paginationLoadingElement;
  final FooterBuilder? footerBuilder;
  final double loadMoreOffset;
  final int pageSize;
  final int nonPaginatedLimit;
  final int cacheSize;
  final bool offlineMode;

  final T Function(Map<String, dynamic> json) fromJson;

  @override
  State<ParseLiveListWidget<T>> createState() => _ParseLiveListWidgetState<T>();

  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
    BuildContext context,
    sdk.ParseLiveListElementSnapshot<T> snapshot, [
    int? index,
  ]) {
    if (snapshot.failed) {
      return const Text('Something went wrong!');
    } else if (snapshot.hasData) {
      return ListTile(
        title: Text(
          snapshot.loadedData?.get<String>(sdk.keyVarObjectId) ??
              'Missing Data!',
        ),
        subtitle: index != null ? Text('Item #$index') : null,
      );
    } else {
      return const ListTile(leading: CircularProgressIndicator());
    }
  }
}

class _ParseLiveListWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListWidget<T>>
    with ConnectivityHandlerMixin<ParseLiveListWidget<T>> {
  CachedParseLiveList<T>? _liveList;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[];

  late final ScrollController _scrollController;
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  String get connectivityLogPrefix => 'ParseLiveListWidget';

  @override
  bool get isOfflineModeEnabled => widget.offlineMode;

  @override
  void disposeLiveList() {
    _liveList?.dispose();
    _liveList = null;
  }

  @override
  Future<void> loadDataFromServer() => _loadData();

  @override
  Future<void> loadDataFromCache() => _loadFromCache();

  @override
  void initState() {
    super.initState();

    // Initialize ScrollController
    if (widget.scrollController == null) {
      _scrollController = ScrollController();
    } else {
      // Use provided controller, but ensure it's the one we listen to if pagination is on
      _scrollController = widget.scrollController!;
    }

    // Add listener only if pagination is enabled and we own the controller or are using the provided one
    if (widget.pagination) {
      _scrollController.addListener(_onScroll);
    }

    // Initialize connectivity and load initial data
    initConnectivityHandler();
  }

  Future<void> _loadFromCache() async {
    if (!isOfflineModeEnabled) {
      debugPrint(
        '$connectivityLogPrefix Offline mode disabled, skipping cache load.',
      );
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {});
      return;
    }

    debugPrint('$connectivityLogPrefix Loading data from cache...');
    _items.clear();

    try {
      final cached = await ParseObjectOffline.loadAllFromLocalCache(
        widget.query.object.parseClassName,
      );
      for (final obj in cached) {
        try {
          _items.add(widget.fromJson(obj.toJson(full: true)));
        } catch (e) {
          debugPrint(
            '$connectivityLogPrefix Error deserializing cached object: $e',
          );
        }
      }
      debugPrint(
        '$connectivityLogPrefix Loaded ${_items.length} items from cache for ${widget.query.object.parseClassName}',
      );
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data from cache: $e');
    }

    _noDataNotifier.value = _items.isEmpty;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    // If offline, attempt to load from cache and exit
    if (isOffline) {
      debugPrint(
        '$connectivityLogPrefix Offline: Skipping server load, relying on cache.',
      );
      if (isOfflineModeEnabled) {
        await loadDataFromCache();
      }
      return;
    }

    // --- Online Loading Logic ---
    debugPrint('$connectivityLogPrefix Loading initial data from server...');
    List<T> itemsToCacheBatch = []; // Prepare list for batch caching

    try {
      // Reset pagination and state
      if (widget.pagination) {
        _currentPage = 0;
        _loadMoreStatus = LoadMoreStatus.idle;
        _hasMoreData = true;
      }
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {}); // Show loading state immediately

      // Prepare query
      final initialQuery = QueryBuilder<T>.copy(widget.query);
      if (widget.pagination) {
        initialQuery
          ..setAmountToSkip(0)
          ..setLimit(widget.pageSize);
      } else {
        if (!initialQuery.limiters.containsKey('limit')) {
          initialQuery.setLimit(widget.nonPaginatedLimit);
        }
      }

      // Fetch from server using ParseLiveList for live updates
      final originalLiveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading
            ? (widget.listeningIncludes ?? [])
            : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading
            ? (widget.preloadedColumns ?? [])
            : widget.preloadedColumns,
      );

      final liveList = CachedParseLiveList<T>(
        originalLiveList,
        widget.cacheSize,
        widget.lazyLoading,
      );
      _liveList?.dispose(); // Dispose previous list if any
      _liveList = liveList;

      // Populate _items directly from server data and collect for caching
      if (liveList.size > 0) {
        for (int i = 0; i < liveList.size; i++) {
          // Use preLoaded data for initial display speed
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

      // --- Stream Listener ---
      liveList.stream.listen(
        (event) {
          if (!mounted) return; // Avoid processing if widget is disposed

          T? objectToCache; // For single item cache updates from stream

          try {
            // Wrap event processing in try-catch
            if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
              final addedItem = event.object;
              setState(() {
                _items.insert(event.index, addedItem);
              });
              objectToCache = addedItem;
            } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
              if (event.index >= 0 && event.index < _items.length) {
                final removedItem = _items.removeAt(event.index);
                setState(() {});
                if (widget.offlineMode) {
                  // Remove deleted item from cache immediately
                  removedItem.removeFromLocalCache().catchError((e) {
                    debugPrint(
                      '$connectivityLogPrefix Error removing item ${removedItem.objectId} from cache: $e',
                    );
                  });
                }
              } else {
                debugPrint(
                  '$connectivityLogPrefix LiveList Delete Event: Invalid index ${event.index}, list size ${_items.length}',
                );
              }
            } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
              final updatedItem = event.object;
              if (event.index >= 0 && event.index < _items.length) {
                setState(() {
                  _items[event.index] = updatedItem;
                });
                objectToCache = updatedItem;
              } else {
                debugPrint(
                  '$connectivityLogPrefix LiveList Update Event: Invalid index ${event.index}, list size ${_items.length}',
                );
              }
            }

            // Save single updates from stream immediately if offline mode is on
            if (widget.offlineMode && objectToCache != null) {
              // Fetch might be needed if stream update is partial and lazy loading is on
              // For simplicity, assuming stream provides complete object or fetch isn't critical here
              objectToCache.saveToLocalCache().catchError((e) {
                debugPrint(
                  '$connectivityLogPrefix Error saving stream update for ${objectToCache?.objectId} to cache: $e',
                );
              });
            }

            _noDataNotifier.value = _items.isEmpty;
          } catch (e) {
            debugPrint(
              '$connectivityLogPrefix Error processing stream event: $e',
            );
            // Optionally update state to reflect error
          }
        },
        onError: (error) {
          debugPrint('$connectivityLogPrefix LiveList Stream Error: $error');
          // Optionally handle stream errors (e.g., show error message)
          if (mounted) {
            setState(() {
              /* Potentially update state to show error */
            });
          }
        },
      );
      // --- End Stream Listener ---
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) {
        setState(() {}); // Update UI to potentially show empty/error state
      }
    }
  }

  // --- Helper to Save Batch to Cache (Handles Fetch if Lazy Loading) ---
  Future<void> _saveBatchToCache(List<T> itemsToSave) async {
    if (itemsToSave.isEmpty || !widget.offlineMode) return;

    debugPrint(
      '$connectivityLogPrefix Saving batch of ${itemsToSave.length} items to cache...',
    );
    Stopwatch stopwatch = Stopwatch()..start();

    List<T> itemsToSaveFinal = [];
    List<Future<void>> fetchFutures = [];

    // First, handle potential fetches if lazy loading is enabled
    if (widget.lazyLoading) {
      for (final item in itemsToSave) {
        // Check if a key typically set by the server (like updatedAt) is missing,
        // indicating the object might need fetching.
        if (!item.containsKey(sdk.keyVarUpdatedAt)) {
          // Collect fetch futures to run concurrently
          fetchFutures.add(
            item
                .fetch()
                .then((_) {
                  // Add successfully fetched items to the final list
                  itemsToSaveFinal.add(item);
                })
                .catchError((fetchError) {
                  debugPrint(
                    '$connectivityLogPrefix Error fetching object ${item.objectId} during batch save pre-fetch: $fetchError',
                  );
                  // Optionally add partially loaded item anyway? itemsToSaveFinal.add(item);
                }),
          );
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
        await ParseObjectOffline.saveAllToLocalCache(
          className,
          itemsToSaveFinal,
        );
      } catch (e) {
        debugPrint(
          '$connectivityLogPrefix Error during batch save operation: $e',
        );
      }
    }

    stopwatch.stop();
    // Adjust log message as the static method now prints details
    debugPrint(
      '$connectivityLogPrefix Finished batch save processing in ${stopwatch.elapsedMilliseconds}ms.',
    );
  }
  // --- End Helper ---

  // --- Helper to Proactively Cache the Next Page ---
  Future<void> _proactivelyCacheNextPage(int pageNumberToCache) async {
    // Only run if online, offline mode is on, and pagination is enabled
    if (isOffline || !widget.offlineMode || !widget.pagination) return;

    debugPrint(
      '$connectivityLogPrefix Proactively caching page $pageNumberToCache...',
    );
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
          debugPrint(
            '$connectivityLogPrefix Proactive cache: Page $pageNumberToCache was empty.',
          );
        }
      } else {
        debugPrint(
          '$connectivityLogPrefix Proactive cache failed for page $pageNumberToCache: ${response.error?.message}',
        );
      }
    } catch (e) {
      debugPrint(
        '$connectivityLogPrefix Proactive cache exception for page $pageNumberToCache: $e',
      );
    }
  }
  // --- End Helper ---

  Future<void> _loadMoreData() async {
    // Prevent loading more if offline, already loading, or no more data
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Cannot load more data while offline.');
      return;
    }
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    debugPrint('$connectivityLogPrefix Loading more data...');
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });

    List<T> itemsToCacheBatch = []; // Prepare list for batch caching

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;
      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount)
        ..setLimit(widget.pageSize);

      // Fetch next page from server
      final parseResponse = await nextPageQuery.query();
      debugPrint(
        '$connectivityLogPrefix LoadMore Response: Success=${parseResponse.success}, Count=${parseResponse.count}, Results=${parseResponse.results?.length}, Error: ${parseResponse.error?.message}',
      );

      if (parseResponse.success && parseResponse.results != null) {
        final List<dynamic> rawResults = parseResponse.results!;
        final List<T> results = rawResults
            .map((dynamic obj) => obj as T)
            .toList();

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
        if (_hasMoreData) {
          // Check if the current load didn't signal the end
          _proactivelyCacheNextPage(_currentPage + 1); // Start caching page N+1
        }
        // --- End Proactive Cache Trigger ---
      } else {
        // Handle query failure
        debugPrint(
          '$connectivityLogPrefix LoadMore Error: ${parseResponse.error?.message}',
        );
        setState(() {
          _loadMoreStatus = LoadMoreStatus.error;
        });
      }
    } catch (e) {
      // Handle general error during load more
      debugPrint('$connectivityLogPrefix Error loading more data: $e');
      setState(() {
        _loadMoreStatus = LoadMoreStatus.error;
      });
    }
  }

  void _onScroll() {
    // Trigger load more only if online, not already loading, and has more data
    if (isOffline ||
        _loadMoreStatus == LoadMoreStatus.loading ||
        !_hasMoreData) {
      return;
    }

    // Check if scroll controller is attached and near the end
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= widget.loadMoreOffset) {
      _loadMoreData();
    }
  }

  Future<void> _refreshData() async {
    debugPrint('$connectivityLogPrefix Refreshing data...');
    disposeLiveList(); // Dispose existing live list before refresh

    // Reload based on connectivity
    if (isOffline) {
      debugPrint(
        '$connectivityLogPrefix Refreshing offline, loading from cache.',
      );
      await loadDataFromCache();
    } else {
      debugPrint(
        '$connectivityLogPrefix Refreshing online, loading from server.',
      );
      await loadDataFromServer(); // This now calls the updated _loadData
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        // Determine loading state: Only show if online AND _liveList is not yet initialized.
        final bool showLoadingIndicator = !isOffline && _liveList == null;

        if (showLoadingIndicator) {
          return widget.listLoadingElement ??
              const Center(child: CircularProgressIndicator());
        } else if (noData) {
          // Show empty state if not loading AND there are no items.
          return widget.queryEmptyElement ??
              const Center(child: Text('No data available'));
        } else {
          // Show the list if not loading and there are items.
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: widget.scrollPhysics,
                    controller: _scrollController, // Use the state's controller
                    scrollDirection: widget.scrollDirection,
                    padding: widget.padding,
                    primary: widget.primary,
                    reverse: widget.reverse,
                    shrinkWrap: widget.shrinkWrap,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      StreamGetter<T>? itemStream;
                      DataGetter<T>? loadedData;
                      DataGetter<T>? preLoadedData;

                      // Use _liveList ONLY if it's initialized (i.e., we are online and loaded)
                      final liveList = _liveList;
                      if (liveList != null && index < liveList.size) {
                        itemStream = () => liveList.getAt(index);
                        loadedData = () => liveList.getLoadedAt(index);
                        preLoadedData = () => liveList.getPreLoadedAt(index);
                      } else {
                        // Offline or before _liveList is ready: Use data directly from _items
                        loadedData = () => item;
                        preLoadedData = () => item;
                      }

                      return ParseLiveListElementWidget<T>(
                        key: ValueKey<String>(
                          item.objectId ?? 'unknown-$index-${item.hashCode}',
                        ), // Ensure unique key
                        stream: itemStream, // Will be null when offline
                        loadedData: loadedData,
                        preLoadedData: preLoadedData,
                        sizeFactor: const AlwaysStoppedAnimation<double>(
                          1.0,
                        ), // Assuming no animations for now
                        duration: widget.duration,
                        childBuilder:
                            widget.childBuilder ??
                            ParseLiveListWidget.defaultChildBuilder,
                        index: index,
                      );
                    },
                  ),
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
        return widget.paginationLoadingElement ??
            Container(
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
        // Return an empty container when idle or in default case
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    disposeConnectivityHandler(); // Dispose mixin resources

    // Remove listener only if we added it
    if (widget.pagination && widget.scrollController == null) {
      _scrollController.removeListener(_onScroll);
    }
    // Dispose controller only if we created it
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    _liveList?.dispose(); // Dispose live list resources
    _noDataNotifier.dispose(); // Dispose value notifier
    super.dispose();
  }
}

// --- ParseLiveListElementWidget remains unchanged ---
class ParseLiveListElementWidget<T extends sdk.ParseObject>
    extends StatefulWidget {
  const ParseLiveListElementWidget({
    super.key,
    this.stream,
    this.loadedData,
    this.preLoadedData,
    required this.sizeFactor,
    required this.duration,
    required this.childBuilder,
    this.index,
    this.error,
  });

  final StreamGetter<T>? stream;
  final DataGetter<T>? loadedData;
  final DataGetter<T>? preLoadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder<T> childBuilder;
  final int? index;
  final ParseError?
  error; // Note: error parameter is not currently used in state logic

  bool get hasData => loadedData != null;

  @override
  State<ParseLiveListElementWidget<T>> createState() =>
      _ParseLiveListElementWidgetState<T>();
}

class _ParseLiveListElementWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListElementWidget<T>> {
  late sdk.ParseLiveListElementSnapshot<T> _snapshot;
  StreamSubscription<T>? _streamSubscription;

  // Removed redundant getters, use widget directly or _snapshot
  // bool get hasData => widget.loadedData != null;
  // bool get failed => widget.error != null;

  @override
  void initState() {
    super.initState();
    // Initialize snapshot with potentially preloaded/loaded data
    _snapshot = sdk.ParseLiveListElementSnapshot<T>(
      loadedData: widget.loadedData?.call(),
      preLoadedData: widget.preLoadedData?.call(),
      error: widget.error, // Initialize with potential error passed in
    );

    // Subscribe to stream if provided
    if (widget.stream != null) {
      _streamSubscription = widget.stream!().listen(
        (data) {
          if (mounted) {
            // Check if widget is still in the tree
            setState(() {
              // Update snapshot with new data from stream
              _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                loadedData: data,
                preLoadedData: _snapshot
                    .preLoadedData, // Keep original preLoadedData? Or update? Let's update.
                // preLoadedData: data,
              );
            });
          }
        },
        onError: (error) {
          if (mounted) {
            // Check if widget is still in the tree
            if (error is sdk.ParseError) {
              setState(() {
                // Update snapshot with error information
                _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                  error: error,
                  preLoadedData:
                      _snapshot.preLoadedData, // Keep previous data on error?
                  loadedData: _snapshot.loadedData,
                );
              });
            } else {
              // Handle non-ParseError errors if necessary
              debugPrint('ParseLiveListElementWidget Stream Error: $error');
              setState(() {
                _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                  error: sdk.ParseError(
                    message: error.toString(),
                  ), // Generic error
                  preLoadedData: _snapshot.preLoadedData,
                  loadedData: _snapshot.loadedData,
                );
              });
            }
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel(); // Cancel stream subscription
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use SizeTransition for potential animations (though factor is currently fixed)
    return SizeTransition(
      sizeFactor: widget.sizeFactor,
      child: widget.index != null
          ? widget.childBuilder(context, _snapshot, widget.index)
          : widget.childBuilder(context, _snapshot),
    );
  }
}
