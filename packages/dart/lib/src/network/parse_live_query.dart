part of '../../parse_server_sdk.dart';

enum LiveQueryEvent { create, enter, update, leave, delete, error }

const String _printConstLiveQuery = 'LiveQuery: ';

class Subscription<T extends ParseObject> {
  Subscription(this.query, this.requestId, {T? copyObject}) {
    _copyObject = copyObject;
    // Captured up front because _subscribeLiveQuery clears query.limiters to
    // strip the limits LiveQuery does not accept. That is destructive, so by
    // the time the subscription is re-sent on reconnect the 'keys' limiter is
    // gone and the payload would silently omit 'fields' — the server would
    // then push full objects instead of the selected columns.
    _keysToReturn = query.limiters['keys']?.split(',');
  }

  QueryBuilder<T> query;
  T? _copyObject;
  int requestId;
  bool _enabled = false;

  /// The `keys` limiter as it was when this subscription was created, so every
  /// subscribe message for it carries the same `fields` list.
  List<String>? _keysToReturn;
  final List<String> _liveQueryEvent = <String>[
    'create',
    'enter',
    'update',
    'leave',
    'delete',
    'error',
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
        'LiveQuery does not work, if there is no ParseConnectivityProvider provided.',
      );
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
      _currentTimer = Timer(
        Duration(milliseconds: retryInterval[_retryState]),
        () {
          _currentTimer = null;
          _reconnect();
        },
      );
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

  LiveQueryClient._internal(
    this._liveQueryURL, {
    bool? debug,
    bool? autoSendSessionId,
  }) {
    _clientEventStreamController = StreamController<LiveQueryClientEvent>();
    _clientEventStream = _clientEventStreamController.stream
        .asBroadcastStream();

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId = autoSendSessionId ?? ParseCoreData().autoSendSessionId;

    reconnectingController = LiveQueryReconnectingController(
      () => reconnect(userInitialized: false),
      getClientEventStream,
      _debug,
    );
  }

  static LiveQueryClient get instance => _getInstance();
  static LiveQueryClient? _instance;

