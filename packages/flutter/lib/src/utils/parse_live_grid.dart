part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// A widget that displays a live grid of Parse objects.
///
/// The `ParseLiveGridWidget` is initialized with a `query` that retrieves the
/// objects to display in the grid. The `gridDelegate` is used to specify the
/// layout of the grid, and the `itemBuilder` function is used to specify how
/// each object in the grid should be displayed.
///
/// The `ParseLiveGridWidget` also provides support for error handling and
/// refreshing the live list of objects.
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
    this.cacheSize = 100,
    this.animationController,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 5.0,
    this.mainAxisSpacing = 5.0,
    this.childAspectRatio = 0.80,
    this.pagination = false,                 // New parameter for enabling pagination
    this.pageSize = 20,                      // New parameter for page size
    this.nonPaginatedLimit = 1000,           // New parameter for max limit when pagination is off
    this.paginationLoadingElement,           // New parameter for loading indicator
    this.footerBuilder,                      // New parameter for custom footer
    this.loadMoreOffset = 200.0,             // New parameter for triggering load more
    this.useAnimations = true,               // New parameter to toggle animations
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

  final ChildBuilder<T>? childBuilder;
  final ChildBuilder<T>? removedItemBuilder;

  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;

  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;
  final int cacheSize;

  final AnimationController? animationController;

  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;

  // New pagination parameters
  final bool pagination;
  final int pageSize;
  final int nonPaginatedLimit;
  final Widget? paginationLoadingElement;
  final Widget Function(BuildContext context, LoadMoreStatus status)? footerBuilder;
  final double loadMoreOffset;

  // New parameter to toggle animations
  final bool useAnimations;

  @override
  State<ParseLiveGridWidget<T>> createState() => _ParseLiveGridWidgetState<T>();

  /// The default child builder function used to display a ParseLiveGrid element.
  /// Now includes an optional index parameter that provides the item's position.
  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the index if available
            if (index != null) 
              Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              snapshot.loadedData!.get<String>(sdk.keyVarObjectId) ?? 'Missing ID',
            ),
          ],
        ),
      );
    } else {
      child = const Card(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return child;
  }
}

class _ParseLiveGridWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveGridWidget<T>> {
  sdk.ParseLiveList<T>? _liveGrid;
  final ScrollController _effectiveController = ScrollController();
  bool noData = true;
  
