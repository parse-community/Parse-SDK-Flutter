part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// A widget that displays a live list of Parse objects in a swipeable page view.
///
/// The `ParseLiveListPageView` is initialized with a `query` that retrieves the
/// objects to display in the page view. The `childBuilder` function is used to
/// specify how each object/page should be displayed.
///
/// This widget supports pagination, lazy loading, and real-time updates through LiveQuery.
class ParseLiveListPageView<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveListPageView({
    super.key,
    required this.query,
    this.pageLoadingElement,
    this.queryEmptyElement,
    this.duration = const Duration(milliseconds: 300),
    this.scrollPhysics,
    this.pageController,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.childBuilder,
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
    this.onPageChanged, // Add this parameter
  });

  final sdk.QueryBuilder<T> query;
  final Widget? pageLoadingElement;
  final Widget? queryEmptyElement;
  final Duration duration;
  final ScrollPhysics? scrollPhysics;
  final PageController? pageController;
  final Axis scrollDirection;
  final bool reverse;
  final ChildBuilder<T>? childBuilder;
  final bool? listenOnAllSubItems;
  final List<String>? listeningIncludes;
  final bool lazyLoading;
  final List<String>? preloadedColumns;
  final List<String>? excludedColumns;
  final bool pagination;
  final int pageSize;
  final int paginationThreshold;
  final Widget? loadingIndicator;
  final int cacheSize;
  final void Function(int)? onPageChanged; // Add this field

  @override
  State<ParseLiveListPageView<T>> createState() => _ParseLiveListPageViewState<T>();

  /// The default child builder function used to display a PageView page.
  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]) {
    Widget child;
    if (snapshot.failed) {
      child = const Center(child: Text('Something went wrong!'));
    } else if (snapshot.hasData) {
      child = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display page number if available
            if (index != null)
              Text('Page ${index + 1}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(
              'Object ID: ${snapshot.loadedData?.get<String>(sdk.keyVarObjectId) ?? 'Missing Data!'}',
            ),
            const SizedBox(height: 10),
            Text(
              'Created: ${snapshot.loadedData?.get<DateTime>(sdk.keyVarCreatedAt)?.toString() ?? 'Unknown date'}',
            ),
            const SizedBox(height: 40),
            const Text('Swipe to see more items', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      );
    } else {
      child = const Center(
        child: CircularProgressIndicator(),
      );
    }
    return child;
  }
}

class _ParseLiveListPageViewState<T extends sdk.ParseObject>
    extends State<ParseLiveListPageView<T>> {
  late PageController _pageController;
  CachedParseLiveList<T>? _liveList;
  List<T> _items = [];
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoading = false;

  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);

  // Status of load more operation
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;

  @override
  void initState() {
    super.initState();
    _pageController = widget.pageController ?? PageController();
    _loadData();

    // Add listener to handle pagination
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    // Only handle pagination if pagination is enabled and not already loading
    if (!widget.pagination || _isLoading || !_hasMoreData || 
        _loadMoreStatus == LoadMoreStatus.loading) {
      return;
    }

    // Calculate if we should load more based on current page
    if (_items.isNotEmpty && _pageController.hasClients) {
      final int currentPage = _pageController.page?.round() ?? 0;

      // If we're within threshold of the end, load more
      if (currentPage >= _items.length - widget.paginationThreshold) {
        _loadMoreData();
      }
    }
  }

  /// Loads the data for the live list with caching.
  Future<void> _loadData() async {
    try {
      _currentPage = 0;
      _hasMoreData = true;
      _items.clear();

      final initialQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(0)
        ..setLimit(widget.pageSize);

      final originalLiveList = await sdk.ParseLiveList.create<T>(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.preloadedColumns,
        // excludedColumns: widget.excludedColumns,
      );

      // Wrap with our caching layer
      final liveList = CachedParseLiveList<T>(originalLiveList, widget.cacheSize);
      _liveList = liveList;

      // Get initial items
      if (liveList.size > 0) {
        for (int i = 0; i < liveList.size; i++) {
          final item = liveList.getPreLoadedAt(i);
          if (item != null) {
            _items.add(item);
          }
        }
      }

      _noDataNotifier.value = _items.isEmpty;

      // Listen for real-time updates
      liveList.stream.listen((event) {
        if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
          setState(() {
            _items.insert(event.index, event.object as T);
            // Cache the new item
            liveList.updateCache(event.index, event.object as T);
          });
        } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
          setState(() {
            _items.removeAt(event.index);
            // Remove from cache
            liveList.removeFromCache(event.index);
            
            // If current page would be out of bounds after deletion, adjust
            if (_pageController.hasClients && 
                _pageController.page!.round() >= _items.length) {
              _pageController.jumpToPage(_items.length - 1);
            }
          });
        } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
          setState(() {
            _items[event.index] = event.object as T;
            // Update the cache
            liveList.updateCache(event.index, event.object as T);
          });
        }

        _noDataNotifier.value = _items.isEmpty;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  /// Refreshes the data by disposing the existing live list and loading fresh data
  Future<void> _refreshData() async {
    final liveList = _liveList;
    if (liveList != null) {
      // Clear cache before disposing
      liveList.clearCache();
      liveList.dispose();
      _liveList = null;
    }
    
    await _loadData();
  }

  /// Loads more data when scrolling near the end with pagination enabled
  Future<void> _loadMoreData() async {
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) return;

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
        final List<T> newItems = response.results as List<T>;

        if (newItems.isEmpty) {
          setState(() {
            _hasMoreData = false;
            _loadMoreStatus = LoadMoreStatus.done;
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
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, _) {
        if (_items.isEmpty && _liveList == null) {
          return widget.pageLoadingElement ?? const Center(child: CircularProgressIndicator());
        }

        if (noData && _items.isEmpty) {
          return widget.queryEmptyElement ?? const Center(child: Text('No items found'));
        }

        return RefreshIndicator(
          onRefresh: _refreshData, // Add pull-to-refresh capability
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: widget.scrollDirection,
                reverse: widget.reverse,
                physics: widget.scrollPhysics,
                itemCount: _items.length,
                onPageChanged: (int page) {
                  // Handle internal page tracking
                  if (widget.pagination && 
                      page >= _items.length - widget.paginationThreshold) {
                    _loadMoreData();
                  }

                  // Forward the callback to the user's implementation
                  widget.onPageChanged?.call(page);
                },
                itemBuilder: (context, index) {
                  // Use the more efficient direct approach for items
                  final item = _items[index];
                  
                  return ParseLiveListElementWidget<T>(
                    key: ValueKey<String>('page_${item.objectId ?? index.toString()}'),
                    // Use a direct stream from the item for better performance
                    stream: () => Stream.value(item),
                    loadedData: () => item,
                    preLoadedData: () => item,
                    sizeFactor: const AlwaysStoppedAnimation<double>(1.0),
                    duration: widget.duration,
                    childBuilder: widget.childBuilder ?? ParseLiveListPageView.defaultChildBuilder,
                    index: index, // Pass the index to the element widget
                  );
                },
              ),

              // Show loading indicator at the bottom when loading more items
              if (_loadMoreStatus == LoadMoreStatus.loading)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: widget.loadingIndicator ?? 
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(16)
                          ),
                          child: const SizedBox(
                            width: 24, 
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2)
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
    // Only dispose the controller if we created it
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    _liveList?.dispose();
    _liveList = null;
    _noDataNotifier.dispose();
    super.dispose();
  }
}