part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// A widget that displays a live sliver list of Parse objects.
class ParseLiveSliverListWidget<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveSliverListWidget({
    super.key,
    required this.query,
    this.listLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.childBuilder,
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
    this.cacheSize = 50,
    this.offlineMode = false,
    required this.fromJson,
  });

  final sdk.QueryBuilder<T> query;
  final Widget? listLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;

  final ChildBuilder<T>? childBuilder;
  final ChildBuilder<T>? removedItemBuilder;

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;

  final bool pagination;
  final Widget? paginationLoadingElement;
  final FooterBuilder? footerBuilder;
  final int pageSize;
  final int nonPaginatedLimit;
  final int cacheSize;
  final bool offlineMode;

  final T Function(Map<String, dynamic> json) fromJson;

  @override
  State<ParseLiveSliverListWidget<T>> createState() => _ParseLiveSliverListWidgetState<T>();

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

class _ParseLiveSliverListWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveSliverListWidget<T>> with ConnectivityHandlerMixin<ParseLiveSliverListWidget<T>> {
  CachedParseLiveList<T>? _liveList;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[];

  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  String get connectivityLogPrefix => 'ParseLiveSliverListWidget';

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
    // Initialize connectivity and load initial data
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

    debugPrint('$connectivityLogPrefix Loading data from cache...');
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
        initialQuery..setAmountToSkip(0)..setLimit(widget.pageSize);
      } else {
        if (!initialQuery.limiters.containsKey('limit')) {
          initialQuery.setLimit(widget.nonPaginatedLimit);
        }
      }

      // Fetch from server using ParseLiveList for live updates
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

      // --- Trigger Proactive Cache for Next Page ---
      if (widget.pagination && _hasMoreData) { // Only if pagination is on and initial load wasn't empty
         _proactivelyCacheNextPage(1); // Start caching page 1 (index 1)
      }
      // --- End Proactive Cache Trigger ---

      // --- Stream Listener ---
      liveList.stream.listen((event) {
        if (!mounted) return; // Avoid processing if widget is disposed

        T? objectToCache; // For single item cache updates from stream

        try { // Wrap event processing in try-catch
          if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
            final addedItem = event.object as T;
            setState(() { _items.insert(event.index, addedItem); });
            objectToCache = addedItem;
          } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
            if (event.index >= 0 && event.index < _items.length) {
              final removedItem = _items.removeAt(event.index);
              setState(() {});
              if (widget.offlineMode) {
                // Remove deleted item from cache immediately
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

    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) setState(() {}); // Update UI to potentially show empty/error state
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
        if (!item.containsKey(sdk.keyVarUpdatedAt)) {
          fetchFutures.add(item.fetch().then((_) {
             itemsToSaveFinal.add(item);
          }).catchError((fetchError) {
             debugPrint('$connectivityLogPrefix Error fetching object ${item.objectId} during batch save pre-fetch: $fetchError');
          }));
        } else {
          itemsToSaveFinal.add(item);
        }
      }
      if (fetchFutures.isNotEmpty) {
         await Future.wait(fetchFutures);
      }
    } else {
      itemsToSaveFinal = itemsToSave;
    }

    // Now, save the final list using the efficient batch method
    if (itemsToSaveFinal.isNotEmpty) {
      try {
        final className = itemsToSaveFinal.first.parseClassName;
        await sdk.ParseObjectOffline.saveAllToLocalCache(className, itemsToSaveFinal);
      } catch (e) {
         debugPrint('$connectivityLogPrefix Error during batch save operation: $e');
      }
    }

    stopwatch.stop();
    debugPrint('$connectivityLogPrefix Finished batch save processing in ${stopwatch.elapsedMilliseconds}ms.');
  }

  // --- Helper to Proactively Cache the Next Page ---
  Future<void> _proactivelyCacheNextPage(int pageNumberToCache) async {
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

  Future<void> _loadMoreData() async {
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Cannot load more data while offline.');
      return;
    }
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    debugPrint('$connectivityLogPrefix Loading more data...');
    setState(() { _loadMoreStatus = LoadMoreStatus.loading; });

    List<T> itemsToCacheBatch = [];

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;
      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount)
        ..setLimit(widget.pageSize);

      final parseResponse = await nextPageQuery.query();

      if (parseResponse.success && parseResponse.results != null) {
        final List<dynamic> rawResults = parseResponse.results!;
        final List<T> results = rawResults.map((dynamic obj) => obj as T).toList();

        if (results.isEmpty) {
          setState(() {
            _loadMoreStatus = LoadMoreStatus.noMoreData;
            _hasMoreData = false;
          });
          return;
        }

        if (widget.offlineMode) {
          itemsToCacheBatch.addAll(results);
        }

        setState(() {
          _items.addAll(results);
          _loadMoreStatus = LoadMoreStatus.idle;
        });

        if (itemsToCacheBatch.isNotEmpty) {
          _saveBatchToCache(itemsToCacheBatch);
        }

        if (_hasMoreData) {
           _proactivelyCacheNextPage(_currentPage + 1);
        }

      } else {
        debugPrint('$connectivityLogPrefix LoadMore Error: ${parseResponse.error?.message}');
        setState(() { _loadMoreStatus = LoadMoreStatus.error; });
      }
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading more data: $e');
      setState(() { _loadMoreStatus = LoadMoreStatus.error; });
    }
  }

  Future<void> _refreshData() async {
    debugPrint('$connectivityLogPrefix Refreshing data...');
    disposeLiveList();

    if (isOffline) {
      debugPrint('$connectivityLogPrefix Refreshing offline, loading from cache.');
      await loadDataFromCache();
    } else {
      debugPrint('$connectivityLogPrefix Refreshing online, loading from server.');
      await loadDataFromServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        final bool showLoadingIndicator = !isOffline && _liveList == null;

        if (showLoadingIndicator) {
          return widget.listLoadingElement != null
              ? SliverToBoxAdapter(child: widget.listLoadingElement!)
              : const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
        } else if (noData) {
          return widget.queryEmptyElement != null
              ? SliverToBoxAdapter(child: widget.queryEmptyElement!)
              : const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No data available'),
                    ),
                  ),
                );
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                StreamGetter<T>? itemStream;
                DataGetter<T>? loadedData;
                DataGetter<T>? preLoadedData;

                final liveList = _liveList;
                if (liveList != null && index < liveList.size) {
                  itemStream = () => liveList.getAt(index);
                  loadedData = () => liveList.getLoadedAt(index);
                  preLoadedData = () => liveList.getPreLoadedAt(index);
                } else {
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
                  childBuilder: widget.childBuilder ?? ParseLiveSliverListWidget.defaultChildBuilder,
                  index: index,
                );
              },
              childCount: _items.length,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    disposeConnectivityHandler();
    _liveList?.dispose();
    _noDataNotifier.dispose();
    super.dispose();
  }
}