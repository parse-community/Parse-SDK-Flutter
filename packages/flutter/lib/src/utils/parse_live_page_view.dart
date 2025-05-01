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
    this.cacheSize = 50,          // Add cacheSize parameter (smaller for page views)
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

  // Add the new property  
  final int cacheSize;

  @override
  State<ParseLiveListPageView<T>> createState() =>
      _ParseLiveListPageViewState<T>();
}

class _ParseLiveListPageViewState<T extends sdk.ParseObject>
    extends State<ParseLiveListPageView<T>> {
  // Change from sdk.ParseLiveList<T>? to CachedParseLiveList<T>?
  CachedParseLiveList<T>? _liveList;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[]; // Local list to manage all items

  // Pagination state
  bool _isLoadingMore = false;
  int _currentPage = 0;
  bool _hasMoreData = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = widget.pageController ?? PageController();

    _loadData();

    // Add listener to detect when to load more pages
    if (widget.pagination) {
      _pageController.addListener(_checkForMoreData);
    }
  }

  void _checkForMoreData() {
    if (!widget.pagination || _isLoadingMore || !_hasMoreData) return;

    // If we're within the threshold of the end, load more data
    if (_pageController.page != null &&
        _items.isNotEmpty &&
        _pageController.page! >= _items.length - widget.paginationThreshold) {
      _loadMoreData();
    }
  }

  /// Loads the data for the live list.
  Future<void> _loadData() async {
    try {
      _currentPage = 0;
      _hasMoreData = true;
      _items.clear();

      final initialQuery = QueryBuilder<T>.copy(widget.query)
        ..setAmountToSkip(0)
        ..setLimit(widget.pageSize);

      // Create the ParseLiveList without cacheSize parameter
       final originalLiveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        // listeningIncludes: widget.listeningIncludes,
        listeningIncludes: widget.lazyLoading ? (widget.listeningIncludes ?? []) : widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : widget.preloadedColumns,
        // preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : null,
        // excludedColumns: widget.excludedColumns,
      );
      // final originalLiveList = await sdk.ParseLiveList.create<T>(
      //   initialQuery,
      //   listenOnAllSubItems: widget.listenOnAllSubItems,
      //   listeningIncludes: widget.listeningIncludes,
      //   lazyLoading: widget.lazyLoading,
      //   preloadedColumns: widget.preloadedColumns,
      //   // excludedColumns: widget.excludedColumns,
      //   // Remove cacheSize parameter
      // );

      // Wrap it with our caching layer
      final liveList =CachedParseLiveList<T>(originalLiveList, widget.cacheSize, widget.lazyLoading);   //CachedParseLiveList<T>(originalLiveList, widget.cacheSize);
      _liveList = liveList;

      // Store initial items in our local list
      if (liveList.size > 0) {
        for (int i = 0; i < liveList.size; i++) {
          final item = liveList.getPreLoadedAt(i);
          if (item != null) {
            _items.add(item);
          }
        }
      }

      _noDataNotifier.value = _items.isEmpty;

      liveList.stream.listen((event) {
        // Handle live query events
        if (event is sdk.ParseLiveListAddEvent<sdk.ParseObject>) {
          setState(() {
            _items.insert(event.index, event.object as T);
          });
        } else if (event is sdk.ParseLiveListDeleteEvent<sdk.ParseObject>) {
          setState(() {
            _items.removeAt(event.index);
          });
        } else if (event is sdk.ParseLiveListUpdateEvent<sdk.ParseObject>) {
          setState(() {
            _items[event.index] = event.object as T;
          });
        }

        _noDataNotifier.value = _items.isEmpty;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  /// Loads more data when approaching the end of available pages
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

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
            _hasMoreData = false;
          });
        } else {
          setState(() {
            _items.addAll(results);
          });
        }
      } else {
        // Handle error
        debugPrint('Error loading more data: ${parseResponse.error?.message}');
      }
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Refreshes the data for the live list.
  Future<void> _refreshData() async {
    _liveList?.dispose();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, child) {
        if (_liveList == null) {
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
                itemCount: _items.length + (_hasMoreData ? 1 : 0),
                onPageChanged: (index) {
                  // Check if we need to load more data
                  if (widget.pagination &&
                      _hasMoreData &&
                      index >= _items.length - widget.paginationThreshold) {
                    _loadMoreData();
                  }

                  // Call the original onPageChanged callback
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index);
                  }
                },
                itemBuilder: (context, index) {
                  // Show loading indicator for the last item if more data is available
                  if (index >= _items.length) {
                    return widget.loadingIndicator ??
                        const Center(child: CircularProgressIndicator());
                  }

                  final item = _items[index];
                  return ParseLiveListElementWidget<T>(
                    key: ValueKey<String>(item.objectId ?? 'unknown-$index'),
                    stream: () => Stream.value(item),
                    loadedData: () => item,
                    preLoadedData: () => item,
                    sizeFactor: const AlwaysStoppedAnimation<double>(1.0),
                    duration: widget.duration,
                    childBuilder: widget.childBuilder ??
                        ParseLiveListWidget.defaultChildBuilder,
                    index: index,
                  );
                },
              ),
              // Show loading indicator when loading more pages
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
    _liveList?.dispose();
    _noDataNotifier.dispose();
    if (widget.pageController == null) {
      _pageController.dispose();
    }
    super.dispose();
  }
}