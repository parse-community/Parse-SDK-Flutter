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
    this.loadMoreOffset = 300.0,
    this.footerBuilder,
    this.cacheSize = 50,
    this.lazyBatchSize = 0,  // 0 means auto-calculate based on crossAxisCount
    this.lazyTriggerOffset = 500.0,  // Distance from visible area to preload
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
  // Add the new property
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
  final double loadMoreOffset;
  final FooterBuilder? footerBuilder;

  final int lazyBatchSize;
  final double lazyTriggerOffset;

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
    extends State<ParseLiveGridWidget<T>> {
  CachedParseLiveList<T>? _liveGrid;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[];

  final ScrollController _scrollController = ScrollController();
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  // Add this to your state class
  final Set<int> _loadingIndices = {};

  @override
  void initState() {
    super.initState();
    final scrollController = widget.scrollController ?? _scrollController;

    if (widget.pagination) {
      scrollController.addListener(_onScroll);
    }

    _loadData();
  }

  void _onScroll() {
    if (!widget.pagination || _loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    final scrollController = widget.scrollController ?? _scrollController;
    final offset = scrollController.position.maxScrollExtent - scrollController.position.pixels;

    if (offset < widget.loadMoreOffset) {
      _loadMoreData();
    }

    // Also add batch loading for upcoming items during scroll
    if (widget.lazyLoading) {
      final visibleMaxIndex = _calculateVisibleMaxIndex(scrollController.offset);
      final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2;

      if (preloadIndex < _items.length) {
        _triggerBatchLoading(preloadIndex);
      }
    }
  }

  int _calculateVisibleMaxIndex(double offset) {
    // Estimate which items are currently visible based on scroll position
    final itemHeight = widget.childAspectRatio * (MediaQuery.of(context).size.width / widget.crossAxisCount);
    return min((offset + MediaQuery.of(context).size.height) ~/ itemHeight * widget.crossAxisCount, _items.length - 1);
  }

  Future<void> _loadMoreData() async {
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });

    try {
      _currentPage++;
      final skipCount = _currentPage * widget.pageSize;

      final nextPageQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(skipCount);

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
      debugPrint('Error loading more data: $e');
      setState(() {
        _loadMoreStatus = LoadMoreStatus.error;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      _currentPage = 0;
      _loadMoreStatus = LoadMoreStatus.idle;
      _hasMoreData = true;
      _items.clear();

      final initialQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(0)
        ..setLimit(widget.pageSize);

      // Create the ParseLiveList without cacheSize parameter
      final originalLiveGrid = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
      );

      // Wrap it with our caching layer
      final liveGrid = CachedParseLiveList<T>(originalLiveGrid, widget.cacheSize, widget.lazyLoading);
      _liveGrid = liveGrid;

      if (liveGrid.size > 0) {
        for (int i = 0; i < liveGrid.size; i++) {
          final item = liveGrid.getPreLoadedAt(i);
          if (item != null) {
            _items.add(item);
          }
        }
      }

      _noDataNotifier.value = _items.isEmpty;

      liveGrid.stream.listen((event) {
        if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
          setState(() {
            _items.insert(event.index, event.object as T);
          });
        } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
          setState(() {
            _items.removeAt(event.index);
          });
        }

        _noDataNotifier.value = _items.isEmpty;
      });

      if (widget.lazyLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final visibleMaxIndex = _calculateVisibleMaxIndex(0);
          final preloadIndex = visibleMaxIndex + widget.crossAxisCount * 2;
          if (preloadIndex < _items.length) {
            _triggerBatchLoading(preloadIndex);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _refreshData() async {
    _liveGrid?.dispose();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        if (_liveGrid == null) {
          return widget.gridLoadingElement ??
              const Center(child: CircularProgressIndicator());
        }

        if (noData) {
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
        
        // Trigger batch loading for visible grid items
        _triggerBatchLoading(index);

        // Get data from LiveList if available, otherwise use direct item
        StreamGetter<T>? itemStream;
        DataGetter<T>? loadedData;
        DataGetter<T>? preLoadedData;

        final liveGrid = _liveGrid;
        if (liveGrid != null && index < liveGrid.size) {
          itemStream = () => liveGrid.getAt(index);
          loadedData = () => liveGrid.getLoadedAt(index);
          preLoadedData = () => liveGrid.getPreLoadedAt(index);
        } else {
          loadedData = () => item;
          preLoadedData = () => item;
        }

        return ParseLiveListElementWidget<T>(
          key: ValueKey<String>(item.objectId ?? 'unknown-${index}'),
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
    if (!widget.lazyLoading || _liveGrid == null) return;

    final batchSize = widget.lazyBatchSize > 0
        ? widget.lazyBatchSize
        : widget.crossAxisCount * 2;

    final startIdx = max(0, currentIndex - widget.crossAxisCount);
    final endIdx = min(_items.length - 1, currentIndex + batchSize);

    for (int i = startIdx; i <= endIdx; i++) {
      if (i < _liveGrid!.size && !_loadingIndices.contains(i)) {
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
          debugPrint('Error lazy loading item at index $i: $e');
        });
      }
    }
  }

  @override
  void dispose() {
    _liveGrid?.dispose();
    _noDataNotifier.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
}