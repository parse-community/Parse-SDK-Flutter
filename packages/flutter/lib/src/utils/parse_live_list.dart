part of 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

/// The type of function that builds a child widget for a ParseLiveList element.
/// Now includes an optional index parameter that provides the item's position.
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

  /// No data available
  done,
  
  /// An error occurred during loading
  error, 
}

/// A widget that displays a live list of Parse objects.
///
/// The `ParseLiveListWidget` is initialized with a `query` that retrieves the
/// objects to display in the list. The `childBuilder` function is used to
/// specify how each object in the list should be displayed.
///
/// The `ParseLiveListWidget` also provides support for error handling and
/// lazy loading of objects in the list.
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
    this.cacheSize = 100,
    this.pagination = false,                  // Pagination parameters
    this.pageSize = 20,                       
    this.nonPaginatedLimit = 1000,            
    this.paginationLoadingElement,            
    this.footerBuilder,                       
    this.loadMoreOffset = 200.0,              
    this.useAnimatedList = true,              // New parameter to choose list type
  });

  // Add the new parameter
  final bool useAnimatedList;
  
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
  final int cacheSize;
  
  // Pagination parameters
  final bool pagination;
  final int pageSize;
  final int nonPaginatedLimit;
  final Widget? paginationLoadingElement;
  final Widget Function(BuildContext context, LoadMoreStatus status)? footerBuilder;
  final double loadMoreOffset;

  @override
  State<ParseLiveListWidget<T>> createState() => _ParseLiveListWidgetState<T>();

  /// The default child builder function used to display a ParseLiveList element.
  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot, [int? index]) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData?.get<String>(sdk.keyVarObjectId) ??
              'Missing Data!',
        ),
        // If index is available, show it as the leading widget
        leading: index != null ? Text('#${index + 1}') : null,
      );
    } else {
      child = const ListTile(
        leading: CircularProgressIndicator(),
      );
    }
    return child;
  }
}

class _ParseLiveListWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListWidget<T>> {
  sdk.ParseLiveList<T>? _liveList;
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  final ScrollController _effectiveController = ScrollController();
  bool _noData = true;
  
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

  /// Loads the data for the live list.
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

      final liveList = await sdk.ParseLiveList.create(
        initialQuery,
        listenOnAllSubItems: widget.listenOnAllSubItems,
        listeningIncludes: widget.listeningIncludes,
        lazyLoading: widget.lazyLoading,
        preloadedColumns: widget.preloadedColumns,
        // excludedColumns and cacheSize will be added when SDK supports them
      );

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
      _noData = _items.isEmpty;

