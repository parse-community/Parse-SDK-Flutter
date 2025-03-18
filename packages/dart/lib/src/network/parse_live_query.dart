part of '../../parse_server_sdk.dart';

enum LiveQueryEvent { create, enter, update, leave, delete, error }

const String _printConstLiveQuery = 'LiveQuery: ';

class Subscription<T extends ParseObject> {
  Subscription(this.query, this.requestId, {T? copyObject}) {
    _copyObject = copyObject;
  }

  QueryBuilder<T> query;
  T? _copyObject;
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

  T? get copyObject {
    return _copyObject;
  }
}

enum LiveQueryClientEvent { connected, disconnected, userDisconnected }

class LiveQueryReconnectingController {
  LiveQueryReconnectingController(
      this._reconnect,
      this._eventStream,
      this.debug,
      ) {
    final ParseConnectivityProvider? connectivityProvider =
        ParseCoreData().connectivityProvider;
    if (connectivityProvider != null) {
      connectivityProvider.checkConnectivity().then(_connectivityChanged);
      connectivityProvider.connectivityStream.listen(_connectivityChanged);
    } else {
      print(
          'LiveQuery does not work, if there is no ParseConnectivityProvider provided.');
    }
    _eventStream.listen((LiveQueryClientEvent event) {
      switch (event) {
        case LiveQueryClientEvent.connected:
          _isConnected = true;
          _retryState = 0;
          _userDisconnected = false;
          break;
        case LiveQueryClientEvent.disconnected:
          _isConnected = false;
          _setReconnect();
          break;
        case LiveQueryClientEvent.userDisconnected:
          _userDisconnected = true;
          Timer? currentTimer = _currentTimer;
          if (currentTimer != null) {
            currentTimer.cancel();
            _currentTimer = null;
          }
          break;
      }

      if (debug) {
        print('$debugTag: $event');
      }
    });
    ParseCoreData().appResumedStream?.listen((void _) => _setReconnect());
  }

  static List<int> get retryInterval => ParseCoreData().liveListRetryIntervals;
  static const String debugTag = 'LiveQueryReconnectingController';

  final Function _reconnect;
  final Stream<LiveQueryClientEvent> _eventStream;
  final bool debug;

  int _retryState = 0;
  bool _isOnline = false;
  bool _isConnected = false;
  bool _userDisconnected = false;

  Timer? _currentTimer;

  void _connectivityChanged(ParseConnectivityResult state) {
    if (!_isOnline && state != ParseConnectivityResult.none) {
      _retryState = 0;
    }
    _isOnline = state != ParseConnectivityResult.none;
    if (state == ParseConnectivityResult.none) {
      _isConnected = false;
    }
    if (debug) {
      print('$debugTag: $state');
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
      if (debug) {
        print('$debugTag: Retry timer set to ${retryInterval[_retryState]}ms');
      }
      if (_retryState < retryInterval.length - 1) {
        _retryState++;
      }
    }
  }
}

class LiveQueryClient {
  factory LiveQueryClient() => _getInstance();

  LiveQueryClient._internal(this._liveQueryURL,
      {bool? debug, bool? autoSendSessionId}) {
    _clientEventStreamController = StreamController<LiveQueryClientEvent>();
    _clientEventStream =
        _clientEventStreamController.stream.asBroadcastStream();

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId = autoSendSessionId ?? ParseCoreData().autoSendSessionId;

    reconnectingController = LiveQueryReconnectingController(
            () => reconnect(userInitialized: false), getClientEventStream, _debug);
  }

  static LiveQueryClient get instance => _getInstance();
  static LiveQueryClient? _instance;

  static LiveQueryClient _getInstance({bool? debug, bool? autoSendSessionId}) {
    String? liveQueryURL = ParseCoreData().liveQueryURL;
    if (liveQueryURL == null) {
      assert(false,
      'liveQueryUrl is not set. For how to setup Live Queries, see https://github.com/parse-community/Parse-SDK-Flutter/tree/master/packages/flutter#live-queries.');
      liveQueryURL = "";
    } else {
      if (liveQueryURL.contains('https')) {
        liveQueryURL = liveQueryURL.replaceAll('https', 'wss');
      } else if (liveQueryURL.contains('http')) {
        liveQueryURL = liveQueryURL.replaceAll('http', 'ws');
      }
    }
    LiveQueryClient instance = _instance ??
        LiveQueryClient._internal(liveQueryURL,
            debug: debug, autoSendSessionId: autoSendSessionId);
    _instance ??= instance;
    return instance;
  }

