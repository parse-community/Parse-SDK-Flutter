import 'dart:async';

import 'package:flutter/material.dart';

import '../../parse_server_sdk.dart';

// ignore_for_file: invalid_use_of_protected_member
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
  StreamController<ParseLiveListEvent<T>> _eventStreamController;
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

      if (val1 == null && val2 == null) {
        break;
      }
      if (val1 == null) {
        return reverse;
      }
      if (val2 == null) {
        return !reverse;
      }

      if (val1 is num && val2 is num) {
        if (val1 < val2) {
          return reverse;
        }
        if (val1 > val2) {
          return !reverse;
        }
      } else if (val1 is String && val2 is String) {
        if (val1.toString().compareTo(val2) < 0) {
          return reverse;
        }
        if (val1.toString().compareTo(val2) > 0) {
          return !reverse;
        }
      } else if (val1 is DateTime && val2 is DateTime) {
        if (val1.isAfter(val2)) {
          return !reverse;
        }
        if (val1.isBefore(val2)) {
          return reverse;
        }
      }
    }
    return null;
  }

  int get nextID => _nextID++;

  final QueryBuilder<T> _query;

  int get size {
    return _list.length;
  }

  Stream<ParseLiveListEvent<T>> get stream => _eventStreamController.stream;
  Subscription<T> _liveQuerySubscription;
  StreamSubscription<LiveQueryClientEvent> _liveQueryClientEventSubscription;

  Future<ParseResponse> _runQuery() async {
    final QueryBuilder<T> query = QueryBuilder<T>.copy(_query);
    if (query.limiters.containsKey('order')) {
      query.keysToReturn(
          query.limiters['order'].toString().split(',').map((String string) {
            if (string.startsWith('-')) {
              return string.substring(1);
            }
        return string;
      }).toList());
    } else {
      query.keysToReturn(List<String>());
    }

    return await query.query<T>();
  }

  Future<void> _init() async {
    _eventStreamController = StreamController<ParseLiveListEvent<T>>();

    final ParseResponse parseResponse = await _runQuery();
    if (parseResponse.success) {
      _list = parseResponse.results
              ?.map<ParseLiveListElement<T>>(
                  (dynamic element) => ParseLiveListElement<T>(element))
              ?.toList() ??
          List<ParseLiveListElement<T>>();
    }

    LiveQuery()
        .client
        .subscribe<T>(QueryBuilder<T>.copy(_query),
            copyObject: _query.object.clone(_query.object.toJson()))
        .then((Subscription<T> subscription) {
      _liveQuerySubscription = subscription;
      subscription.on(LiveQueryEvent.create, _objectAdded);
      subscription.on(LiveQueryEvent.update, _objectUpdated);
      subscription.on(LiveQueryEvent.enter, _objectAdded);
      subscription.on(LiveQueryEvent.leave, _objectDeleted);
      subscription.on(LiveQueryEvent.delete, _objectDeleted);
    });

    _liveQueryClientEventSubscription = LiveQuery()
        .client
        .getClientEventStream
        .listen((LiveQueryClientEvent event) async {
      if (event == LiveQueryClientEvent.CONNECTED) {
        final ParseResponse parseResponse = await _runQuery();
        if (parseResponse.success) {
          final List<T> newList = parseResponse.results ?? List<T>();

          //update List
          for (int i = 0; i < _list.length; i++) {
            final ParseObject currentObject = _list[i].object;
            final String currentObjectId =
                currentObject.get<String>(keyVarObjectId);

            bool stillInList = false;

            for (int j = 0; j < newList.length; j++) {
              if (newList[j].get<String>(keyVarObjectId) == currentObjectId) {
                stillInList = true;
                if (newList[j]
                    .get<DateTime>(keyVarUpdatedAt)
                    .isAfter(currentObject.get<DateTime>(keyVarUpdatedAt))) {
                  final QueryBuilder<T> queryBuilder =
                      QueryBuilder<T>.copy(_query)
                        ..whereEqualTo(keyVarObjectId, currentObjectId);
                  queryBuilder.query<T>().then((ParseResponse result) {
                    if (result.success && result.results != null) {
                      _objectUpdated(result.results.first);
                    }
                  });
                }
                newList.removeAt(j);
                j--;
                break;
              }
            }
            if (!stillInList) {
              _objectDeleted(currentObject);
              i--;
            }
          }

          for (int i = 0; i < newList.length; i++) {
            _objectAdded(newList[i], loaded: false);
          }
        }
      }
    });
  }

  void _objectAdded(T object, {bool loaded = true}) {
    for (int i = 0; i < _list.length; i++) {
      if (after(object, _list[i].object) != true) {
        _list.insert(i, ParseLiveListElement<T>(object, loaded: loaded));
        _eventStreamController.sink.add(ParseLiveListAddEvent<T>(
            i, object?.clone(object?.toJson(full: true))));
        return;
      }
    }
    _list.add(ParseLiveListElement<T>(object, loaded: loaded));
    _eventStreamController.sink.add(ParseLiveListAddEvent<T>(
        _list.length - 1, object?.clone(object?.toJson(full: true))));
  }

  void _objectUpdated(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        if (after(_list[i].object, object) == null) {
          _list[i].object = object;
        } else {
          _list.removeAt(i).dispose();
          _eventStreamController.sink.add(ParseLiveListDeleteEvent<T>(
            // ignore: invalid_use_of_protected_member
              i,
              object?.clone(object?.toJson(full: true))));
          // ignore: invalid_use_of_protected_member
          _objectAdded(object?.clone(object?.toJson(full: true)));
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
        _eventStreamController.sink.add(ParseLiveListDeleteEvent<T>(
            i, object?.clone(object?.toJson(full: true))));
        break;
      }
    }
  }

  Stream<T> getAt(final int index) async* {
    if (index < _list.length) {
      if (!_list[index].loaded) {
        final QueryBuilder<T> queryBuilder = QueryBuilder<T>.copy(_query)
          ..whereEqualTo(
              keyVarObjectId, _list[index].object.get<String>(keyVarObjectId))
          ..setLimit(1);
        final ParseResponse response = await queryBuilder.query<T>();
        if (response.success) {
          _list[index].object = response.results?.first;
        } else {
          _list[index].object = null;
          throw response.error;
        }
      }
//    just for testing
//    await Future<void>.delayed(const Duration(seconds: 2));
      yield _list[index].object;
      yield* _list[index].stream;
    }
  }

  String idOf(int index) {
    if (index < _list.length) {
      return _list[index].object.get<String>(keyVarObjectId);
    }
    return 'NotFound';
  }

  T getLoadedAt(int index) {
    if (index < _list.length && _list[index].loaded) {
      return _list[index].object;
    }
    return null;
  }

  void dispose() {
    if (_liveQuerySubscription != null) {
      LiveQuery().client.unSubscribe(_liveQuerySubscription);
      _liveQuerySubscription = null;
    }
    if (_liveQueryClientEventSubscription != null) {
      _liveQueryClientEventSubscription.cancel();
      _liveQueryClientEventSubscription = null;
    }
    while (_list.isNotEmpty) {
      _list.removeLast().dispose();
    }
  }
}

