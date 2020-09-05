part of flutter_parse_sdk;

enum LiveQueryEvent { create, enter, update, leave, delete, error }

const String _printConstLiveQuery = 'LiveQuery: ';

class Subscription<T extends ParseObject> {
  Subscription(this.query, this.requestId, {T copyObject}) {
    _copyObject = copyObject;
  }

  QueryBuilder<T> query;
  T _copyObject;
  int requestId;
  bool _enabled = false;
  final List<String> _liveQueryEvent = <String>[
    'create',
    'enter',
    'update',
    'leave',
    'delete',
    'error'
  ];
  Map<String, Function> eventCallbacks = <String, Function>{};
  void on(LiveQueryEvent op, Function callback) {
    eventCallbacks[_liveQueryEvent[op.index]] = callback;
  }

  T get copyObject {
    return _copyObject;
  }
}

enum LiveQueryClientEvent { CONNECTED, DISCONNECTED, USER_DISCONNECTED }

class LiveQueryReconnectingController {
  LiveQueryReconnectingController(
    this._reconnect,
    this._eventStream,
    this.debug,
  ) {
    final ParseConnectivityProvider connectivityProvider =
        ParseCoreData().connectivityProvider;
    if (connectivityProvider != null) {
      connectivityProvider.checkConnectivity().then(_connectivityChanged);
      connectivityProvider.connectivityStream.listen(_connectivityChanged);
    } else {
      print(
          'LiveQuery does not work, if there is ParseConnectivityProvider provided.');
    }
    _eventStream.listen((LiveQueryClientEvent event) {
      switch (event) {
        case LiveQueryClientEvent.CONNECTED:
          _isConnected = true;
          _retryState = 0;
          _userDisconnected = false;
          break;
        case LiveQueryClientEvent.DISCONNECTED:
          _isConnected = false;
          _setReconnect();
          break;
        case LiveQueryClientEvent.USER_DISCONNECTED:
          _userDisconnected = true;
          if (_currentTimer != null) {
            _currentTimer.cancel();
            _currentTimer = null;
          }
          break;
      }

      if (debug) {
        print('$DEBUG_TAG: $event');
      }
    });
    ParseCoreData().appResumedStream?.listen((void _) => _setReconnect());
  }

  static List<int> get retryInterval => ParseCoreData().liveListRetryIntervals;
  static const String DEBUG_TAG = 'LiveQueryReconnectingController';

  final Function _reconnect;
  final Stream<LiveQueryClientEvent> _eventStream;
  final bool debug;

  int _retryState = 0;
  bool _isOnline = false;
  bool _isConnected = false;
  bool _userDisconnected = false;

  Timer _currentTimer;

  void _connectivityChanged(ParseConnectivityResult state) {
    if (!_isOnline && state != ParseConnectivityResult.none) {
      _retryState = 0;
    }
    _isOnline = state != ParseConnectivityResult.none;
    if(state == ParseConnectivityResult.none) {
      _isConnected = false;
    }
    if (debug) {
      print('$DEBUG_TAG: $state');
    }
    _setReconnect();
  }

  void _setReconnect() {
    if (_isOnline &&
        !_isConnected &&
        _currentTimer == null &&
        !_userDisconnected &&
        retryInterval[_retryState] >= 0) {
      _currentTimer =
          Timer(Duration(milliseconds: retryInterval[_retryState]), () {
        _currentTimer = null;
        _reconnect();
      });
      if (debug)
        print('$DEBUG_TAG: Retrytimer set to ${retryInterval[_retryState]}ms');
      if (_retryState < retryInterval.length - 1) {
        _retryState++;
      }
    }
  }
}

class LiveQueryClient {
  factory LiveQueryClient() => _getInstance();
  LiveQueryClient._internal(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
    _clientEventStreamController = StreamController<LiveQueryClientEvent>();
    _clientEventStream =
        _clientEventStreamController.stream.asBroadcastStream();

    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId =
        autoSendSessionId ?? ParseCoreData().autoSendSessionId ?? true;
    _liveQueryURL = _client.data.liveQueryURL;
    if (_liveQueryURL.contains('https')) {
      _liveQueryURL = _liveQueryURL.replaceAll('https', 'wss');
    } else if (_liveQueryURL.contains('http')) {
      _liveQueryURL = _liveQueryURL.replaceAll('http', 'ws');
    }

    reconnectingController = LiveQueryReconnectingController(
        () => reconnect(userInitialized: false), getClientEventStream, _debug);
  }
  static LiveQueryClient get instance => _getInstance();
  static LiveQueryClient _instance;
  static LiveQueryClient _getInstance(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
    _instance ??= LiveQueryClient._internal(
        debug: debug, client: client, autoSendSessionId: autoSendSessionId);
    return _instance;
  }

