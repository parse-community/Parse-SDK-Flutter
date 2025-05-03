part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// The type of function that builds a child widget for a ParseLiveList element.
typedef ChildBuilder<T extends sdk.ParseObject> = Widget Function(
    BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]);

/// The type of function that returns the stream to listen for updates from.
typedef StreamGetter<T extends sdk.ParseObject> = Stream<T> Function();

/// The type of function that returns the loaded data for a ParseLiveList element.
typedef DataGetter<T extends sdk.ParseObject> = T? Function();

/// Represents the status of the load more operation
enum LoadMoreStatus {
  idle,
  loading,
  noMoreData,
  error,
}

/// Footer builder for pagination
typedef FooterBuilder = Widget Function(BuildContext context, LoadMoreStatus loadMoreStatus);

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
  final ChildBuilder<T>? removedItemBuilder;

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

class _ParseLiveListWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListWidget<T>> with ConnectivityHandlerMixin<ParseLiveListWidget<T>> {
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

    if (widget.scrollController == null) {
      _scrollController = ScrollController();
    } else {
      if (widget.pagination) {
        _scrollController = widget.scrollController!;
      } else {
        _scrollController = widget.scrollController ?? ScrollController();
      }
    }

    if (widget.pagination) {
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

    debugPrint('$connectivityLogPrefix Loading data from cache...');
    _items.clear();

    try {
      final cached = await sdk.ParseObjectOffline.loadAllFromLocalCache(
        widget.query.object.parseClassName,
      );
      for (final obj in cached) {
        _items.add(widget.fromJson(obj.toJson(full: true)));
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
    if (isOffline) {
      debugPrint('$connectivityLogPrefix Offline: Skipping server load, relying on cache.');
      if (isOfflineModeEnabled) {
        await loadDataFromCache();
      }
      return;
    }

    debugPrint('$connectivityLogPrefix Loading initial data from server...');
    try {
      if (widget.pagination) {
        _currentPage = 0;
        _loadMoreStatus = LoadMoreStatus.idle;
        _hasMoreData = true;
      }

      _items.clear();
      _noDataNotifier.value = true; // Assume no data initially
      // Set loading state visually *before* async work
      if (mounted) setState(() {});

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

      final originalLiveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
      );

      final liveList = CachedParseLiveList<T>(originalLiveList, widget.cacheSize, widget.lazyLoading);
      _liveList?.dispose();
      _liveList = liveList;

      // --- Refactored Initial Item Handling ---
      final List<T> initialItems = [];
      final List<T> itemsToFetchAndCache = []; // Items needing background processing

      if (liveList.size > 0) {
        for (int i = 0; i < liveList.size; i++) {
          final item = liveList.getPreLoadedAt(i);
          if (item != null) {
            initialItems.add(item); // Add preloaded item for immediate display
            // If offline mode is on, mark for background fetch/cache
            if (widget.offlineMode) {
              itemsToFetchAndCache.add(item);
            }
          }
        }
      }

      // Update the UI immediately with preloaded items
      _items.addAll(initialItems);
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) {
        setState(() {});
      }
      // --- End Refactored Initial Item Handling ---

      // --- Start Background Fetching and Caching (if needed) ---
      if (itemsToFetchAndCache.isNotEmpty) {
        // Don't await this block, let it run in the background
        _fetchAndCacheItemsInBackground(itemsToFetchAndCache);
      }
      // --- End Background Fetching and Caching ---

      // --- Stream Listener (remains the same) ---
      liveList.stream.listen((event) {
        T? objectToCache;

        if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
          final addedItem = event.object as T; // Cast needed
          if (mounted) {
            setState(() { _items.insert(event.index, addedItem); });
          }
          objectToCache = addedItem;
        } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
          if (event.index >= 0 && event.index < _items.length) {
            final removedItem = _items.removeAt(event.index);
            if (mounted) {
              setState(() {});
            }
            if (widget.offlineMode) {
              removedItem.removeFromLocalCache();
            }
          } else {
            debugPrint('$connectivityLogPrefix LiveList Delete Event: Invalid index ${event.index}, list size ${_items.length}');
          }
        } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
          final updatedItem = event.object as T; // Cast needed
          if (event.index >= 0 && event.index < _items.length) {
            if (mounted) {
              setState(() { _items[event.index] = updatedItem; });
            }
            objectToCache = updatedItem;
          } else {
            debugPrint('$connectivityLogPrefix LiveList Update Event: Invalid index ${event.index}, list size ${_items.length}');
          }
        }

        // Save updates from stream immediately (usually less performance critical than initial load)
        if (widget.offlineMode && objectToCache != null) {
          // Consider if fetch is needed for stream events too, though often they are complete
          objectToCache.saveToLocalCache();
        }

        _noDataNotifier.value = _items.isEmpty;
      });
      // --- End Stream Listener ---

    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) {
        setState(() {});
      }
    }
  }

  // --- Helper for Background Caching ---
  Future<void> _fetchAndCacheItemsInBackground(List<T> items) async {
     debugPrint('$connectivityLogPrefix Starting background fetch/cache for ${items.length} items...');
     for (final item in items) {
       try {
         // Check if still mounted within the loop if operations are long
         if (!mounted) return;

         // Fetch *only* if lazy loading is enabled to ensure cached data is complete
         if (widget.lazyLoading) {
           // Fetch the full object data before saving to cache when lazy loading.
           // We assume that if lazy loading is on, the initial object might be incomplete.
           await item.fetch();
         }
         await item.saveToLocalCache();
       } catch (e) {
         // Log error but continue with the next item
         debugPrint('$connectivityLogPrefix Error background saving object ${item.objectId} to cache: $e');
       }
     }
     debugPrint('$connectivityLogPrefix Finished background fetch/cache.');
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

    debugPrint('$connectivityLogPrefix Loading more data...');
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;

      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount)
        ..setLimit(widget.pageSize);

      debugPrint('$connectivityLogPrefix Loading page $_currentPage, Skip: $skipCount, Limit: ${widget.pageSize}');
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
          return;
        }

        if (widget.offlineMode) {
          for (final item in results) {
            try {
              if (widget.lazyLoading) {
                await item.fetch();
              }
              await item.saveToLocalCache();
            } catch (e) {
              debugPrint('$connectivityLogPrefix Error saving fetched object ${item.objectId} from loadMore to cache: $e');
            }
          }
        }

        setState(() {
          _items.addAll(results);
          _loadMoreStatus = LoadMoreStatus.idle;
        });
      } else {
        setState(() {
          _loadMoreStatus = LoadMoreStatus.error;
        });
      }
    } catch (e) {
      debugPrint('$connectivityLogPrefix Error loading more data: $e');
      setState(() {
        _loadMoreStatus = LoadMoreStatus.error;
      });
    }
  }

  void _onScroll() {
    if (isOffline) return;

    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }
    final scrollController = widget.scrollController ?? _scrollController;
    if (!scrollController.hasClients) {
      return;
    }
    final offset = scrollController.position.maxScrollExtent - scrollController.position.pixels;
    if (offset < widget.loadMoreOffset) {
      _loadMoreData();
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
        final bool showLoadingIndicator =
            (!isOffline && _liveList == null) || (isOffline && _items.isEmpty && !noData);

        if (showLoadingIndicator) {
          return widget.listLoadingElement ?? const Center(child: CircularProgressIndicator());
        }

        if (noData && (_liveList != null || isOffline)) {
          return widget.queryEmptyElement ?? const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  physics: widget.scrollPhysics,
                  controller: widget.scrollController ?? _scrollController,
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

                    final liveList = _liveList;
                    if (!isOffline && liveList != null && index < liveList.size) {
                      itemStream = () => liveList.getAt(index);
                      loadedData = () => liveList.getLoadedAt(index);
                      preLoadedData = () => liveList.getPreLoadedAt(index);
                    } else {
                      loadedData = () => item;
                      preLoadedData = () => item;
                    }

                    return ParseLiveListElementWidget<T>(
                      key: ValueKey<String>(item.objectId ?? 'unknown-$index'),
                      stream: itemStream,
                      loadedData: loadedData,
                      preLoadedData: preLoadedData,
                      sizeFactor: const AlwaysStoppedAnimation<double>(1.0),
                      duration: widget.duration,
                      childBuilder: widget.childBuilder ?? ParseLiveListWidget.defaultChildBuilder,
                      index: index,
                    );
                  },
                ),
              ),
              if (widget.pagination && _items.isNotEmpty)
                widget.footerBuilder != null
                    ? widget.footerBuilder!(context, _loadMoreStatus)
                    : _buildDefaultFooter(),
            ],
          ),
        );
      },
    );
  }

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
          onTap: _loadMoreData,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: const Text("Error loading more items. Tap to retry."),
          ),
        );
      case LoadMoreStatus.idle:
      default:
        return Container(height: 0);
    }
  }

  @override
  void dispose() {
    disposeConnectivityHandler();

    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      if (widget.pagination) {
        _scrollController.removeListener(_onScroll);
      }
    }
    _liveList?.dispose();
    _noDataNotifier.dispose();
    super.dispose();
  }
}

