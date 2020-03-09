import 'dart:async';

import 'package:flutter/material.dart';

import '../../parse_server_sdk.dart';

class ParseLiveList<T extends ParseObject> {
  ParseLiveList._(this._query);

  static Future<ParseLiveList<T>> create<T extends ParseObject>(
      QueryBuilder<T> _query) {
    final ParseLiveList<T> parseLiveList = ParseLiveList<T>._(_query);

    return parseLiveList._init().then((_) {
      return parseLiveList;
    });
  }

  List<ParseLiveListElement<T>> _list = List<ParseLiveListElement<T>>();
  StreamController<LiveListEvent<T>> _eventStreamController;
  int _nextID = 0;

  /// is object1 listed after object2?
  /// can return null
  bool after(T object1, T object2) {
    List<String> fields = List<String>();

    if (_query.limiters.containsKey('order')) {
      fields = _query.limiters['order'].toString().split(',');
    }
    fields.add(keyVarCreatedAt);
    for (String key in fields) {
      bool reverse = false;
      if (key.startsWith('-')) {
        reverse = true;
        key = key.substring(1);
      }
      final dynamic val1 = object1.get<dynamic>(key);
      final dynamic val2 = object2.get<dynamic>(key);

      if (val1 == null && val2 == null) break;
      if (val1 == null) return reverse;
      if (val2 == null) return !reverse;

      if (val1 is num && val2 is num) {
        if ((val1 as num) < (val2 as num)) return reverse;
        if ((val1 as num) > (val2 as num)) return !reverse;
      } else if (val1 is String && val2 is String) {
        if (val1.toString().compareTo(val2) < 0) return reverse;
        if (val1.toString().compareTo(val2) > 0) return !reverse;
      } else if (val1 is DateTime && val2 is DateTime) {
        if ((val1 as DateTime).isAfter(val2)) return !reverse;
        if ((val1 as DateTime).isBefore(val2)) return reverse;
      }
    }
    return null;
  }

  int get nextID => _nextID++;

  final QueryBuilder<T> _query;

  int get size {
    return _list.length;
  }

  Stream<LiveListEvent<T>> get stream => _eventStreamController.stream;
  Subscription _subscription;

  Future<ParseResponse> _runQuery() async {
    final QueryBuilder<T> query = QueryBuilder<T>.copy(_query);
    if (query.limiters.containsKey('order')) {
      query.keysToReturn(
          query.limiters['order'].toString().split(',').map((String string) {
        if (string.startsWith('-')) return string.substring(1);
        return string;
      }).toList());
    } else {
      query.keysToReturn(List<String>());
    }

    return await query.query();
  }

  Future<void> _init() async {
    _eventStreamController = StreamController<LiveListEvent<T>>();

    final ParseResponse parseResponse = await _runQuery();
    if (parseResponse.success) {
      _list = parseResponse.results
          .map<ParseLiveListElement<T>>(
              (dynamic element) => ParseLiveListElement<T>(element))
          .toList();
    }

    LiveQuery()
        .client
        .subscribe(QueryBuilder<T>.copy(_query))
        .then((Subscription subscription) {
      _subscription = subscription;
      subscription.on(LiveQueryEvent.create, _objectAdded);
      subscription.on(LiveQueryEvent.update, _objectUpdated);
      subscription.on(LiveQueryEvent.enter, _objectAdded);
      subscription.on(LiveQueryEvent.leave, _objectDeleted);
      subscription.on(LiveQueryEvent.delete, _objectDeleted);
    });

    LiveQuery()
        .client
        .getClientEventStream
        .listen((LiveQueryClientEvent event) async {
      if (event == LiveQueryClientEvent.CONNECTED) {
        ParseResponse parseResponse = await _runQuery();
        if (parseResponse.success) {
          List<T> newlist = parseResponse.results;

          //update List
          for (int i = 0; i < _list.length; i++) {
            final ParseObject currentObject = _list[i].object;
            final String currentObjectId =
                currentObject.get<String>(keyVarObjectId);

            bool stillInList = false;

            for (int j = 0; j < newlist.length; j++) {
              if (newlist[j].get<String>(keyVarObjectId) == currentObjectId) {
                stillInList = true;
                if (newlist[j]
                    .get<DateTime>(keyVarUpdatedAt)
                    .isAfter(currentObject.get<DateTime>(keyVarUpdatedAt))) {
                  QueryBuilder<T> queryBuilder = QueryBuilder<T>.copy(_query)
                    ..whereEqualTo(keyVarObjectId, currentObjectId);
                  queryBuilder.query().then((ParseResponse result) {
                    if (result.success) {
                      _objectUpdated(result.results.first);
                    }
                  });
                }
                newlist.removeAt(j);
                j--;
                break;
              }
            }
            if (!stillInList) {
              _objectDeleted(currentObject);
              i--;
            }
          }

          for (int i = 0; i < newlist.length; i++) {
            _objectAdded(newlist[i], loaded: false);
          }

//          _eventStreamController.sink.add(LiveListUpdateEvent<T>());
        }
      }
    });
  }

