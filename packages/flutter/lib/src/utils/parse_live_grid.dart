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
    this.removedItemBuilder,
    this.listenOnAllSubItems,
    this.listeningIncludes,
    this.lazyLoading = true,
    this.preloadedColumns,
    this.excludedColumns,
    this.animationController,
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
    this.lazyBatchSize = 0,
    this.lazyTriggerOffset = 500.0,
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
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot) {
    if (snapshot.failed) {
      return const Text('Something went wrong!');
    } else if (snapshot.hasData) {
      return ListTile(
        title: Text(
          snapshot.loadedData!.get<String>(sdk.keyVarObjectId)!,
        ),
      );
    } else {
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }
}

class _ParseLiveGridWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveGridWidget<T>>  with ConnectivityHandlerMixin<ParseLiveGridWidget<T>> {
  CachedParseLiveList<T>? _liveGrid;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[];

  late final ScrollController _scrollController;
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  final Set<int> _loadingIndices = {};

  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();
  ConnectivityResult? _connectionStatus;

   // --- Implement Mixin Requirements ---
  @override
  Future<void> loadDataFromServer() => _loadData(); // Map to existing method

  @override
  Future<void> loadDataFromCache() => _loadFromCache(); // Map to existing method

  @override
  void disposeLiveList() {
    _liveGrid?.dispose();
    _liveGrid = null;
  }

  @override
  String get connectivityLogPrefix => 'ParseLiveGrid';