  Stream<LiveQueryClientEvent> get getClientEventStream {
    return _clientEventStream;
  }

  parse_web_socket.WebSocket _webSocket;
  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  WebSocketChannel _channel;
  String _liveQueryURL;
  bool _connecting = false;
  StreamController<LiveQueryClientEvent> _clientEventStreamController;
  Stream<LiveQueryClientEvent> _clientEventStream;
  LiveQueryReconnectingController reconnectingController;

  final Map<int, Subscription> _requestSubScription = <int, Subscription>{};

  Future<void> reconnect({bool userInitialized = false}) async {
    await _connect(userInitialized: userInitialized);
    _connectLiveQuery();
  }

  int readyState() {
    if (_webSocket != null) {
      return _webSocket.readyState;
    }
    return parse_web_socket.WebSocket.CONNECTING;
  }

  Future<dynamic> disconnect({bool userInitialized = false}) async {
    if (_webSocket != null &&
        _webSocket.readyState == parse_web_socket.WebSocket.OPEN) {
      if (_debug) {
        print('$_printConstLiveQuery: Socket closed');
      }
      await _webSocket.close();
      _webSocket = null;
    }
    if (_channel != null && _channel.sink != null) {
      if (_debug) {
        print('$_printConstLiveQuery: close');
      }
      await _channel.sink.close();
      _channel = null;
    }
    _requestSubScription.values.toList().forEach((Subscription subscription) {
      subscription._enabled = false;
    });
    _connecting = false;
    if (userInitialized)
      _clientEventStreamController.sink
          .add(LiveQueryClientEvent.USER_DISCONNECTED);
  }

  Future<Subscription<T>> subscribe<T extends ParseObject>(
      QueryBuilder<T> query,
      {T copyObject}) async {
    if (_webSocket == null) {
      await _clientEventStream.any((LiveQueryClientEvent event) =>
          event == LiveQueryClientEvent.CONNECTED);
    }
    final int requestId = _requestIdGenerator();
    final Subscription<T> subscription =
        Subscription<T>(query, requestId, copyObject: copyObject);
    _requestSubScription[requestId] = subscription;
    //After a client connects to the LiveQuery server,
    //it can send a subscribe message to subscribe a ParseQuery.
    _subscribeLiveQuery(subscription);
    return subscription;
  }

  void unSubscribe<T extends ParseObject>(Subscription<T> subscription) {
    //Mount message for Unsubscribe
    final Map<String, dynamic> unsubscribeMessage = <String, dynamic>{
      'op': 'unsubscribe',
      'requestId': subscription.requestId,
    };
    if (_channel != null && _channel.sink != null) {
      if (_debug) {
        print('$_printConstLiveQuery: UnsubscribeMessage: $unsubscribeMessage');
      }
      _channel.sink.add(jsonEncode(unsubscribeMessage));
      subscription._enabled = false;
      _requestSubScription.remove(subscription.requestId);
    }
  }

  static int _requestIdCount = 1;

  int _requestIdGenerator() {
    return _requestIdCount++;
  }

  Future<dynamic> _connect({bool userInitialized = false}) async {
    if (_connecting) {
      print('already connecting');
      return Future<void>.value(null);
    }
    await disconnect(userInitialized: userInitialized);
    _connecting = true;

    try {
      _webSocket = await parse_web_socket.WebSocket.connect(_liveQueryURL);
      _connecting = false;
      if (_webSocket != null &&
          _webSocket.readyState == parse_web_socket.WebSocket.OPEN) {
        if (_debug) {
          print('$_printConstLiveQuery: Socket opened');
        }
      } else {
        if (_debug) {
          print('$_printConstLiveQuery: Error when connection client');
        }
        return Future<void>.value(null);
      }
      _channel = _webSocket.createWebSocketChannel();
      _channel.stream.listen((dynamic message) {
        _handleMessage(message);
      }, onDone: () {
        _clientEventStreamController.sink
            .add(LiveQueryClientEvent.DISCONNECTED);
        if (_debug) {
          print('$_printConstLiveQuery: Done');
        }
      }, onError: (Object error) {
        _clientEventStreamController.sink
            .add(LiveQueryClientEvent.DISCONNECTED);
        if (_debug) {
          print(
              '$_printConstLiveQuery: Error: ${error.runtimeType.toString()}');
        }
        return Future<ParseResponse>.value(handleException(
            Exception(error),
            ParseApiRQ.liveQuery,
            _debug,
            !parseIsWeb ? 'IOWebSocketChannel' : 'HtmlWebSocketChannel'));
      });
    } on Exception catch (e) {
      _connecting = false;
      _clientEventStreamController.sink.add(LiveQueryClientEvent.DISCONNECTED);
      if (_debug) {
        print('$_printConstLiveQuery: Error: ${e.toString()}');
      }
      return handleException(e, ParseApiRQ.liveQuery, _debug, 'LiveQuery');
    }
  }