  void _objectAdded(T object, {bool loaded = true}) {
    for (int i = 0; i < _list.length; i++) {
      if (after(object, _list[i].object) != true) {
        _list.insert(i, ParseLiveListElement<T>(object, loaded: loaded));
        _eventStreamController.sink.add(LiveListAddEvent<T>(i, object));
        return;
      }
    }
    _list.add(ParseLiveListElement<T>(object, loaded: loaded));
    _eventStreamController.sink
        .add(LiveListAddEvent<T>(_list.length - 1, object));
  }

  void _updateObject(T object) {}

  void _objectUpdated(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        if (after(_list[i].object, object) == null) {
          _list[i].object = object;
        } else {
          _list.removeAt(i).dispose();
          _eventStreamController.sink.add(LiveListDeleteEvent<T>(i, object));
          _objectAdded(object);
        }
        break;
      }
    }
  }

  void _objectDeleted(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        _list.removeAt(i).dispose();
        _eventStreamController.sink.add(LiveListDeleteEvent<T>(i, object));
        break;
      }
    }
  }

  Stream<T> getAt(final int i) async* {
    if (!_list[i].loaded) {
      final QueryBuilder<T> queryBuilder = QueryBuilder<T>.copy(_query)
        ..whereEqualTo(
            keyVarObjectId, _list[i].object.get<String>(keyVarObjectId))
        ..setLimit(1);
      final ParseResponse response = await queryBuilder.query();
      if (response.success) {
        _list[i].object = response.results.first;
      } else {
        throw response.error;
      }
    }
//    just for testing
//    await Future<void>.delayed(const Duration(seconds: 2));
    yield _list[i].object;
    yield* _list[i].stream;
  }

  String idOf(int index) {
    return _list[index].object.get<String>(keyVarObjectId);
  }

  T getLoadedAt(int index) {
    if (_list[index].loaded) return _list[index].object;
    return null;
  }
}

class ParseLiveListElement<T extends ParseObject> {
  ParseLiveListElement(this._object, {bool loaded = false}) {
    if (_object != null) _loaded = loaded;
  }

  final StreamController<T> _streamController = StreamController<T>.broadcast();
  T _object;
  bool _loaded = false;

  Stream<T> get stream => _streamController?.stream;

  T get object => _object;

  set object(T value) {
    _loaded = true;
    _object = value;
    _streamController?.add(object);
  }

  bool get loaded => _loaded;

  void dispose() {
    _streamController.close();
  }
}

typedef Stream<T> StreamGetter<T extends ParseObject>();
typedef T DataGetter<T extends ParseObject>();
typedef Widget ChildBuilder<T extends ParseObject>(
    BuildContext context, bool failed, T loadedData);
typedef Widget RemovedItemBuilder<T extends ParseObject>(
    BuildContext context, int index, T oldObject);

class ParseLiveListBuilder<T extends ParseObject> extends StatefulWidget {
  const ParseLiveListBuilder(
      {Key key,
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
      this.removedItemBuilder})
      : super(key: key);

  final QueryBuilder<T> query;
  final Widget listLoadingElement;
  final Duration duration;
  final ScrollPhysics scrollPhysics;
  final ScrollController scrollController;

  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final bool primary;
  final bool reverse;
  final bool shrinkWrap;

  final ChildBuilder childBuilder;
  final RemovedItemBuilder<T> removedItemBuilder;