      liveList.stream.listen((sdk.ParseLiveListEvent<sdk.ParseObject> event) {
        final AnimatedListState? animatedListState = _animatedListKey.currentState;
        
        // Handle LiveQuery events
        if (event is sdk.ParseLiveListAddEvent) {
          setState(() {
            _items.insert(event.index, event.object as T);
            
            if (animatedListState != null) {
              animatedListState.insertItem(event.index, duration: widget.duration);
            }
            
            _noData = _items.isEmpty;
            _noDataNotifier.value = _items.isEmpty;
          });
        } else if (event is sdk.ParseLiveListDeleteEvent) {
          setState(() {
            _items.removeAt(event.index);
            
            if (animatedListState != null) {
              animatedListState.removeItem(
                event.index,
                (BuildContext context, Animation<double> animation) =>
                    ParseLiveListElementWidget<T>(
                      key: ValueKey<String>(
                          event.object.get<String>(sdk.keyVarObjectId) ??
                              'removingItem'),
                      childBuilder: widget.childBuilder ??
                          ParseLiveListWidget.defaultChildBuilder,
                      sizeFactor: animation,
                      duration: widget.duration,
                      loadedData: () => event.object as T,
                      preLoadedData: () => event.object as T,
                      index: event.index,
                    ),
                duration: widget.duration,
              );
            }
            
            _noData = _items.isEmpty;
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
        
        final int startIndex = _items.length;
        
        setState(() {
          // Add new items to our list
          _items.addAll(newItems);
          _loadMoreStatus = LoadMoreStatus.idle;
          
          // If using AnimatedList, animate in the new items
          if (widget.useAnimatedList) {
            final AnimatedListState? animatedListState = _animatedListKey.currentState;
            if (animatedListState != null) {
              for (int i = 0; i < newItems.length; i++) {
                animatedListState.insertItem(startIndex + i, duration: widget.duration);
              }
            }
          }
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
    if (_items.isEmpty && _liveList == null) {
      return widget.listLoadingElement ?? Container();
    }
    
    return ValueListenableBuilder<bool>(
      valueListenable: _noDataNotifier,
      builder: (context, noData, _) {
        if (noData) {
          return widget.queryEmptyElement ?? Container();
        }
        
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: Stack(
            children: <Widget>[
              buildAnimatedList(),
              if (_loadMoreStatus == LoadMoreStatus.loading && _items.isEmpty) 
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
    );
  }

  /// Refreshes data by disposing existing LiveList and reloading
  Future<void> _refreshData() async {
    setState(() {
      _loadMoreStatus = LoadMoreStatus.loading;
    });
    
    try {
      // Dispose of the old live list
      _liveList?.dispose();
      _liveList = null;
      
      // If using AnimatedList, handle removing items with animation
      if (widget.useAnimatedList) {
        final AnimatedListState? animatedListState = _animatedListKey.currentState;
        
        if (animatedListState != null) {
          final int itemCount = _items.length;
          for (int i = itemCount - 1; i >= 0; i--) {
            animatedListState.removeItem(
              i,
              (context, animation) => SizedBox.shrink(),
              duration: Duration.zero,
            );
          }
        }
      }
      
      // Reset state
      _items = []; // Create a new list rather than clearing
      _currentPage = 0;
      _hasMoreData = true;
      
      // Load data with a slight delay to ensure proper animation if needed
      if (widget.useAnimatedList) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      
      await _loadData();
      
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      setState(() {
        _loadMoreStatus = LoadMoreStatus.error;
      });
    }
  }

  Widget buildAnimatedList() {
    return Column(
      children: [
        Expanded(
          child: widget.useAnimatedList
              ? _buildAnimatedList()
              : _buildListView(),
        ),
        
        // Show footer based on load more status if pagination is enabled
        if (widget.pagination) _buildFooter(),
      ],
    );
  }

  // Build using AnimatedList for animated insertions/removals
  Widget _buildAnimatedList() {
    return AnimatedList(
      key: _animatedListKey,
      physics: widget.scrollPhysics,
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      primary: widget.primary,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      initialItemCount: _items.length,
      itemBuilder: (BuildContext context, int index, Animation<double> animation) {
        // Get the actual item
        if (index >= _items.length) {
          return SizedBox.shrink();
        }
        
        final item = _items[index];
        
        // Get data from LiveList if available, otherwise use direct item
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
          key: ValueKey<String>(item.objectId ?? 'item-$index'),
          stream: itemStream,
          loadedData: loadedData,
          preLoadedData: preLoadedData,
          sizeFactor: animation,
          duration: widget.duration,
          childBuilder: widget.childBuilder ?? ParseLiveListWidget.defaultChildBuilder,
          index: index,
        );
      },
    );
  }

  // Build using ListView.builder for simpler list rendering
  Widget _buildListView() {
    return ListView.builder(
      physics: widget.scrollPhysics,
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      padding: widget.padding,
      primary: widget.primary,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      itemCount: _items.length,
      itemBuilder: (BuildContext context, int index) {
        // Get the actual item
        final item = _items[index];
        
        // Get data from LiveList if available, otherwise use direct item
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
          key: ValueKey<String>(item.objectId ?? 'item-$index'),
          stream: itemStream,
          loadedData: loadedData,
          preLoadedData: preLoadedData,
          sizeFactor: const AlwaysStoppedAnimation<double>(1.0), // No animation
          duration: widget.duration,
          childBuilder: widget.childBuilder ?? ParseLiveListWidget.defaultChildBuilder,
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
        return SizedBox.shrink();
      
      case LoadMoreStatus.loading:
        return widget.paginationLoadingElement ?? 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
      
      case LoadMoreStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: TextButton(
              onPressed: _loadMoreData,
              child: Text('Error loading items. Tap to retry.'),
            ),
          ),
        );
      
      case LoadMoreStatus.noMoreData:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(child: Text('No more items')),
        );
      
      default:
        return SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _liveList?.dispose();
    _liveList = null;
    
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
      this.index, // Add the optional index parameter
  });

  final StreamGetter<T>? stream;
  final DataGetter<T>? loadedData;
  final DataGetter<T>? preLoadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder<T> childBuilder;
  final int? index; // Store the index

  @override
  State<ParseLiveListElementWidget<T>> createState() {
    return _ParseLiveListElementWidgetState<T>();
  }
}

class _ParseLiveListElementWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListElementWidget<T>> {
  late sdk.ParseLiveListElementSnapshot<T> _snapshot;
  StreamSubscription<T>? _streamSubscription;

  @override
  void initState() {
    _snapshot = sdk.ParseLiveListElementSnapshot<T>(
        loadedData: widget.loadedData != null ? widget.loadedData!() : null,
        preLoadedData:
            widget.preLoadedData != null ? widget.preLoadedData!() : null);
    if (widget.stream != null) {
      _streamSubscription = widget.stream!().listen(
        (T data) {
          setState(() {
            _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                loadedData: data, preLoadedData: data);
          });
        },
        onError: (Object error) {
          if (error is sdk.ParseError) {
            setState(() {
              _snapshot = sdk.ParseLiveListElementSnapshot<T>(error: error);
            });
          }
        },
        cancelOnError: false,
      );
    }

    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
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