  static LiveQueryClient _getInstance({bool? debug, bool? autoSendSessionId}) {
    String? liveQueryURL = ParseCoreData().liveQueryURL;
    if (liveQueryURL == null) {
      assert(
        false,
        'liveQueryUrl is not set. For how to setup Live Queries, see https://github.com/parse-community/Parse-SDK-Flutter/tree/master/packages/flutter#live-queries.',
      );
      liveQueryURL = "";
    } else {
      if (liveQueryURL.contains('https')) {
        liveQueryURL = liveQueryURL.replaceAll('https', 'wss');
      } else if (liveQueryURL.contains('http')) {
        liveQueryURL = liveQueryURL.replaceAll('http', 'ws');
      }
    }
    LiveQueryClient instance =
        _instance ??
        LiveQueryClient._internal(
          liveQueryURL,
          debug: debug,
          autoSendSessionId: autoSendSessionId,
        );
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

  /// Whether the LiveQuery `connect` handshake has been acknowledged by the
  /// server (a `connected` op was received on the current socket). A raw socket
  /// being open ([_webSocket] != null) is NOT enough — subscribing before this
  /// is true yields "Can not find this client" and leaves the subscription
  /// stuck. Reset to false whenever the socket drops.
  bool _connected = false;
  late StreamController<LiveQueryClientEvent> _clientEventStreamController;
  late Stream<LiveQueryClientEvent> _clientEventStream;
  StreamController<String>? chanelStream;
  late LiveQueryReconnectingController reconnectingController;

  final Map<int, Subscription> _requestSubscription = <int, Subscription>{};

  /// Coalesces concurrent reconnects onto one in-flight attempt.
  ///
  /// `_connect` guards on `_connecting`, but only sets it AFTER `await
  /// disconnect(...)` — and `disconnect` itself clears it — so two callers can
  /// both pass the guard while the first is suspended at that await and open
  /// two sockets. `subscribe` makes this easy to hit, because it starts a
  /// reconnect without awaiting it, so a burst of subscriptions all reach here
  /// before any connection exists.
  Future<void>? _reconnectFuture;

  Future<void> reconnect({bool userInitialized = false}) {
    final Future<void>? inFlight = _reconnectFuture;
    if (inFlight != null) {
      return inFlight;
    }
    late final Future<void> attempt;
    attempt = _reconnect(userInitialized: userInitialized).whenComplete(() {
      if (identical(_reconnectFuture, attempt)) {
        _reconnectFuture = null;
      }
    });
    _reconnectFuture = attempt;
    return attempt;
  }

  Future<void> _reconnect({bool userInitialized = false}) async {
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
    _connected = false;
    if (userInitialized) {
      _clientEventStreamController.sink.add(
        LiveQueryClientEvent.userDisconnected,
      );
    }
  }

  Future<Subscription<T>> subscribe<T extends ParseObject>(
    QueryBuilder<T> query, {
    T? copyObject,
  }) async {
    final int requestId = _requestIdGenerator();
    final Subscription<T> subscription = Subscription<T>(
      query,
      requestId,
      copyObject: copyObject,
    );
    // Always register the subscription so the `connected` handler can (re)send
    // it. Only send the subscribe now if the LiveQuery handshake is already
    // acknowledged — sending before that yields "Can not find this client" and,
    // because _subscribeLiveQuery marks it _enabled, the connected handler would
    // then skip it, leaving it permanently unregistered.
    _requestSubscription[requestId] = subscription;
    if (_connected) {
      //After a client connects to the LiveQuery server,
      //it can send a subscribe message to subscribe a ParseQuery.
      _subscribeLiveQuery(subscription);
    } else if (_webSocket == null && !_connecting) {
      // No live connection yet — open one. The `connected` handler then sends
      // this (and every other pending) subscription.
      reconnect();
    }
    return subscription;
  }

  void unSubscribe<T extends ParseObject>(Subscription<T> subscription) {
    //Mount message for Unsubscribe
    final Map<String, dynamic> unsubscribeMessage = <String, dynamic>{
      'op': 'unsubscribe',
      'requestId': subscription.requestId,
    };
    // Drop the LOCAL state FIRST, unconditionally. Telling the server is
    // best-effort — it only has a socket to hear it on, and a non-null channel
    // does not prove the sink still accepts writes. Both used to sit inside the
    // channel guard, so unsubscribing while disconnected (app backgrounded,
    // socket dropped) was a silent no-op: the entry stayed in
    // _requestSubscription and was resurrected by the re-subscribe on
    // reconnect. Callers that cancel-and-resubscribe therefore accumulated a
    // duplicate per cycle, and every event fired their handler once per
    // accumulated subscription. Ordering the removal first means a throwing
    // sink cannot resurrect it either.
    subscription._enabled = false;
    _requestSubscription.remove(subscription.requestId);

    WebSocketChannel? channel = _channel;
    if (channel != null) {
      if (_debug) {
        print('$_printConstLiveQuery: UnsubscribeMessage: $unsubscribeMessage');
      }
      try {
        channel.sink.add(jsonEncode(unsubscribeMessage));
      } catch (e) {
        if (_debug) {
          print('$_printConstLiveQuery: Unsubscribe send failed: $e');
        }
      }
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
        // Drop the handle for a socket that never opened. `subscribe` only
        // starts recovery when _webSocket == null, so leaving this assigned
        // parks every later subscription behind a socket that will never
        // complete a handshake.
        _webSocket = null;
        _connected = false;
        // Plain `null` rather than a Future: this is an async body, so
        // returning a Future inside the try block trips
        // unawaited_return_in_try_block on newer analyzers.
        return null;
      }
      WebSocketChannel channel = webSocket.createWebSocketChannel();
      _channel = channel;
      channel.stream.listen(
        (dynamic message) {
          _handleMessage(message);

          chanelStream?.sink.add(message);
        },
        onDone: () {
          // Clear the handles for THIS socket, so the _webSocket == null check
          // in subscribe can trigger a fresh connection. Guarded on identity so
          // a reconnect that already swapped in a new socket is left alone.
          if (identical(_webSocket, webSocket)) {
            _webSocket = null;
            _channel = null;
          }
          _connected = false;
          _clientEventStreamController.sink.add(
            LiveQueryClientEvent.disconnected,
          );
          if (_debug) {
            print('$_printConstLiveQuery: Done');
          }
        },
        onError: (Object error) {
          if (identical(_webSocket, webSocket)) {
            _webSocket = null;
            _channel = null;
          }
          _connected = false;
          _clientEventStreamController.sink.add(
            LiveQueryClientEvent.disconnected,
          );
          if (_debug) {
            print(
              '$_printConstLiveQuery: Error: ${error.runtimeType.toString()}',
            );
          }
          return Future<ParseResponse>.value(
            handleException(
              Exception(error),
              ParseApiRQ.liveQuery,
              _debug,
              !parseIsWeb ? 'IOWebSocketChannel' : 'HtmlWebSocketChannel',
            ),
          );
        },
      );
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
      'applicationId': ParseCoreData().applicationId,
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
    final List<String>? keysToReturn = subscription._keysToReturn;
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
          'fields': keysToReturn,
      },
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
      // The handshake is acknowledged — safe to (re)send subscribes now.
      _connected = true;
      _requestSubscription.values.toList().forEach((Subscription subscription) {
        // This is a fresh connection, so the server has no record of any prior
        // subscribe. Force a re-send by clearing _enabled first — otherwise the
        // guard in _subscribeLiveQuery skips already-enabled subscriptions and
        // they never re-register after a (re)connect.
        subscription._enabled = false;
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
              eventCallback(
                (subscription.copyObject ??
                        ParseCoreData.instance.createParseUser(
                          null,
                          null,
                          null,
                        ))
                    .fromJson(map),
              );
            } else {
              eventCallback(
                (subscription.copyObject ??
                        ParseCoreData.instance.createObject(className))
                    .fromJson(map),
              );
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
      debug: _debug,
      autoSendSessionId: _sendSessionId,
    );
  }

  bool? _debug;
  bool? _sendSessionId;
  late LiveQueryClient client;
}