class ParseLiveListElementWidget<T extends sdk.ParseObject> extends StatefulWidget {
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
  final ParseError? error;

  bool get hasData => loadedData != null;

  @override
  State<ParseLiveListElementWidget<T>> createState() =>
      _ParseLiveListElementWidgetState<T>();
}

class _ParseLiveListElementWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListElementWidget<T>> {
  late sdk.ParseLiveListElementSnapshot<T> _snapshot;
  StreamSubscription<T>? _streamSubscription;

  bool get hasData => widget.loadedData != null;
  bool get failed => widget.error != null;

  @override
  void initState() {
    super.initState();
    _snapshot = sdk.ParseLiveListElementSnapshot<T>(
      loadedData: widget.loadedData?.call(),
      preLoadedData: widget.preLoadedData?.call(),
    );

    if (widget.stream != null) {
      _streamSubscription = widget.stream!().listen(
        (data) {
          setState(() {
            _snapshot = sdk.ParseLiveListElementSnapshot<T>(
              loadedData: data,
              preLoadedData: data,
            );
          });
        },
        onError: (error) {
          if (error is sdk.ParseError) {
            setState(() {
              _snapshot = sdk.ParseLiveListElementSnapshot<T>(error: error);
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.sizeFactor,
      child: widget.index != null
          ? widget.childBuilder(context, _snapshot, widget.index)
          : widget.childBuilder(context, _snapshot),
    );
  }
}

