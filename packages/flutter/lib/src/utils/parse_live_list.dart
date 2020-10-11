part of flutter_parse_sdk_flutter;

typedef ChildBuilder<T extends sdk.ParseObject> = Widget Function(
    BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot);

class ParseLiveListWidget<T extends sdk.ParseObject> extends StatefulWidget {
  const ParseLiveListWidget({
    Key key,
    @required this.query,
    this.listLoadingElement,
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
  }) : super(key: key);

  final sdk.QueryBuilder<T> query;
  final Widget listLoadingElement;
  final Duration duration;
  final ScrollPhysics scrollPhysics;
  final ScrollController scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final bool primary;
  final bool reverse;
  final bool shrinkWrap;

  final ChildBuilder<T> childBuilder;
  final ChildBuilder<T> removedItemBuilder;

  final bool listenOnAllSubItems;
  final List<String> listeningIncludes;

  final bool lazyLoading;
  final List<String> preloadedColumns;

  @override
  _ParseLiveListWidgetState<T> createState() => _ParseLiveListWidgetState<T>(
        query: query,
        removedItemBuilder: removedItemBuilder,
        listenOnAllSubItems: listenOnAllSubItems,
        listeningIncludes: listeningIncludes,
        lazyLoading: lazyLoading,
        preloadedColumns: preloadedColumns,
      );

  static Widget defaultChildBuilder<T extends sdk.ParseObject>(
      BuildContext context, sdk.ParseLiveListElementSnapshot<T> snapshot) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData.get(sdk.keyVarObjectId),
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
  _ParseLiveListWidgetState(
      {@required this.query,
      @required this.removedItemBuilder,
      bool listenOnAllSubItems,
      List<String> listeningIncludes,
      bool lazyLoading = true,
      List<String> preloadedColumns}) {
    sdk.ParseLiveList.create(
      query,
      listenOnAllSubItems: listenOnAllSubItems,
      listeningIncludes: listeningIncludes,
      lazyLoading: lazyLoading,
      preloadedColumns: preloadedColumns,
    ).then((sdk.ParseLiveList<T> value) {
      setState(() {
        _liveList = value;
        _liveList.stream
            .listen((sdk.ParseLiveListEvent<sdk.ParseObject> event) {
          if (event is sdk.ParseLiveListAddEvent) {
            if (_animatedListKey.currentState != null)
              _animatedListKey.currentState
                  .insertItem(event.index, duration: widget.duration);
          } else if (event is sdk.ParseLiveListDeleteEvent) {
            _animatedListKey.currentState.removeItem(
                event.index,
                (BuildContext context, Animation<double> animation) =>
                    ParseLiveListElementWidget<T>(
                      key: ValueKey<String>(event.object?.get<String>(
                          sdk.keyVarObjectId,
                          defaultValue: 'removingItem')),
                      childBuilder: widget.childBuilder ??
                          ParseLiveListWidget.defaultChildBuilder,
                      sizeFactor: animation,
                      duration: widget.duration,
                      loadedData: () => event.object,
                      preLoadedData: () => event.object,
                    ),
                duration: widget.duration);
          }
        });
      });
    });
  }

  final sdk.QueryBuilder<T> query;
  sdk.ParseLiveList<T> _liveList;
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  final ChildBuilder<T> removedItemBuilder;

  @override
  Widget build(BuildContext context) {
    return _liveList == null
        ? widget.listLoadingElement ?? Container()
        : buildAnimatedList();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Widget buildAnimatedList() {
    return AnimatedList(
        key: _animatedListKey,
        physics: widget.scrollPhysics,
        controller: widget.scrollController,
        scrollDirection: widget.scrollDirection,
        padding: widget.padding,
        primary: widget.primary,
        reverse: widget.reverse,
        shrinkWrap: widget.shrinkWrap,
        initialItemCount: _liveList?.size,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return ParseLiveListElementWidget<T>(
            key: ValueKey<String>(
                _liveList?.getIdentifier(index) ?? '_NotFound'),
            stream: () => _liveList?.getAt(index),
            loadedData: () => _liveList?.getLoadedAt(index),
            preLoadedData: () => _liveList?.getPreLoadedAt(index),
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
      {Key key,
      this.stream,
      this.loadedData,
      this.preLoadedData,
      @required this.sizeFactor,
      @required this.duration,
      @required this.childBuilder})
      : super(key: key);

  final sdk.StreamGetter<T> stream;
  final sdk.DataGetter<T> loadedData;
  final sdk.DataGetter<T> preLoadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder<T> childBuilder;

  @override
  _ParseLiveListElementWidgetState<T> createState() {
    return _ParseLiveListElementWidgetState<T>(
        loadedData, preLoadedData, stream);
  }
}

class _ParseLiveListElementWidgetState<T extends sdk.ParseObject>
    extends State<ParseLiveListElementWidget<T>>
    with SingleTickerProviderStateMixin {
  _ParseLiveListElementWidgetState(sdk.DataGetter<T> loadedDataGetter,
      sdk.DataGetter<T> preLoadedDataGetter, sdk.StreamGetter<T> stream) {
    _snapshot = sdk.ParseLiveListElementSnapshot<T>(
        loadedData: loadedDataGetter(), preLoadedData: preLoadedDataGetter());
    if (stream != null) {
      _streamSubscription = stream().listen(
        (T data) {
          if (widget != null) {
            setState(() {
              _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                  loadedData: data, preLoadedData: data);
            });
          } else {
            _snapshot = sdk.ParseLiveListElementSnapshot<T>(
                loadedData: data, preLoadedData: data);
          }
        },
        onError: (Object error) {
          if (error is sdk.ParseError) {
            if (widget != null) {
              setState(() {
                _snapshot = sdk.ParseLiveListElementSnapshot<T>(error: error);
              });
            } else {
              _snapshot = sdk.ParseLiveListElementSnapshot<T>(error: error);
            }
          }
        },
        cancelOnError: false,
      );
    }
  }

  sdk.ParseLiveListElementSnapshot<T> _snapshot;

  StreamSubscription<T> _streamSubscription;

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
        vsync: this,
        child: widget.childBuilder(context, _snapshot),
      ),
    );
    return result;
  }
}