class ParseLiveListElement<T extends ParseObject> {
  ParseLiveListElement(this._object, {bool loaded = false}) {
    if (_object != null) {
      _loaded = loaded;
    }
  }

  final StreamController<T> _streamController = StreamController<T>.broadcast();
  T _object;
  bool _loaded = false;

  Stream<T> get stream => _streamController?.stream;

  // ignore: invalid_use_of_protected_member
  T get object => _object?.clone(_object?.toJson(full: true));

  set object(T value) {
    _loaded = true;
    _object = value;
    // ignore: invalid_use_of_protected_member
    _streamController?.add(_object?.clone(_object?.toJson(full: true)));
  }

  bool get loaded => _loaded;

  void dispose() {
    _streamController.close();
  }
}

abstract class ParseLiveListEvent<T extends ParseObject> {
  ParseLiveListEvent(this._index, this._object); //, this._object);

  final int _index;
  final T _object;

  int get index => _index;

  T get object => _object;
}

class ParseLiveListAddEvent<T extends ParseObject>
    extends ParseLiveListEvent<T> {
  ParseLiveListAddEvent(int index, T object) : super(index, object);
}

class ParseLiveListDeleteEvent<T extends ParseObject>
    extends ParseLiveListEvent<T> {
  ParseLiveListDeleteEvent(int index, T object) : super(index, object);
}

typedef StreamGetter<T extends ParseObject> = Stream<T> Function();
typedef DataGetter<T extends ParseObject> = T Function();
typedef ChildBuilder<T extends ParseObject> = Widget Function(
    BuildContext context, ParseLiveListElementSnapshot<T> snapshot);

class ParseLiveListElementSnapshot<T extends ParseObject> {
  ParseLiveListElementSnapshot({this.loadedData, this.error});

  final T loadedData;
  final ParseError error;

  bool get hasData => loadedData != null;

  bool get failed => error != null;
}