  @override
  bool get isOfflineModeEnabled => widget.offlineMode;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController == null) {
      _scrollController = ScrollController();
    } else {
      _scrollController = widget.scrollController!;
    }

    if (widget.pagination) {
      _scrollController.addListener(_onScroll);
    }

     initConnectivityHandler();

    // _initConnectivity();

    // _connectivitySubscription =
    //     _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
    //   final newResult = results.contains(ConnectivityResult.mobile)
    //       ? ConnectivityResult.mobile
    //       : results.contains(ConnectivityResult.wifi)
    //           ? ConnectivityResult.wifi
    //           : results.contains(ConnectivityResult.none)
    //               ? ConnectivityResult.none
    //               : ConnectivityResult.other;

    //   _updateConnectionStatus(newResult);
    // });
  }

  // Future<void> _initConnectivity() async {
  //   try {
  //     var connectivityResults = await _connectivity.checkConnectivity();
  //     final initialResult = connectivityResults.contains(ConnectivityResult.mobile)
  //         ? ConnectivityResult.mobile
  //         : connectivityResults.contains(ConnectivityResult.wifi)
  //             ? ConnectivityResult.wifi
  //             : connectivityResults.contains(ConnectivityResult.none)
  //                 ? ConnectivityResult.none
  //                 : ConnectivityResult.other;

  //     await _updateConnectionStatus(initialResult, isInitialCheck: true);
  //   } catch (e) {
  //     debugPrint('Error during initial connectivity check: $e');
  //     await _updateConnectionStatus(ConnectivityResult.none, isInitialCheck: true);
  //   }
  // }

  // Future<void> _updateConnectionStatus(ConnectivityResult result, {bool isInitialCheck = false}) async {
  //   if (result == _connectionStatus) {
  //     debugPrint('Grid Connectivity status unchanged: $result');
  //     return;
  //   }

  //   debugPrint('Grid Connectivity status changed: From $_connectionStatus to $result');
  //   final previousStatus = _connectionStatus;
  //   _connectionStatus = result;

  //   bool wasOnline = previousStatus != null && previousStatus != ConnectivityResult.none;
  //   bool isOnline = result == ConnectivityResult.mobile || result == ConnectivityResult.wifi;

  //   if (isOnline && !wasOnline) {
  //     _isOffline = false;
  //     debugPrint('Grid Transitioning Online: $result. Loading data from server...');
  //     await _loadData();
  //   } else if (!isOnline && wasOnline) {
  //     _isOffline = true;
  //     debugPrint('Grid Transitioning Offline: $result. Disposing liveGrid and loading from cache...');
  //     _liveGrid?.dispose();
  //     _liveGrid = null;
  //     await _loadFromCache();
  //   } else if (isInitialCheck) {
  //     if (isOnline) {
  //       _isOffline = false;
  //       debugPrint('Grid Initial State Online: $result. Loading data from server...');
  //       await _loadData();
  //     } else {
  //       _isOffline = true;
  //       debugPrint('Grid Initial State Offline: $result. Loading from cache...');
  //       await _loadFromCache();
  //     }
  //   } else {
  //     debugPrint('Grid Connectivity changed within same state (Online/Offline): $result');
  //   }
  // }

  Future<void> _loadFromCache() async {
    if (!isOfflineModeEnabled) {
      debugPrint('Offline mode disabled, skipping cache load.');
      _items.clear();
      _noDataNotifier.value = true;
      if (mounted) setState(() {});
      return;
    }

    debugPrint('Loading Grid data from cache...');
    _items.clear();

    try {
      final cached = await sdk.ParseObjectOffline.loadAllFromLocalCache(
        widget.query.object.parseClassName,
      );
      for (final obj in cached) {
        _items.add(widget.fromJson(obj.toJson(full: true)));
      }
      debugPrint('Loaded ${_items.length} items from cache for ${widget.query.object.parseClassName}');
    } catch (e) {
      debugPrint('Error loading grid data from cache: $e');
    }

    _noDataNotifier.value = _items.isEmpty;
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (isOffline) return;

    if (!widget.pagination || _loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    final scrollController = widget.scrollController ?? _scrollController;
    final offset = scrollController.position.maxScrollExtent - scrollController.position.pixels;

    if (offset < widget.loadMoreOffset) {
      _loadMoreData();
    }

    if (widget.lazyLoading) {
      final visibleMaxIndex = _calculateVisibleMaxIndex(scrollController.offset);
      final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2;

      if (preloadIndex < _items.length) {
        _triggerBatchLoading(preloadIndex);
      }
    }
  }

  int _calculateVisibleMaxIndex(double offset) {
    if (!mounted || !context.findRenderObject()!.paintBounds.isFinite) {
      return 0;
    }
    final itemWidth = (MediaQuery.of(context).size.width - (widget.crossAxisCount - 1) * widget.crossAxisSpacing - (widget.padding?.horizontal ?? 0)) / widget.crossAxisCount;
    final itemHeight = itemWidth / widget.childAspectRatio + widget.mainAxisSpacing;
    final itemsPerRow = widget.crossAxisCount;
    final rowsVisible = (offset + MediaQuery.of(context).size.height) / itemHeight;
    return min((rowsVisible * itemsPerRow).ceil(), _items.length - 1);
  }

  Future<void> _loadMoreData() async {
    if (isOffline) {
      debugPrint('Cannot load more data while offline.');
      return;
    }

    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    debugPrint('Grid loading more data...');
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;

      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount)
        ..setLimit(widget.pageSize);

      debugPrint('Grid Loading page $_currentPage, Skip: $skipCount, Limit: ${widget.pageSize}');
      final parseResponse = await nextPageQuery.query();
      debugPrint('Grid LoadMore Response: Success=${parseResponse.success}, Count=${parseResponse.count}, Results=${parseResponse.results?.length}, Error: ${parseResponse.error?.message}');

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
          debugPrint('Saving ${results.length} more items to cache...');
          for (final item in results) {
            try {
              if (widget.lazyLoading) {
                await item.fetch();
              }
              await item.saveToLocalCache();
            } catch (e) {
              debugPrint('Error saving fetched object ${item.objectId} from loadMore to cache: $e');
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
      debugPrint('Error loading more grid data: $e');
      setState(() {
        _loadMoreStatus = LoadMoreStatus.error;
      });
    }
  }

  Future<void> _loadData() async {
    if (isOffline) {
      debugPrint('Offline: Skipping server load, relying on cache.');
      if (isOfflineModeEnabled) {
         await loadDataFromCache();
      }
      return;
    }

    debugPrint('Grid loading initial data from server...');
    try {
      _currentPage = 0;
      _loadMoreStatus = LoadMoreStatus.idle;
      _hasMoreData = true;
      _items.clear();
      _loadingIndices.clear();
      _noDataNotifier.value = true;
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

      final originalLiveGrid = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
      );

      final liveGrid = CachedParseLiveList<T>(originalLiveGrid, widget.cacheSize, widget.lazyLoading);
      _liveGrid?.dispose();
      _liveGrid = liveGrid;

      if (liveGrid.size > 0) {
        for (int i = 0; i < liveGrid.size; i++) {
          final item = liveGrid.getPreLoadedAt(i);
          if (item != null) {
            if (widget.offlineMode) {
              try {
                if (widget.lazyLoading) {
                  await item.fetch();
                }
                await item.saveToLocalCache();
              } catch (e) {
                debugPrint('Error saving initial object ${item.objectId} to cache: $e');
              }
            }
            _items.add(item);
          }
        }
      }

      _noDataNotifier.value = _items.isEmpty;

      if (mounted) {
        setState(() {});
      }

      liveGrid.stream.listen((event) {
        T? objectToCache;

        if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
          final addedItem = event.object as T;
          if (mounted) {
            setState(() {
              _items.insert(event.index, addedItem);
            });
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
            debugPrint('Grid LiveList Delete Event: Invalid index ${event.index}, list size ${_items.length}');
          }
        } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
          final updatedItem = event.object as T;
          if (event.index >= 0 && event.index < _items.length) {
            if (mounted) {
              setState(() {
                _items[event.index] = updatedItem;
              });
            }
            objectToCache = updatedItem;
          } else {
            debugPrint('Grid LiveList Update Event: Invalid index ${event.index}, list size ${_items.length}');
          }
        }

        if (widget.offlineMode && objectToCache != null) {
          objectToCache.saveToLocalCache();
        }

        _noDataNotifier.value = _items.isEmpty;
      });

      if (widget.lazyLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final visibleMaxIndex = _calculateVisibleMaxIndex(0);
          final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2;
          if (preloadIndex < _items.length) {
            _triggerBatchLoading(preloadIndex);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading grid data: $e');
      _noDataNotifier.value = _items.isEmpty;
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshData() async {
    debugPrint('Refreshing Grid data...');
    disposeLiveList();

    if (isOffline) {
      debugPrint('Refreshing offline, loading from cache.');
      await _loadFromCache();
    } else {
      debugPrint('Refreshing online, loading from server.');
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        final bool showLoadingIndicator =
            (!_isOffline && _liveGrid == null) || (_isOffline && _items.isEmpty && !noData);

        if (showLoadingIndicator) {
          return widget.gridLoadingElement ??
              const Center(child: CircularProgressIndicator());
        }

        if (noData && (_liveGrid != null || isOffline)) {
          return widget.queryEmptyElement ??
              const Center(child: Text('No data available'));
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Expanded(
                child: buildAnimatedGrid(),
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
      case LoadMoreStatus.idle:
        return const SizedBox.shrink();
      case LoadMoreStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadMoreStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: TextButton(
              onPressed: _loadMoreData,
              child: const Text('Error loading data. Tap to retry.'),
            ),
          ),
        );
      case LoadMoreStatus.noMoreData:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: Text('No more data available')),
        );
    }
  }

  Widget buildAnimatedGrid() {
    final Animation<double> boxAnimation = widget.animationController != null
        ? Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: widget.animationController!,
              curve: const Interval(0, 0.5, curve: Curves.decelerate),
            ),
          )
        : const AlwaysStoppedAnimation<double>(1.0);

    return GridView.builder(
      reverse: widget.reverse,
      padding: widget.padding,
      physics: widget.scrollPhysics,
      controller: widget.scrollController ?? _scrollController,
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

        if (!isOffline) {
          _triggerBatchLoading(index);
        }

        StreamGetter<T>? itemStream;
        DataGetter<T>? loadedData;
        DataGetter<T>? preLoadedData;

        final liveGrid = _liveGrid;
         if (!isOffline && liveGrid != null && index < liveGrid.size) {
          itemStream = () => liveGrid.getAt(index);
          loadedData = () => liveGrid.getLoadedAt(index);
          preLoadedData = () => liveGrid.getPreLoadedAt(index);
        } else {
          loadedData = () => item;
          preLoadedData = () => item;
        }

       

        return ParseLiveListElementWidget<T>(
          key: ValueKey<String>(item.objectId ?? 'unknown-$index'),
          stream: itemStream,
          loadedData: loadedData,
          preLoadedData: preLoadedData,
          sizeFactor: boxAnimation,
          duration: widget.duration,
          childBuilder: widget.childBuilder ??
              ParseLiveListWidget.defaultChildBuilder,
          index: index,
        );
      },
    );
  }

  void _triggerBatchLoading(int currentIndex) {
    if (isOffline || !widget.lazyLoading || _liveGrid == null) return;

    final batchSize = widget.lazyBatchSize > 0
        ? widget.lazyBatchSize
        : widget.crossAxisCount * 2;

    final startIdx = max(0, currentIndex - widget.crossAxisCount);
    final endIdx = min(_items.length - 1, currentIndex + batchSize);

    for (int i = startIdx; i <= endIdx; i++) {
      if (i >= 0 && i < _liveGrid!.size && !_loadingIndices.contains(i) && _liveGrid!.getLoadedAt(i) == null) {
        _loadingIndices.add(i);
        _liveGrid!.getAt(i).first.then((item) {
          _loadingIndices.remove(i);
          if (item != null && mounted) {
            setState(() {
              if (i < _items.length) {
                _items[i] = item;
              }
            });
          }
        }).catchError((e) {
          _loadingIndices.remove(i);
          debugPrint('Error lazy loading grid item at index $i: $e');
        });
      }
    }
  }

  @override
  void dispose() {
    disposeConnectivityHandler();

    _liveGrid?.dispose();
    _noDataNotifier.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      if (widget.pagination) {
        _scrollController.removeListener(_onScroll);
      }
    }
    super.dispose();
  }
  

}