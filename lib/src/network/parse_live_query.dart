import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity/connectivity.dart';

import '../../parse_server_sdk.dart';

enum LiveQueryEvent { create, enter, update, leave, delete, error }

const String _printConstLiveQuery = 'LiveQuery: ';

class Subscription {
  Subscription(this.query, this.requestId);
  QueryBuilder query;
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
}

class Client with WidgetsBindingObserver {
  factory Client() => _getInstance();
  Client._internal(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
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
    Connectivity().onConnectivityChanged
        .listen((ConnectivityResult connectivityResult) {
      print('onConnectivityChanged:$connectivityResult');
      if (connectivityResult != ConnectivityResult.none) {
        reconnect();
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }
  static Client get instance => _getInstance();
  static Client _instance;
  static Client _getInstance(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
    _instance ??= Client._internal(
        debug: debug, client: client, autoSendSessionId: autoSendSessionId);
    return _instance;
  }

  WebSocket _webSocket;
  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  WebSocketChannel _channel;
  String _liveQueryURL;
  bool _userDisconnected = false;
  bool _connecting = false;

  final Map<int, Subscription> _requestSubScription = <int, Subscription>{};

  Future<void> reconnect() async {
    await _connect();
    _connectLiveQuery();
  }

  int readyState() {
    if (_webSocket != null) {
      return _webSocket.readyState;
    }
    return WebSocket.connecting;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed: 
        reconnect();
        break;
      default:
        break;
    }
  }

  Future<dynamic> disconnect() async {
    if (_webSocket != null && _webSocket.readyState == WebSocket.open) {
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
    _requestSubScription.values.toList().forEach((Subscription subcription) {
      subcription._enabled = false;
    });
    _userDisconnected = true;
    _connecting = false;
  }

  Future<Subscription> subscribe(QueryBuilder query) async {
    if (_webSocket == null) {
      await reconnect();
    }
    final int requestId = _requestIdGenerator();
    final Subscription subscription = Subscription(query, requestId);
    _requestSubScription[requestId] = subscription;
    //After a client connects to the LiveQuery server,
    //it can send a subscribe message to subscribe a ParseQuery.
    _subscribeLiveQuery(subscription);
    return subscription;
  }

  void unSubscribe(Subscription subscription) {
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

  Future<dynamic> _connect() async {
    if (_connecting) {
      print('already connecting');
      return Future<void>.value(null);
    }
    await disconnect();
    _connecting = true;
    _userDisconnected = false;

    try {
      _webSocket = await WebSocket.connect(_liveQueryURL);
      if (_webSocket != null && _webSocket.readyState == WebSocket.open) {
        if (_debug) {
          print('$_printConstLiveQuery: Socket opened');
        }
      } else {
        if (_debug) {
          print('$_printConstLiveQuery: Error when connection client');
        }
        return Future<void>.value(null);
      }
      _channel = IOWebSocketChannel(_webSocket);
      _channel.stream.listen((dynamic message) {
        _handleMessage(message);
      }, onDone: () {
        if (!_userDisconnected) {
          reconnect();
        }
        if (_debug) {
          print('$_printConstLiveQuery: Done');
        }
      }, onError: (Object error) {
        if (!_userDisconnected) {
          reconnect();
        }
        if (_debug) {
          print(
              '$_printConstLiveQuery: Error: ${error.runtimeType.toString()}');
        }
        return Future<ParseResponse>.value(handleException(Exception(error),
            ParseApiRQ.liveQuery, _debug, 'IOWebSocketChannel'));
      });
    } on Exception catch (e) {
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
    QueryBuilder query = subscription.query;
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
      _connecting = false;
      print('ReSubScription:$_requestSubScription');
      _requestSubScription.values.toList().forEach((Subscription subcription) {
        _subscribeLiveQuery(subcription);
      });
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
        if (className == '_User') {
          subscription.eventCallbacks[actionData['op']](
              ParseUser(null, null, null).fromJson(map));
        } else {
          subscription.eventCallbacks[actionData['op']](
              ParseObject(className).fromJson(map));
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
    this.client = Client._getInstance(
        client: _client, debug: _debug, autoSendSessionId: _sendSessionId);
  }

  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  Subscription _latestSubscription;
  Client client;

  // ignore: always_specify_types
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