class ParseLiveListWidget<T extends ParseObject> extends StatefulWidget {
  const ParseLiveListWidget(
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

  final ChildBuilder<T> childBuilder;
  final ChildBuilder<T> removedItemBuilder;

  @override
  _ParseLiveListWidgetState<T> createState() =>
      _ParseLiveListWidgetState<T>(query, removedItemBuilder);

  static Widget defaultChildBuilder<T extends ParseObject>(
      BuildContext context, ParseLiveListElementSnapshot<T> snapshot) {
    Widget child;
    if (snapshot.failed) {
      child = const Text('something went wrong!');
    } else if (snapshot.hasData) {
      child = ListTile(
        title: Text(
          snapshot.loadedData.get(keyVarObjectId),
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

class _ParseLiveListWidgetState<T extends ParseObject>
    extends State<ParseLiveListWidget<T>> {
  _ParseLiveListWidgetState(this._query, this.removedItemBuilder) {
    ParseLiveList.create(_query).then((ParseLiveList<T> value) {
      setState(() {
        _liveList = value;
        _liveList.stream.listen((ParseLiveListEvent<ParseObject> event) {
          if (event is ParseLiveListAddEvent) {
            if (_animatedListKey.currentState != null)
              _animatedListKey.currentState
                  .insertItem(event.index, duration: widget.duration);
          } else if (event is ParseLiveListDeleteEvent) {
            _animatedListKey.currentState.removeItem(
                event.index,
                (BuildContext context, Animation<double> animation) =>
                    ParseLiveListElementWidget<T>(
                      key: ValueKey<String>(event.object?.get<String>(
                          keyVarObjectId,
                          defaultValue: 'removingItem')),
                      childBuilder: widget.childBuilder ??
                          ParseLiveListWidget.defaultChildBuilder,
                      sizeFactor: animation,
                      duration: widget.duration,
                      loadedData: () => event.object,
                    ),
                duration: widget.duration);
          }
        });
      });
    });
  }

  final QueryBuilder<T> _query;
  ParseLiveList<T> _liveList;
  final GlobalKey<AnimatedListState> _animatedListKey =
      GlobalKey<AnimatedListState>();
  final ChildBuilder<T> removedItemBuilder;

  @override
  Widget build(BuildContext context) {
    return _liveList == null
        ? widget.listLoadingElement ?? Container()
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
        initialItemCount: _liveList?.size,
        itemBuilder:
            (BuildContext context, int index, Animation<double> animation) {
          return ParseLiveListElementWidget<T>(
            key: ValueKey<String>(_liveList?.idOf(index) ?? '_NotFound'),
            stream: () => _liveList?.getAt(index),
            loadedData: () => _liveList?.getLoadedAt(index),
            sizeFactor: animation,
            duration: widget.duration,
            childBuilder:
                widget.childBuilder ?? ParseLiveListWidget.defaultChildBuilder,
          );
        });
  }

  @override
  void dispose() {
    _liveList.dispose();
    _liveList = null;
    super.dispose();
  }
}

class ParseLiveListElementWidget<T extends ParseObject> extends StatefulWidget {
  const ParseLiveListElementWidget(
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
  final ChildBuilder<T> childBuilder;

  @override
  _ParseLiveListElementWidgetState<T> createState() {
    return _ParseLiveListElementWidgetState<T>(loadedData, stream);
  }
}

class _ParseLiveListElementWidgetState<T extends ParseObject>
    extends State<ParseLiveListElementWidget<T>>
    with SingleTickerProviderStateMixin {
  _ParseLiveListElementWidgetState(
      DataGetter<T> loadedDataGetter, StreamGetter<T> stream) {
//    loadedData = loadedDataGetter();
    _snapshot = ParseLiveListElementSnapshot<T>(loadedData: loadedDataGetter());
    if (stream != null) {
      _streamSubscription = stream().listen(
        (T data) {
          if (widget != null) {
            setState(() {
              _snapshot = ParseLiveListElementSnapshot<T>(loadedData: data);
            });
          } else {
            _snapshot = ParseLiveListElementSnapshot<T>(loadedData: data);
          }
        },
        onError: (Object error) {
          if (error is ParseError) {
            if (widget != null) {
              setState(() {
                _snapshot = ParseLiveListElementSnapshot<T>(error: error);
              });
            } else {
              _snapshot = ParseLiveListElementSnapshot<T>(error: error);
            }
          }
        },
        cancelOnError: false,
      );
    }
  }

  ParseLiveListElementSnapshot<T> _snapshot;

  StreamSubscription<T> _streamSubscription;

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