  Stream<LiveQueryClientEvent> get getClientEventStream {
    return _clientEventStream;
  }

  parse_web_socket.WebSocket? _webSocket;
  late bool _debug;
  late bool _sendSessionId;
  WebSocketChannel? _channel;
  final String _liveQueryURL;
  bool _connecting = false;
  late StreamController<LiveQueryClientEvent> _clientEventStreamController;
  late Stream<LiveQueryClientEvent> _clientEventStream;
  StreamController<String>? chanelStream;
  late LiveQueryReconnectingController reconnectingController;

  final Map<int, Subscription> _requestSubscription = <int, Subscription>{};

  Future<void> reconnect({bool userInitialized = false}) async {
    await _connect(userInitialized: userInitialized);
    await _connectLiveQuery();
  }

  int readyState() {
    parse_web_socket.WebSocket? webSocket = _webSocket;
    if (webSocket != null) {
      return webSocket.readyState;
    }
    return parse_web_socket.WebSocket.connecting;
  }

  Future<dynamic> disconnect({bool userInitialized = false}) async {
    parse_web_socket.WebSocket? webSocket = _webSocket;
    if (webSocket != null &&
        webSocket.readyState == parse_web_socket.WebSocket.open) {
      if (_debug) {
        print('$_printConstLiveQuery: Socket closed');
      }
      await webSocket.close();
      _webSocket = null;
    }
    WebSocketChannel? channel = _channel;
    if (channel != null) {
      if (_debug) {
        print('$_printConstLiveQuery: close');
      }
      await channel.sink.close();
      _channel = null;
    }
    _requestSubscription.values.toList().forEach((Subscription subscription) {
      subscription._enabled = false;
    });
    _connecting = false;
    if (userInitialized) {
      _clientEventStreamController.sink
          .add(LiveQueryClientEvent.userDisconnected);
    }
  }