  @override
  _ParseLiveListBuilderState<T> createState() =>
      _ParseLiveListBuilderState<T>(query, removedItemBuilder);

  static Widget defaultChildBuilder<T extends ParseObject>(
      BuildContext context, bool failed, T loadedData) {
    Widget child;
    if (failed) {
      child = const Text('something went wrong!');
    } else if (loadedData != null) {
      child = ListTile(
        title: Text(
          loadedData.get(keyVarObjectId),
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

class _ParseLiveListBuilderState<T extends ParseObject>
    extends State<ParseLiveListBuilder<T>> {
  _ParseLiveListBuilderState(this._query, this.removedItemBuilder) {
    ParseLiveList.create(_query).then((ParseLiveList<T> value) {
      setState(() {
        _liveList = value;
        _liveList.stream.listen((LiveListEvent<ParseObject> event) {
          if (event is LiveListAddEvent) {
            if (_animatedListKey.currentState != null)
              _animatedListKey.currentState.insertItem(event.index);
          } else if (event is LiveListDeleteEvent) {
            _animatedListKey.currentState.removeItem(
                event.index,
                (BuildContext context, Animation<double> animation) =>
                    ListElement<T>(
                      key: ValueKey<String>(event.object?.get<String>(
                          keyVarObjectId,
                          defaultValue: 'removingItem')),
                      childBuilder: widget.childBuilder ??
                          ParseLiveListBuilder.defaultChildBuilder,
                      sizeFactor: animation,
                      duration: widget.duration,
                      loadedData: () => event.object,
                    ));
          }
        });
      });
    });
  }

  final QueryBuilder<T> _query;
  ParseLiveList<T> _liveList;
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  final RemovedItemBuilder<T> removedItemBuilder;

  @override
  Widget build(BuildContext context) {
    return _liveList == null
        ? widget.listLoadingElement == null
            ? Container()
            : widget.listLoadingElement
        : buildAnimatedList();
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
        initialItemCount: _liveList.size,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return ListElement<T>(
            key: ValueKey<String>(_liveList.idOf(index)),
            stream: () => _liveList.getAt(index),
            loadedData: () => _liveList.getLoadedAt(index),
            sizeFactor: animation,
            duration: widget.duration,
            childBuilder:
                widget.childBuilder ?? ParseLiveListBuilder.defaultChildBuilder,
          );
        });
  }
}

class ListElement<T extends ParseObject> extends StatefulWidget {
  const ListElement(
      {Key key,
      this.stream,
      this.loadedData,
      @required this.sizeFactor,
      @required this.duration,
      @required this.childBuilder})
      : super(key: key);

  final StreamGetter<T> stream;
  final DataGetter<T> loadedData;
  final Animation<double> sizeFactor;
  final Duration duration;
  final ChildBuilder childBuilder;

  @override
  _ListElementState<T> createState() {
    return _ListElementState<T>(loadedData, stream);
  }
}

class _ListElementState<T extends ParseObject> extends State<ListElement<T>>
    with SingleTickerProviderStateMixin {
  _ListElementState(DataGetter<T> loadedDataGetter, StreamGetter<T> stream) {
    loadedData = loadedDataGetter();
    if (stream != null) {
      _streamSubscription = stream().listen((T data) {
        if (widget != null) {
          setState(() {
            loadedData = data;
          });
        } else {
          loadedData = data;
        }
      });
    }
  }
  T loadedData;
  bool failed = false;
  StreamSubscription<T> _streamSubscription;
  bool firstBuild = true;

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget result = SizeTransition(
      sizeFactor: widget.sizeFactor,
      child: AnimatedSize(
        duration: widget.duration,
        vsync: this,
        child: widget.childBuilder(context, failed, loadedData),
      ),
    );
    firstBuild = false;
    return result;
  }
}

abstract class LiveListEvent<T extends ParseObject> {
  LiveListEvent(this._index, this._object); //, this._object);

  final int _index;
  final T _object;

  int get index => _index;
  T get object => _object;
}

class LiveListAddEvent<T extends ParseObject> extends LiveListEvent<T> {
  LiveListAddEvent(int index, T object) : super(index, object);
}

class LiveListDeleteEvent<T extends ParseObject> extends LiveListEvent<T> {
  LiveListDeleteEvent(int index, T object) : super(index, object);
}
