import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../parse_server_sdk.dart';

enum LiveQueryEvent { create, enter, update, leave, delete, error }

const String _printConstLiveQuery = 'LiveQuery: ';

class Subscription {
  Subscription(this.query, this.requestId);
  QueryBuilder query;
  int requestId;
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

class Client {
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
  Subscription _latestSubscription;

  final Map<int, Subscription> _requestSubScription = <int, Subscription>{};

  Future<void> reconnect() async {
    await _connect();
    _connectLiveQuery();
    _requestSubScription.values.toList().forEach((Subscription subcription) {
      _subscribeLiveQuery(subcription);
    });
  }

  Future<dynamic> disconnect() async {
    _requestSubScription.clear();
    if (_webSocket != null && _webSocket.readyState == WebSocket.open) {
      if (_debug) {
        print('$_printConstLiveQuery: Socket closed');
      }
      await _webSocket.close();
    }
    if (_channel != null && _channel.sink != null) {
      if (_debug) {
        print('$_printConstLiveQuery: close');
      }
      return _channel.sink.close();
    } else {
      if (_debug) {
        print('$_printConstLiveQuery: close failed, channel or sink is null');
      }
      return Future<void>.value(null);
    }
  }

  Future<Subscription> subscribe(QueryBuilder query) async {
    final String _className = query.object.parseClassName;
    if (_webSocket == null) {
      await reconnect();
    }
    final int requestId = _requestIdGenerator();
    final Subscription subscription = Subscription(query, requestId);
    _requestSubScription[requestId] = subscription;
    //After a client connects to the LiveQuery server,
    //it can send a subscribe message to subscribe a ParseQuery.
    _subscribeLiveQuery(subscription);
    _latestSubscription = subscription;
    _channel.stream.listen((dynamic message) {
      _handleMessage(message);
    }, onDone: () {
      if (_debug) {
        print('$_printConstLiveQuery: Done');
      }
    }, onError: (Object error) {
      if (_debug) {
        print('$_printConstLiveQuery: Error: ${error.runtimeType.toString()}');
      }
      return Future<ParseResponse>.value(handleException(
          Exception(error), ParseApiRQ.liveQuery, _debug, _className));
    });
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
      _requestSubScription.remove(subscription.requestId);
    }
  }

  static int _requestIdCount = 1;

  int _requestIdGenerator() {
    return _requestIdCount++;
  }

  Future<dynamic> _connect() async {
    String _liveQueryURL = _client.data.liveQueryURL;
    if (_liveQueryURL.contains('https')) {
      _liveQueryURL = _liveQueryURL.replaceAll('https', 'wss');
    } else if (_liveQueryURL.contains('http')) {
      _liveQueryURL = _liveQueryURL.replaceAll('http', 'ws');
    }
    await disconnect();
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
    try {
      _channel = IOWebSocketChannel(_webSocket);
    } on Exception catch (e) {
      if (_debug) {
        print('$_printConstLiveQuery: Error: ${e.toString()}');
      }
      return handleException(e, ParseApiRQ.liveQuery, _debug, 'LiveQuery');
    }
  }

  void _connectLiveQuery() {
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
    if (actionData.containsKey('requestId')) {
      subscription = _requestSubScription[actionData['requestId']];
    }
    if (subscription == null) {
      print('error: no subscription for message:$message');
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
  }

  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  Subscription _latestSubscription;
  Client client = Client.instance;

  // ignore: always_specify_types
  @deprecated
  Future subscribe(QueryBuilder query) async {
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