  Future<Subscription<T>> subscribe<T extends ParseObject>(
      QueryBuilder<T> query,
      {T? copyObject}) async {
    if (_webSocket == null) {
      await _clientEventStream.any((LiveQueryClientEvent event) =>
      event == LiveQueryClientEvent.connected);
    }
    final int requestId = _requestIdGenerator();
    final Subscription<T> subscription =
    Subscription<T>(query, requestId, copyObject: copyObject);
    _requestSubscription[requestId] = subscription;
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
    WebSocketChannel? channel = _channel;
    if (channel != null) {
      if (_debug) {
        print('$_printConstLiveQuery: UnsubscribeMessage: $unsubscribeMessage');
      }
      channel.sink.add(jsonEncode(unsubscribeMessage));
      subscription._enabled = false;
      _requestSubscription.remove(subscription.requestId);
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
      parse_web_socket.WebSocket webSocket =
      await parse_web_socket.WebSocket.connect(_liveQueryURL);
      _webSocket = webSocket;
      _connecting = false;
      if (webSocket.readyState == parse_web_socket.WebSocket.open) {
        if (_debug) {
          print('$_printConstLiveQuery: Socket opened');
        }
      } else {
        if (_debug) {
          print('$_printConstLiveQuery: Error when connection client');
        }
        return Future<void>.value(null);
      }
      WebSocketChannel channel = webSocket.createWebSocketChannel();
      _channel = channel;
      channel.stream.listen((dynamic message) {
        _handleMessage(message);

        chanelStream?.sink.add(message);
      }, onDone: () {
        _clientEventStreamController.sink
            .add(LiveQueryClientEvent.disconnected);
        if (_debug) {
          print('$_printConstLiveQuery: Done');
        }
      }, onError: (Object error) {
        _clientEventStreamController.sink
            .add(LiveQueryClientEvent.disconnected);
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
      _clientEventStreamController.sink.add(LiveQueryClientEvent.disconnected);
      if (_debug) {
        print('$_printConstLiveQuery: Error: ${e.toString()}');
      }
      return handleException(e, ParseApiRQ.liveQuery, _debug, 'LiveQuery');
    }
  }

  Future<void> _connectLiveQuery() async {
    WebSocketChannel? channel = _channel;
    if (channel == null) {
      return;
    }
    //The connect message is sent from a client to the LiveQuery server.
    //It should be the first message sent from a client after the WebSocket connection is established.
    final Map<String, String> connectMessage = <String, String>{
      'op': 'connect',
      'applicationId': ParseCoreData().applicationId
    };

    if (_sendSessionId) {
      String? sessionId = ParseCoreData().sessionId;
      if (sessionId != null) {
        connectMessage['sessionToken'] = sessionId;
      }
    }

    String? clientKey = ParseCoreData().clientKey;
    if (clientKey != null) {
      connectMessage['clientKey'] = clientKey;
    }

    String? masterKey = ParseCoreData().masterKey;
    if (masterKey != null) {
      connectMessage['masterKey'] = masterKey;
    }

    String? parseInstallation =
        (await ParseInstallation.currentInstallation()).installationId;
    if (parseInstallation != null) {
      connectMessage['installationId'] = parseInstallation;
    }

    if (_debug) {
      print('$_printConstLiveQuery: ConnectMessage: $connectMessage');
    }
    channel.sink.add(jsonEncode(connectMessage));
  }

  void _subscribeLiveQuery(Subscription subscription) {
    if (subscription._enabled) {
      return;
    }
    subscription._enabled = true;
    final QueryBuilder query = subscription.query;
    final List<String>? keysToReturn = query.limiters['keys']?.split(',');
    query.limiters.clear(); //Remove limits in LiveQuery
    final String where = query.buildQuery().replaceAll('where=', '');

    //Convert where condition to Map
    Map<String, dynamic> whereMap = <String, dynamic>{};
    if (where != '') {
      whereMap = json.decode(where);
    }

    final Map<String, dynamic> subscribeMessage = <String, dynamic>{
      'op': 'subscribe',
      'requestId': subscription.requestId,
      'query': <String, dynamic>{
        'className': query.object.parseClassName,
        'where': whereMap,
        if (keysToReturn != null && keysToReturn.isNotEmpty)
          'fields': keysToReturn
      }
    };
    if (_sendSessionId && ParseCoreData().sessionId != null) {
      subscribeMessage['sessionToken'] = ParseCoreData().sessionId;
    }

    if (_debug) {
      print('$_printConstLiveQuery: SubscribeMessage: $subscribeMessage');
    }

    _channel?.sink.add(jsonEncode(subscribeMessage));
  }

  void _handleMessage(String message) {
    if (_debug) {
      print('$_printConstLiveQuery: Listen: $message');
    }

    final Map<String, dynamic> actionData = jsonDecode(message);

    Subscription? subscription;
    if (actionData.containsKey('op') && actionData['op'] == 'connected') {
      print('Re subscription:$_requestSubscription');

      _requestSubscription.values.toList().forEach((Subscription subscription) {
        _subscribeLiveQuery(subscription);
      });
      _clientEventStreamController.sink.add(LiveQueryClientEvent.connected);
      return;
    }
    if (actionData.containsKey('requestId')) {
      subscription = _requestSubscription[actionData['requestId']];
    }
    if (subscription == null) {
      return;
    }
    if (subscription.eventCallbacks.containsKey(actionData['op'])) {
      Function? eventCallback = subscription.eventCallbacks[actionData['op']];
      if (eventCallback != null) {
        if (actionData.containsKey('object')) {
          final Map<String, dynamic> map = actionData['object'];
          final String? className = map['className'];
          if (className != null) {
            if (className == keyClassUser) {
              eventCallback((subscription.copyObject ??
                  ParseCoreData.instance.createParseUser(null, null, null))
                  .fromJson(map));
            } else {
              eventCallback((subscription.copyObject ??
                  ParseCoreData.instance.createObject(className))
                  .fromJson(map));
            }
          }
        } else {
          eventCallback(actionData);
        }
      }
    }
  }
}

class LiveQuery {
  LiveQuery({bool? debug, bool? autoSendSessionId}) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId = autoSendSessionId ?? ParseCoreData().autoSendSessionId;
    client = LiveQueryClient._getInstance(
        debug: _debug, autoSendSessionId: _sendSessionId);
  }

  bool? _debug;
  bool? _sendSessionId;
  late LiveQueryClient client;
}