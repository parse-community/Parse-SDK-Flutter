import 'dart:async';

import 'package:flutter/material.dart';

import '../../parse_server_sdk.dart';

class ParseLiveList<T extends ParseObject> {
  ParseLiveList._(this._query);

  static Future<ParseLiveList<T>> create<T extends ParseObject>(
      QueryBuilder<T> _query) {
    final ParseLiveList<T> parseLiveList = ParseLiveList<T>._(_query);

    return parseLiveList._init().then((_) {
      //TODO: Error-handling
      return parseLiveList;
    });
  }

//  final List<ParseLiveListElement<T>> _loadedElements =
//      List<ParseLiveListElement<T>>();
  List<ParseLiveListElement<T>> _list = List<ParseLiveListElement<T>>();
  StreamController<LiveListEvent<T>> _eventStreamController;
  int _nextID = 0;

//  static Future get create<T extends ParseObject>() {
//  }

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
//  int _size;

  int get size {
    return _list.length;
  }

  Stream<LiveListEvent<T>> get stream => _eventStreamController.stream;
  Subscription _subscription;

  Future<void> _init() async {
    _eventStreamController = StreamController<LiveListEvent<T>>();
//    final ParseResponse parseResponse = await _query.count();
//    _size = parseResponse.count;

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

    final ParseResponse parseResponse = await query.query();
    if (parseResponse.success) {
      _list = parseResponse.results
          .map<ParseLiveListElement<T>>(
              (dynamic element) => ParseLiveListElement<T>(element))
          .toList();
      _list.forEach((ParseLiveListElement<T> element) => print(element.object));
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
    return size;
  }

//  int _findObjectIndex(T object) {
//    for (int i = 0; i < _loadedElements.length; i++) {
//      if (after(object, _loadedElements[i].object) != false) return i;
//    }
//    return _loadedElements.length;
//  }

  void _objectAdded(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (after(object, _list[i].object) != true) {
        _list.insert(i, ParseLiveListElement<T>(object, loaded: true));
        _eventStreamController.sink.add(LiveListAddEvent<T>(i, object));
        return;
      }
    }
    _list.add(ParseLiveListElement<T>(object, loaded: true));
    _eventStreamController.sink
        .add(LiveListAddEvent<T>(_list.length - 1, object));
  }

  void _objectUpdated(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        _list[i] = ParseLiveListElement<T>(object, loaded: true);
        _eventStreamController.sink.add(LiveListUpdateEvent<T>(i, object));
        break;
      }
    }
  }

  void _objectDeleted(T object) {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        _list.removeAt(i);
        _eventStreamController.sink.add(LiveListDeleteEvent<T>(i, object));
        break;
      }
    }
  }

  Future<T> getAt(final int i) async {
    if (!_list[i].loaded) {
      final QueryBuilder<T> queryBuilder = QueryBuilder<T>.copy(_query)
        ..whereEqualTo(
            keyVarObjectId, _list[i].object.get<String>(keyVarObjectId))
        ..setLimit(1);
      final ParseResponse response = await queryBuilder.query();
      if (response.success) {
        _list[i] =
            ParseLiveListElement<T>(response.results.first, loaded: false);
      } else {
        throw response.error;
      }
//      final QueryBuilder<T> queryBuilder = QueryBuilder<T>.copy(_query)
//        ..setAmountToSkip(i)
//        ..setLimit(1);
//      try {
//        print('load $i');
//        final ParseResponse response = await queryBuilder.query();
//
//        if (response.success) {
////          print('load $i success: ${response.results.first}');
//          _loadedElements[i].object = response.results.first;
//        } else {
//          print('load $i error');
//          print(response.error);
//        }
//      } on Exception catch (e) {
//        print('load $i exception');
//        print(e);
//      }
    }
    return _list[i].object;
  }

  String idOf(int index) {
    return _list[index].object.get<String>(keyVarObjectId);
  }

  void test() {
    for (int j = 0; j < _list.length; ++j) {
      for (int k = 0; k < _list.length; ++k) {
        print(
            '${_list[j].object.get<String>("text")} after ${_list[k].object.get<String>("text")}: ${after(_list[j].object, _list[k].object)}');
      }
    }
  }
}

class ParseLiveListElement<T extends ParseObject> {
  ParseLiveListElement(this.object, {this.loaded = false});

  T object;
  bool loaded;
}

class ParseLiveListBuilder<T extends ParseObject> extends StatefulWidget {
  const ParseLiveListBuilder({
    Key key,
    @required this.query,
    this.listLoadingElement,
  }) : super(key: key);

  final QueryBuilder<T> query;
  final Widget listLoadingElement;

  @override
  _ParseLiveListBuilderState<T> createState() =>
      _ParseLiveListBuilderState<T>(query);
}

class _ParseLiveListBuilderState<T extends ParseObject>
    extends State<ParseLiveListBuilder<T>> {
  _ParseLiveListBuilderState(this._query) {
    ParseLiveList.create(_query).then((ParseLiveList<T> value) {
      setState(() {
        _liveList = value;
        _liveList.stream.listen((LiveListEvent<ParseObject> event) {
          setState(() {});
        });
      });
    });
  }

  final QueryBuilder<T> _query;
  ParseLiveList _liveList;

  @override
  Widget build(BuildContext context) {
    return _liveList == null
        ? widget.listLoadingElement == null
            ? Container()
            : widget.listLoadingElement
        : Row(
            children: <Widget>[
              FlatButton(
                onPressed: _liveList.test,
                child: Text("test"),
              ),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) => FutureBuilder(
                    key: ValueKey<String>(_liveList.idOf(index)),
                    future: _liveList.getAt(index),
                    builder: (BuildContext context,
                        AsyncSnapshot<ParseObject> snapshot) {
                      print('$index: ${snapshot.connectionState}');
                      if (snapshot.hasData) {
                        return ListTile(
                          title: Text(
                            snapshot.data.get("text"),
                          ),
                        );
                      }
                      return Text("loading");
                    },
                  ),
                  itemCount: _liveList.size,
                ),
              ),
            ],
          );
  }
}

//abstract class LiveListEvent<T extends ParseObject> {}
//
//class LiveListSizeEvent<T extends ParseObject> extends LiveListEvent<T> {
//  LiveListSizeEvent(this._size);
//
//  final int _size;
//
//  int get size => _size;
//}

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

class LiveListUpdateEvent<T extends ParseObject> extends LiveListEvent<T> {
  LiveListUpdateEvent(int index, T object) : super(index, object);
}
