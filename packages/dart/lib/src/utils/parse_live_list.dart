part of flutter_parse_sdk;

// ignore_for_file: invalid_use_of_protected_member
class ParseLiveList<T extends ParseObject> {
  ParseLiveList._(this._query, this._listeningIncludes, this._lazyLoading,
      {List<String> preloadedColumns = const <String>[]})
      : _preloadedColumns = preloadedColumns {
    _debug = isDebugEnabled();
  }

  static Future<ParseLiveList<T>> create<T extends ParseObject>(
    QueryBuilder<T> _query, {
    bool listenOnAllSubItems,
    List<String> listeningIncludes,
    bool lazyLoading = true,
    List<String> preloadedColumns,
  }) {
    final ParseLiveList<T> parseLiveList = ParseLiveList<T>._(
      _query,
      listenOnAllSubItems == true
          ? _toIncludeMap(
              _query.limiters['include']?.toString()?.split(',') ?? <String>[])
          : _toIncludeMap(listeningIncludes ?? <String>[]),
      lazyLoading,
      preloadedColumns: preloadedColumns,
    );

    return parseLiveList._init().then((_) {
      return parseLiveList;
    });
  }

  final QueryBuilder<T> _query;
  //The included Items, where LiveList should look for updates.
  final Map<String, dynamic> _listeningIncludes;
  final bool _lazyLoading;
  final List<String> _preloadedColumns;

  List<ParseLiveListElement<T>> _list = List<ParseLiveListElement<T>>();
  StreamController<ParseLiveListEvent<T>> _eventStreamController;
  int _nextID = 0;
  bool _debug;

  int get nextID => _nextID++;

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

  int get size {
    return _list.length;
  }

  List<String> get includes =>
      _query.limiters['include']?.toString()?.split(',') ?? <String>[];

  Map<String, dynamic> get _includePaths {
    return _toIncludeMap(includes);
  }

  static Map<String, dynamic> _toIncludeMap(List<String> includes) {
    final Map<String, dynamic> includesMap = <String, dynamic>{};

    for (String includeString in includes) {
      final List<String> pathParts = includeString.split('.');
      Map<String, dynamic> root = includesMap;
      for (String pathPart in pathParts) {
        root.putIfAbsent(pathPart, () => <String, dynamic>{});
        root = root[pathPart];
      }
    }

    return includesMap;
  }

  Stream<ParseLiveListEvent<T>> get stream => _eventStreamController.stream;
  Subscription<T> _liveQuerySubscription;
  StreamSubscription<LiveQueryClientEvent> _liveQueryClientEventSubscription;
  final Future<void> _updateQueue = Future<void>.value();

  Future<ParseResponse> _runQuery() async {
    final QueryBuilder<T> query = QueryBuilder<T>.copy(_query);
    if (_debug)
      print('ParseLiveList: lazyLoading is ${_lazyLoading ? 'on' : 'off'}');
    if (_lazyLoading) {
      final List<String> keys = _preloadedColumns?.toList() ?? <String>[];
      if (_lazyLoading && query.limiters.containsKey('order'))
        keys.addAll(
          query.limiters['order'].toString().split(',').map((String string) {
            if (string.startsWith('-')) {
              return string.substring(1);
            }
            return string;
          }),
        );
      query.keysToReturn(keys);
    }
    return await query.query<T>();
  }