  void _connectLiveQuery() {
    if (_channel == null || _channel.sink == null) {
      return;
    }
    //The connect message is sent from a client to the LiveQuery server.
    //It should be the first message sent from a client after the WebSocket connection is established.
    final Map<String, String> connectMessage = <String, String>{
      'op': 'connect',
      'applicationId': _client.data.applicationId
    };

    if (_sendSessionId && _client.data.sessionId != null) {
      connectMessage['sessionToken'] = _client.data.sessionId;
    }

    if (_client.data.clientKey != null)
      connectMessage['clientKey'] = _client.data.clientKey;
    if (_client.data.masterKey != null)
      connectMessage['masterKey'] = _client.data.masterKey;

    if (_debug) {
      print('$_printConstLiveQuery: ConnectMessage: $connectMessage');
    }
    _channel.sink.add(jsonEncode(connectMessage));
  }

  void _subscribeLiveQuery(Subscription subscription) {
    if (subscription._enabled) {
      return;
    }
    subscription._enabled = true;
    final QueryBuilder query = subscription.query;
    final List<String> keysToReturn = query.limiters['keys']?.split(',');
    query.limiters.clear(); //Remove limits in LiveQuery
    final String _where = query.buildQuery().replaceAll('where=', '');

    //Convert where condition to Map
    Map<String, dynamic> _whereMap = Map<String, dynamic>();
    if (_where != '') {
      _whereMap = json.decode(_where);
    }

    final Map<String, dynamic> subscribeMessage = <String, dynamic>{
      'op': 'subscribe',
      'requestId': subscription.requestId,
      'query': <String, dynamic>{
        'className': query.object.parseClassName,
        'where': _whereMap,
        if (keysToReturn != null && keysToReturn.isNotEmpty)
          'fields': keysToReturn
      }
    };
    if (_sendSessionId && _client.data.sessionId != null) {
      subscribeMessage['sessionToken'] = _client.data.sessionId;
    }

    if (_debug) {
      print('$_printConstLiveQuery: SubscribeMessage: $subscribeMessage');
    }

    _channel.sink.add(jsonEncode(subscribeMessage));
  }

  void _handleMessage(String message) {
    if (_debug) {
      print('$_printConstLiveQuery: Listen: $message');
    }

    final Map<String, dynamic> actionData = jsonDecode(message);

    Subscription subscription;
    if (actionData.containsKey('op') && actionData['op'] == 'connected') {
      print('ReSubScription:$_requestSubScription');

      _requestSubScription.values.toList().forEach((Subscription subcription) {
        _subscribeLiveQuery(subcription);
      });
      _clientEventStreamController.sink.add(LiveQueryClientEvent.CONNECTED);
      return;
    }
    if (actionData.containsKey('requestId')) {
      subscription = _requestSubScription[actionData['requestId']];
    }
    if (subscription == null) {
      return;
    }
    if (subscription.eventCallbacks.containsKey(actionData['op'])) {
      if (actionData.containsKey('object')) {
        final Map<String, dynamic> map = actionData['object'];
        final String className = map['className'];
        if (className == keyClassUser) {
          subscription.eventCallbacks[actionData['op']](
              (subscription.copyObject ??
                      ParseCoreData.instance.createParseUser(null, null, null))
                  .fromJson(map));
        } else {
          subscription.eventCallbacks[actionData['op']](
              (subscription.copyObject ??
                      ParseCoreData.instance.createObject(className))
                  .fromJson(map));
        }
      } else {
        subscription.eventCallbacks[actionData['op']](actionData);
      }
    }
  }
}

class LiveQuery {
  LiveQuery({bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId =
        autoSendSessionId ?? ParseCoreData().autoSendSessionId ?? true;
    this.client = LiveQueryClient._getInstance(
        client: _client, debug: _debug, autoSendSessionId: _sendSessionId);
  }

  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  Subscription _latestSubscription;
  LiveQueryClient client;

  @deprecated
  Future<dynamic> subscribe(QueryBuilder query) async {
    _latestSubscription = await client.subscribe(query);
    return _latestSubscription;
  }

  @deprecated
  Future<void> unSubscribe() async {
    client.unSubscribe(_latestSubscription);
  }

  @deprecated
  void on(LiveQueryEvent op, Function callback) {
    _latestSubscription.on(op, callback);
  }
}
