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
  /// Initial state, no loading is happening
  idle,
  
  /// Loading is in progress
  loading,
  
  /// All data has been loaded
  noMoreData, 
  
  /// An error occurred during loading
  error, 
}

/// Footer builder for pagination
typedef FooterBuilder = Widget Function(BuildContext context, LoadMoreStatus loadMoreStatus);

/// A widget that displays a live list of Parse objects.
///
/// The `ParseLiveListWidget` is initialized with a `query` that retrieves the
/// objects to display in the list. The `childBuilder` function is used to
/// specify how each object in the list should be displayed.
///
/// The `ParseLiveListWidget` also provides support for error handling and
/// lazy loading of objects in the list.
/// 
/// 
/// 
// performance improvement

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
    this.loadMoreOffset = 200.0, // Provide a default value or make it required
    this.cacheSize = 50, // Default cache size
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

  @override
  State<ParseLiveListWidget<T>> createState() => _ParseLiveListWidgetState<T>();

  /// The default child builder function used to display a ParseLiveList element.
  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]) {
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
      return const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
  }
}

class _ParseLiveListWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListWidget<T>> {
  CachedParseLiveList<T>? _liveList;
  final ValueNotifier<bool> _noDataNotifier = ValueNotifier<bool>(true);
  final List<T> _items = <T>[]; // Local list to manage all items

  // Initialize these only when pagination is enabled
  late final ScrollController _scrollController;
  LoadMoreStatus _loadMoreStatus = LoadMoreStatus.idle;
  int _currentPage = 0;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize scroll controller only if needed
    if (widget.scrollController == null) {
      _scrollController = ScrollController();
    }

    // Add listener only if pagination is enabled
    if (widget.pagination) {
      final scrollController = widget.scrollController ?? _scrollController;
      scrollController.addListener(_onScroll);
    }

    _loadData();
  }

   Future<void> _loadMoreData() async {
      if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
        return;
      }
   }

  // This method is called only when pagination is enabled
  void _onScroll() {
    if (_loadMoreStatus == LoadMoreStatus.loading || !_hasMoreData) {
      return;
    }

    final scrollController = widget.scrollController ?? _scrollController;
    final offset = scrollController.position.maxScrollExtent - scrollController.position.pixels;

    if (offset < widget.loadMoreOffset) {
      _loadMoreData();
    }
  }
  

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
          initialQuery.setLimit(widget.nonPaginatedLimit); // Use a high value to get "all" items
        }
      }

      // Create the ParseLiveList without cacheSize
      final originalLiveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.lazyLoading ? (widget.preloadedColumns ?? []) : null,
        // excludedColumns: widget.excludedColumns,
      );

      // Wrap it with our caching layer
      final liveList = CachedParseLiveList<T>(originalLiveList, widget.cacheSize, widget.lazyLoading);
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
        // Update local list based on live query events
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
                  itemCount: _items.length, // Use local list's length
                  itemBuilder: (context, index) {
                    final item = _items[index]; // Get item from local list
                    
                    // Get data from LiveList if available, otherwise use direct item
                    StreamGetter<T>? itemStream;
                    DataGetter<T>? loadedData;
                    DataGetter<T>? preLoadedData;

                    final liveList = _liveList;
                    if (liveList != null && index < liveList.size) {
                      // This part is critical for lazy loading to work
                      itemStream = () => liveList.getAt(index);
                      loadedData = () => liveList.getLoadedAt(index);
                      preLoadedData = () => liveList.getPreLoadedAt(index);
                    } else {
                      loadedData = () => item;
                      preLoadedData = () => item;
                    }

                    return ParseLiveListElementWidget<T>(
                      key: ValueKey<String>(item.objectId ?? 'unknown-${index}'),
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
              ),
              // Only show footer if pagination is enabled
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
    // Only dispose of scroll controller if we created it
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } 
    // Only remove listener if pagination was enabled
    else if (widget.pagination) {
      widget.scrollController!.removeListener(_onScroll);
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
    this.index, // Make index optional
  });

  final StreamGetter<T>? stream;
  final DataGetter<T>? loadedData;
  final DataGetter<T>? preLoadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder<T> childBuilder;
  final int? index; // Change to nullable

  @override
  State<ParseLiveListElementWidget<T>> createState() =>
      _ParseLiveListElementWidgetState<T>();
}

class _ParseLiveListElementWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListElementWidget<T>> {
  late sdk.ParseLiveListElementSnapshot<T> _snapshot;
  StreamSubscription<T>? _streamSubscription;

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