  Future<void> _init() async {
    _eventStreamController = StreamController<ParseLiveListEvent<T>>();

    final ParseResponse parseResponse = await _runQuery();
    if (parseResponse.success) {
      _list = parseResponse.results
              ?.map<ParseLiveListElement<T>>((dynamic element) =>
                  ParseLiveListElement<T>(element,
                      updatedSubItems: _listeningIncludes,
                      loaded: !_lazyLoading))
              ?.toList() ??
          List<ParseLiveListElement<T>>();
    }

    LiveQuery()
        .client
        .subscribe<T>(QueryBuilder<T>.copy(_query),
            copyObject: _query.object.clone(_query.object.toJson()))
        .then((Subscription<T> subscription) {
      _liveQuerySubscription = subscription;

      //This should synchronize the events. Not sure if it is necessary, but it should help preventing unexpected results.
      subscription.on(LiveQueryEvent.create,
          (T object) => _updateQueue.whenComplete(() => _objectAdded(object)));
      subscription.on(
          LiveQueryEvent.update,
          (T object) =>
              _updateQueue.whenComplete(() => _objectUpdated(object)));
      subscription.on(LiveQueryEvent.enter,
          (T object) => _updateQueue.whenComplete(() => _objectAdded(object)));
      subscription.on(
          LiveQueryEvent.leave,
          (T object) =>
              _updateQueue.whenComplete(() => _objectDeleted(object)));
      subscription.on(
          LiveQueryEvent.delete,
          (T object) =>
              _updateQueue.whenComplete(() => _objectDeleted(object)));
//      subscription.on(LiveQueryEvent.create, _objectAdded);
//      subscription.on(LiveQueryEvent.update, _objectUpdated);
//      subscription.on(LiveQueryEvent.enter, _objectAdded);
//      subscription.on(LiveQueryEvent.leave, _objectDeleted);
//      subscription.on(LiveQueryEvent.delete, _objectDeleted);
    });

    _liveQueryClientEventSubscription = LiveQuery()
        .client
        .getClientEventStream
        .listen((LiveQueryClientEvent event) async {
      if (event == LiveQueryClientEvent.CONNECTED) {
        _updateQueue.whenComplete(() async {
          List<Future<void>> tasks = <Future<void>>[];
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
                    tasks.add(queryBuilder
                        .query<T>()
                        .then((ParseResponse result) async {
                      if (result.success && result.results != null) {
                        await _objectUpdated(result.results.first);
                      }
                    }));
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
              tasks.add(_objectAdded(newList[i], loaded: false));
            }
          }
          await Future.wait(tasks);
          tasks = <Future<void>>[];
          for (ParseLiveListElement<T> element in _list) {
            tasks.add(element.reconnected());
          }
          await Future.wait(tasks);
        });
      }
    });
  }

  static Future<void> _loadIncludes(ParseObject object,
      {ParseObject oldObject, Map<String, dynamic> paths}) async {
    if (object == null || paths == null || paths.isEmpty) {
      return;
    }

    final List<Future<void>> loadingNodes = <Future<void>>[];

    for (String key in paths.keys) {
      if (object.containsKey(key)) {
        ParseObject includedObject = object.get<ParseObject>(key);
        //If the object is not fetched
        if (!includedObject.containsKey(keyVarUpdatedAt)) {
          //See if oldObject contains key
          if (oldObject != null && oldObject.containsKey(key)) {
            includedObject = oldObject.get<ParseObject>(key);
            //If the object is not fetched || the ids don't match / the pointer changed
            if (!includedObject.containsKey(keyVarUpdatedAt) ||
                includedObject.objectId !=
                    object.get<ParseObject>(key).objectId) {
              includedObject = object.get<ParseObject>(key);
              //fetch from web including sub objects
              //same as down there
              final QueryBuilder<ParseObject> queryBuilder = QueryBuilder<
                  ParseObject>(ParseObject(includedObject.parseClassName))
                ..whereEqualTo(keyVarObjectId, includedObject.objectId)
                ..includeObject(_toIncludeStringList(paths[key]));
              loadingNodes.add(queryBuilder
                  .query()
                  .then<void>((ParseResponse parseResponse) {
                if (parseResponse.success &&
                    parseResponse.results.length == 1) {
                  // ignore: deprecated_member_use_from_same_package
                  object.getObjectData()[key] = parseResponse.results[0];
                }
              }));
              continue;
            } else {
              // ignore: deprecated_member_use_from_same_package
              object.getObjectData()[key] = includedObject;
              //recursion
              loadingNodes
                  .add(_loadIncludes(includedObject, paths: paths[key]));
              continue;
            }
          } else {
            //fetch from web including sub objects
            //same as up there
            final QueryBuilder<ParseObject> queryBuilder = QueryBuilder<
                ParseObject>(ParseObject(includedObject.parseClassName))
              ..whereEqualTo(keyVarObjectId, includedObject.objectId)
              ..includeObject(_toIncludeStringList(paths[key]));
            loadingNodes.add(
                queryBuilder.query().then<void>((ParseResponse parseResponse) {
              if (parseResponse.success && parseResponse.results.length == 1) {
                // ignore: deprecated_member_use_from_same_package
                object.getObjectData()[key] = parseResponse.results[0];
              }
            }));
            continue;
          }
        } else {
          //recursion
          loadingNodes.add(_loadIncludes(includedObject,
              oldObject: oldObject?.get(key), paths: paths[key]));
          continue;
        }
      } else {
        //All fine for this key
        continue;
      }
    }
    await Future.wait(loadingNodes);
  }

  static List<String> _toIncludeStringList(Map<String, dynamic> includes) {
    final List<String> includeList = <String>[];
    for (String key in includes.keys) {
      includeList.add(key);
      // ignore: avoid_as
      if ((includes[key] as Map<String, dynamic>).isNotEmpty) {
        includeList.addAll(
            _toIncludeStringList(includes[key]).map((String e) => '$key.$e'));
      }
    }
    return includeList;
  }

  Future<void> _objectAdded(T object,
      {bool loaded = true, bool fetchedIncludes = false}) async {
    //This line seems unnecessary, but without this, weird things happen.
    //(Hide first element, hide second, view first, view second => second is displayed twice)
    object = object?.clone(object?.toJson(full: true));

    if (!fetchedIncludes) {
      await _loadIncludes(object, paths: _includePaths);
    }
    for (int i = 0; i < _list.length; i++) {
      if (after(object, _list[i].object) != true) {
        _list.insert(
            i,
            ParseLiveListElement<T>(object,
                loaded: loaded, updatedSubItems: _listeningIncludes));
        _eventStreamController.sink.add(ParseLiveListAddEvent<T>(
            i, object?.clone(object?.toJson(full: true))));
        return;
      }
    }
    _list.add(ParseLiveListElement<T>(object,
        loaded: loaded, updatedSubItems: _listeningIncludes));
    _eventStreamController.sink.add(ParseLiveListAddEvent<T>(
        _list.length - 1, object?.clone(object?.toJson(full: true))));
  }

  Future<void> _objectUpdated(T object) async {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        await _loadIncludes(object,
            oldObject: _list[i].object, paths: _includePaths);
        if (after(_list[i].object, object) == null) {
          _list[i].object = object?.clone(object?.toJson(full: true));
        } else {
          _list.removeAt(i).dispose();
          _eventStreamController.sink.add(ParseLiveListDeleteEvent<T>(
              i, object?.clone(object?.toJson(full: true))));
          await _objectAdded(object?.clone(object?.toJson(full: true)),
              fetchedIncludes: true);
        }
        break;
      }
    }
  }

  Future<void> _objectDeleted(T object) async {
    for (int i = 0; i < _list.length; i++) {
      if (_list[i].object.get<String>(keyVarObjectId) ==
          object.get<String>(keyVarObjectId)) {
        await _loadIncludes(object,
            oldObject: _list[i].object, paths: _includePaths);
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
        if (_list.isEmpty) {
          yield* _createStreamError<T>(
              ParseError(message: 'ParseLiveList: _list is empty'));
          return;
        }
        if (response.success) {
          _list[index].object = response.results?.first;
        } else {
          _list[index].object = null;
          yield* _createStreamError<T>(response.error);
          return;
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

  String getIdentifier(int index) {
    if (index < _list.length) {
      return _list[index].object.get<String>(keyVarObjectId) +
              _list[index].object.get<DateTime>(keyVarUpdatedAt)?.toString() ??
          '';
    }
    return 'NotFound';
  }

  T getLoadedAt(int index) {
    if (index < _list.length && _list[index].loaded) {
      return _list[index].object;
    }
    return null;
  }

  T getPreLoadedAt(int index) {
    if (index < _list.length) {
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

class ParseLiveElement<T extends ParseObject> extends ParseLiveListElement<T> {
  ParseLiveElement(T object, {bool loaded = false, List<String> includeObject})
      : super(object,
            loaded: loaded,
            updatedSubItems:
                ParseLiveList._toIncludeMap(includeObject ?? <String>[])) {
    _includes = ParseLiveList._toIncludeMap(includeObject ?? <String>[]);
    queryBuilder = QueryBuilder<T>(object.clone(null))
      ..includeObject(includeObject)
      ..whereEqualTo(keyVarObjectId, object.objectId);
    _init(object, loaded: loaded, includeObject: includeObject);
  }

  Subscription<T> _subscription;
  Map<String, dynamic> _includes;
  QueryBuilder<T> queryBuilder;

  Future<void> _init(T object,
      {bool loaded = false, List<String> includeObject}) async {
    if (!loaded) {
      final ParseResponse parseResponse = await queryBuilder.query();
      if (parseResponse.success) {
        super.object = parseResponse.result.first;
      }
    }

    _subscription = await LiveQuery().client.subscribe<T>(
        QueryBuilder<T>.copy(queryBuilder),
        copyObject: object.clone(null));

    _subscription.on(LiveQueryEvent.update, (T newObject) async {
      await ParseLiveList._loadIncludes(newObject,
          oldObject: super.object, paths: _includes);
      super.object = newObject;
    });

    LiveQuery()
        .client
        .getClientEventStream
        .listen((LiveQueryClientEvent event) {
      _subscriptionQueue.whenComplete(() async {
        // ignore: missing_enum_constant_in_switch
        switch (event) {
          case LiveQueryClientEvent.CONNECTED:
            final ParseResponse parseResponse = await queryBuilder.query();
            if (parseResponse.success) {
              super.object = parseResponse.result.first;
            }
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    if (_subscription != null) {
      LiveQuery().client.unSubscribe(_subscription);
      _subscription = null;
    }
    super.dispose();
  }
}

class ParseLiveListElement<T extends ParseObject> {
  ParseLiveListElement(this._object,
      {bool loaded = false, Map<String, dynamic> updatedSubItems}) {
    if (_object != null) {
      _loaded = loaded;
    }
    _updatedSubItems =
        _toSubscriptionMap(updatedSubItems ?? Map<String, dynamic>());
    if (_updatedSubItems.isNotEmpty) {
      _liveQuery = LiveQuery();
      _subscribe();
    }
  }

  final StreamController<T> _streamController = StreamController<T>.broadcast();
  T _object;
  bool _loaded = false;
  Map<PathKey, dynamic> _updatedSubItems;
  LiveQuery _liveQuery;
  final Future<void> _subscriptionQueue = Future<void>.value();

  Stream<T> get stream => _streamController?.stream;

  // ignore: invalid_use_of_protected_member
  T get object => _object?.clone(_object?.toJson(full: true));

  Map<PathKey, dynamic> _toSubscriptionMap(Map<String, dynamic> map) {
    final Map<PathKey, dynamic> result = Map<PathKey, dynamic>();
    for (String key in map.keys) {
      result.putIfAbsent(PathKey(key), () => _toSubscriptionMap(map[key]));
    }
    return result;
  }

  Map<String, dynamic> _toKeyMap(Map<PathKey, dynamic> map) {
    final Map<String, dynamic> result = Map<String, dynamic>();
    for (PathKey key in map.keys) {
      result.putIfAbsent(key.key, () => _toKeyMap(map[key]));
    }
    return result;
  }

  void _subscribe() {
    _subscriptionQueue.whenComplete(() async {
      if (_updatedSubItems.isNotEmpty && _object != null) {
        final List<Future<void>> tasks = <Future<void>>[];
        for (PathKey key in _updatedSubItems.keys) {
          tasks.add(_subscribeSubItem(_object, key,
              _object.get<ParseObject>(key.key), _updatedSubItems[key]));
        }
        await Future.wait(tasks);
      }
    });
  }

  void _unsubscribe(Map<PathKey, dynamic> subscriptions) {
    for (PathKey key in subscriptions.keys) {
      if (_liveQuery != null && key.subscription != null) {
        _liveQuery.client.unSubscribe(key.subscription);
        key.subscription = null;
      }
      _unsubscribe(subscriptions[key]);
    }
  }

  Future<void> _subscribeSubItem(ParseObject parentObject, PathKey currentKey,
      ParseObject subObject, Map<PathKey, dynamic> path) async {
    if (_liveQuery != null && subObject != null) {
      final List<Future<void>> tasks = <Future<void>>[];
      for (PathKey key in path.keys) {
        tasks.add(_subscribeSubItem(
            subObject, key, subObject.get<ParseObject>(key.key), path[key]));
      }
      final QueryBuilder<ParseObject> queryBuilder =
          QueryBuilder<ParseObject>(subObject)
            ..whereEqualTo(keyVarObjectId, subObject.objectId);

      tasks.add(_liveQuery.client
          .subscribe(queryBuilder)
          .then((Subscription<ParseObject> subscription) {
        currentKey.subscription = subscription;
        subscription.on(LiveQueryEvent.update, (ParseObject newObject) async {
          _subscriptionQueue.whenComplete(() async {
            await ParseLiveList._loadIncludes(newObject,
                oldObject: subObject, paths: _toKeyMap(path));
            // ignore: deprecated_member_use_from_same_package
            parentObject.getObjectData()[currentKey.key] = newObject;
            if (!_streamController.isClosed) {
              _streamController
                  ?.add(_object?.clone(_object?.toJson(full: true)));
              //Resubscribe subitems
              // TODO(any): only resubscribe on changed pointers
              _unsubscribe(path);
              for (PathKey key in path.keys) {
                tasks.add(_subscribeSubItem(newObject, key,
                    newObject.get<ParseObject>(key.key), path[key]));
              }
            }
            await Future.wait(tasks);
          });
        });
      }));
      await Future.wait(tasks);
    }
  }

  set object(T value) {
    _loaded = true;
    _object = value;
    _unsubscribe(_updatedSubItems);
    _subscribe();
    // ignore: invalid_use_of_protected_member
    _streamController?.add(_object?.clone(_object?.toJson(full: true)));
  }

  bool get loaded => _loaded;

  void dispose() {
    _unsubscribe(_updatedSubItems);
    _streamController.close();
  }

  Future<void> reconnected() async {
    if (loaded) {
      _subscriptionQueue.whenComplete(() async {
        await _updateSubItems(_object, _updatedSubItems);
//        _streamController?.add(_object?.clone(_object?.toJson(full: true)));
      });
    }
  }

  List<String> _getIncludeList(Map<PathKey, dynamic> path) {
    final List<String> includes = <String>[];
    for (PathKey key in path.keys) {
      includes.add(key.key);
      includes.addAll(
          _getIncludeList(path[key]).map((String e) => '${key.key}.$e'));
    }
    return includes;
  }

  Future<void> _updateSubItems(
      ParseObject root, Map<PathKey, dynamic> path) async {
    final List<Future<void>> tasks = <Future<void>>[];
    for (PathKey key in path.keys) {
      ParseObject subObject = root.get<ParseObject>(key.key);
      if (subObject?.containsKey(keyVarUpdatedAt) == true) {
        final QueryBuilder<ParseObject> queryBuilder =
            QueryBuilder<ParseObject>(subObject)
              ..keysToReturn(<String>[keyVarUpdatedAt])
              ..whereEqualTo(keyVarObjectId, subObject.objectId);
        final ParseResponse parseResponse = await queryBuilder.query();
        if (parseResponse.success &&
            parseResponse.results.first.updatedAt != subObject.updatedAt) {
          queryBuilder.limiters.remove('keys');
          queryBuilder.includeObject(_getIncludeList(path[key]));
          final ParseResponse parseResponse = await queryBuilder.query();
          if (parseResponse.success) {
            subObject = parseResponse.result.first;
//            root.getObjectData()[key.key] = subObject;
            if (key.subscription?.eventCallbacks?.containsKey('update') ==
                true) {
              key.subscription.eventCallbacks['update'](subObject);
            }
//            key.subscription.eventCallbacks["update"](subObject);
            break;
          }
        }
      }
      tasks.add(_updateSubItems(subObject, path[key]));
    }
    await Future.wait(tasks);
  }
}

class PathKey {
  PathKey(this.key, {this.subscription});

  final String key;
  Subscription<ParseObject> subscription;
  @override
  String toString() {
    return 'PathKey(key: $key, subscription: ${subscription?.requestId})';
  }
}

abstract class ParseLiveListEvent<T extends ParseObject> {
  ParseLiveListEvent(this._index, this._object);

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

class ParseLiveListElementSnapshot<T extends ParseObject> {
  ParseLiveListElementSnapshot(
      {this.loadedData, this.error, this.preLoadedData});

  final T loadedData;
  final T preLoadedData;

  final ParseError error;

  bool get hasData => loadedData != null;

  bool get hasPreLoadedData => preLoadedData != null;

  bool get failed => error != null;
}
