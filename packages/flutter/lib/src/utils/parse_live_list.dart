part of '../../parse_server_sdk_flutter.dart';

/// The type of function that builds a child widget for a ParseLiveList element.
typedef ChildBuilder<T extends sdk.ParseObject> = Widget Function(
    BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot);

/// The type of function that returns the stream to listen for updates from.
typedef StreamGetter<T extends sdk.ParseObject> = Stream<T> Function();

/// The type of function that returns the loaded data for a ParseLiveList element.
typedef DataGetter<T extends sdk.ParseObject> = T? Function();

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

  @override
  State<ParseLiveListWidget<T>> createState() => _ParseLiveListWidgetState<T>();

  /// The default child builder function used to display a ParseLiveList element.
  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData?.get<String>(sdk.keyVarObjectId) ??
              'Missing Data!',
        ),
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
  @override
  void initState() {
    sdk.ParseLiveList.create(
      widget.query,
      listenOnAllSubItems: widget.listenOnAllSubItems,
      listeningIncludes: widget.listeningIncludes,
      lazyLoading: widget.lazyLoading,
      preloadedColumns: widget.preloadedColumns,
    ).then((sdk.ParseLiveList<T> liveList) {
      setState(() {
        _noData = liveList.size == 0;
        _liveList = liveList;
        liveList.stream.listen((sdk.ParseLiveListEvent<sdk.ParseObject> event) {
          final AnimatedListState? animatedListState =
              _animatedListKey.currentState;
          if (animatedListState != null) {
            if (event is sdk.ParseLiveListAddEvent) {
              animatedListState.insertItem(event.index,
                  duration: widget.duration);

              setState(() {
                _noData = liveList.size == 0;
              });
            } else if (event is sdk.ParseLiveListDeleteEvent) {
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
                      ),
                  duration: widget.duration);
              setState(() {
                _noData = liveList.size == 0;
              });
            }
          }
        });
      });
    });

    super.initState();
  }

  sdk.ParseLiveList<T>? _liveList;
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  bool _noData = true;

  @override
  Widget build(BuildContext context) {
    final sdk.ParseLiveList<T>? liveList = _liveList;
    if (liveList == null) {
      return widget.listLoadingElement ?? Container();
    } else {
      return Stack(
        children: <Widget>[
          if (widget.queryEmptyElement != null)
            AnimatedOpacity(
              opacity: _noData ? 1 : 0,
              duration: widget.duration,
              child: widget.queryEmptyElement,
            ),
          buildAnimatedList(liveList),
        ],
      );
    }
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget buildAnimatedList(sdk.ParseLiveList<T> liveList) {
    return AnimatedList(
        key: _animatedListKey,
        physics: widget.scrollPhysics,
        controller: widget.scrollController,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        primary: widget.primary,
        reverse: widget.reverse,
        shrinkWrap: widget.shrinkWrap,
        initialItemCount: liveList.size,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return ParseLiveListElementWidget<T>(
            key: ValueKey<String>(liveList.getIdentifier(index)),
            stream: () => liveList.getAt(index),
            loadedData: () => liveList.getLoadedAt(index),
            preLoadedData: () => liveList.getPreLoadedAt(index),
            sizeFactor: animation,
            duration: widget.duration,
            childBuilder:
                widget.childBuilder ?? ParseLiveListWidget.defaultChildBuilder,
          );
        });
  }

  @override
  void dispose() {
    _liveList?.dispose();
    _liveList = null;
    super.dispose();
  }
}

class ParseLiveListElementWidget<T extends sdk.ParseObject>
    extends StatefulWidget {
  const ParseLiveListElementWidget(
      {super.key,
      this.stream,
      this.loadedData,
      this.preLoadedData,
      required this.sizeFactor,
      required this.duration,
      required this.childBuilder});

  final StreamGetter<T>? stream;
  final DataGetter<T>? loadedData;
  final DataGetter<T>? preLoadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder<T> childBuilder;

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
    final Widget result = SizeTransition(
      sizeFactor: widget.sizeFactor,
      child: AnimatedSize(
        duration: widget.duration,
        child: widget.childBuilder(context, _snapshot),
      ),
    );
    return result;
  }
}