  // Pagination related fields
  List<T> _items = [];
  int _currentPage = 0;
  bool _hasMoreData = true;
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);

  ScrollController get _scrollController => 
      widget.scrollController ?? _effectiveController;

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener for pagination
    if (widget.pagination) {
      _scrollController.addListener(_onScroll);
    }
    
    _loadData();
  }
  
  void _onScroll() {
    if (!widget.pagination || _loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    // Load more when user scrolls to the threshold
    if (maxScroll - currentScroll <= widget.loadMoreOffset) {
      _loadMoreData();
    }
  }

  /// Load the initial data and set up LiveQuery
  Future<void> _loadData() async {
    try {
      // Reset pagination state if pagination is enabled
      if (widget.pagination) {
        _currentPage = 0;
        _loadMoreStatus = LoadMoreStatus.idle;
        _hasMoreData = true;
      }
      
      _items.clear();

      // Create the appropriate query based on pagination
      final initialQuery = QueryBuilder<T>.copy(widget.query);
      
      if (widget.pagination) {
        // For pagination, use the pageSize
        initialQuery
          ..setAmountToSkip(0)
          ..setLimit(widget.pageSize);
      } else {
        // When pagination is disabled, use a very high limit to get all items
        // or respect the user's original limit if they set one
        if (!initialQuery.limiters.containsKey('limit')) {
          initialQuery.setLimit(widget.nonPaginatedLimit);
        }
      }

      final liveGrid = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.preloadedColumns,
        // excludedColumns and cacheSize will be added when SDK supports them
      );

      _liveGrid = liveGrid;
      
      // Store initial items in our local list
      if (liveGrid.size > 0) {
        for (int i = 0; i < liveGrid.size; i++) {
          final item = liveGrid.getPreLoadedAt(i);
          if (item != null) {
            _items.add(item);
          }
        }
      }

      _noDataNotifier.value = _items.isEmpty;
      noData = _items.isEmpty;

      liveGrid.stream.listen((sdk.ParseLiveListEvent<sdk.ParseObject> event) {
        // Handle LiveQuery events
        if (event is sdk.ParseLiveListAddEvent) {
          setState(() {
            _items.insert(event.index, event.object as T);
            noData = _items.isEmpty;
            _noDataNotifier.value = _items.isEmpty;
          });
        } else if (event is sdk.ParseLiveListDeleteEvent) {
          setState(() {
            _items.removeAt(event.index);
            noData = _items.isEmpty;
            _noDataNotifier.value = _items.isEmpty;
          });
        } else if (event is sdk.ParseLiveListUpdateEvent) {
          setState(() {
            _items[event.index] = event.object as T;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  /// Load more data for pagination
  Future<void> _loadMoreData() async {
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }
    
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });

    try {
      _currentPage++;
      final nextQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(_currentPage * widget.pageSize)
        ..setLimit(widget.pageSize);

      final response = await nextQuery.query<T>();
      
      if (response.success && response.results != null) {
        final newItems = response.results as List<T>;
        
        if (newItems.isEmpty) {
          setState(() {
            _hasMoreData = false;
            _loadMoreStatus = LoadMoreStatus.noMoreData;
          });
          return;
        }
        
        setState(() {
          _items.addAll(newItems);
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

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _liveGrid == null) {
      return widget.gridLoadingElement ?? Container();
    }
    
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, _) {
        if (noData) {
          return widget.queryEmptyElement ?? Container();
        }
        
        // Wrap with RefreshIndicator to enable pull-to-refresh
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Expanded(
                child: buildAnimatedGrid(),
              ),
              
              // Show footer based on load more status if pagination is enabled
              if (widget.pagination) _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  /// Refreshes data by disposing existing LiveGrid and reloading
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    // Update UI to show loading state
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });
    
    try {
      // Save a reference to the current list size
      final int oldItemCount = _items.length;
      
      // Reset state and clear lists
      _items = [];  // Create a new list rather than clearing the existing one
      _currentPage = 0;
      _hasMoreData = true;
      
      // Dispose old LiveGrid
      final oldLiveGrid = _liveGrid;
      _liveGrid = null;
      oldLiveGrid?.dispose();
      
      // Load new data
      await _loadData();
      
      // Force UI update after data is loaded
      if (mounted) {
        setState(() {
          // Make sure UI reflects the new state
          _loadMoreStatus = LoadMoreStatus.idle;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      if (mounted) {
        setState(() {
          _loadMoreStatus = LoadMoreStatus.error;
        });
      }
    }
  }

  Widget buildAnimatedGrid() {
    Animation<double> boxAnimation;
    if (widget.useAnimations && widget.animationController != null) {
      boxAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: widget.animationController!,
          curve: const Interval(
            0,
            0.5,
            curve: Curves.decelerate,
          ),
        ),
      );
    } else {
      // Provide default animation that's always at its end value
      boxAnimation = const AlwaysStoppedAnimation<double>(1.0);
    }
    
    return GridView.builder(
      reverse: widget.reverse,
      padding: widget.padding,
      physics: widget.scrollPhysics,
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      shrinkWrap: widget.shrinkWrap,
      itemCount: _items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio),
      itemBuilder: (BuildContext context, int index) {
        // Get the actual item
        T? item = _items[index];
        if (item == null) {
          return const SizedBox.shrink();
        }
        
        // Get data from LiveList if available, otherwise use direct item
        Stream<T>? itemStream;
        T? loadedData;
        T? preLoadedData;
        
        final liveGrid = _liveGrid;
        if (liveGrid != null && index < liveGrid.size) {
          itemStream = liveGrid.getAt(index);
          loadedData = liveGrid.getLoadedAt(index);
          preLoadedData = liveGrid.getPreLoadedAt(index);
        } else {
          // If liveGrid is null or index is out of bounds, use the item directly
          // itemStream remains null in this case
          loadedData = item;
          preLoadedData = item;
        }
        
        return ParseLiveListElementWidget<T>(
          key: ValueKey<String>(item.objectId ?? 'item-$index'),
          stream: itemStream != null ? () => itemStream! : null, // Keep the stream function wrapper here
          loadedData: loadedData != null ? () => loadedData : null,
          preLoadedData: preLoadedData != null ? () => preLoadedData : null,
          sizeFactor: boxAnimation,
          duration: widget.duration,
          childBuilder: widget.childBuilder ?? ParseLiveGridWidget.defaultChildBuilder,
          index: index,
        );
      },
    );
  }

  Widget _buildFooter() {
    if (widget.footerBuilder != null) {
      return widget.footerBuilder!(context, _loadMoreStatus);
    }
    
    switch (_loadMoreStatus) {
      case LoadMoreStatus.idle:
        return const SizedBox.shrink();
      
      case LoadMoreStatus.loading:
        return widget.paginationLoadingElement ?? 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
      
      case LoadMoreStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: TextButton(
              onPressed: _loadMoreData,
              child: const Text('Error loading items. Tap to retry.'),
            ),
          ),
        );
      
      case LoadMoreStatus.noMoreData:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: Text('No more items')),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _liveGrid?.dispose();
    _liveGrid = null;
    
    // Only dispose the controller if we created it
    if (widget.scrollController == null) {
      _effectiveController.dispose();
    } else {
      // Remove listener if using external controller
      _scrollController.removeListener(_onScroll);
    }
    
    _noDataNotifier.dispose();
    super.dispose();
  }
}
