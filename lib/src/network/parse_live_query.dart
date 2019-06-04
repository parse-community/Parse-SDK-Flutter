part of flutter_parse_sdk;

enum LiveQueryEvent { create, enter, update, leave, delete, error }

class LiveQuery {
  LiveQuery({bool debug, ParseHTTPClient client, bool autoSendSessionId}) {
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _sendSessionId = autoSendSessionId ?? ParseCoreData().autoSendSessionId ?? true;
  }

  WebSocket _webSocket;
  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  IOWebSocketChannel _channel;
  Map<String, dynamic> _connectMessage;
  Map<String, dynamic> _subscribeMessage;
  Map<String, dynamic> _unsubscribeMessage;
  Map<String, Function> eventCallbacks = <String, Function>{};
  int _requestIdCount = 1;
  final List<String> _liveQueryEvent = <String>[
    'create',
    'enter',
    'update',
    'leave',
    'delete',
    'error'
  ];
  final String _printConstLiveQuery = 'LiveQuery: ';

  int _requestIdGenerator() {
    return _requestIdCount++;
  }

  // ignore: always_specify_types
  Future subscribe(QueryBuilder query) async {

    String _liveQueryURL = _client.data.liveQueryURL;
    if (_liveQueryURL.contains('https')) {
      _liveQueryURL = _liveQueryURL.replaceAll('https', 'wss');
    } else if (_liveQueryURL.contains('http')) {
      _liveQueryURL = _liveQueryURL.replaceAll('http', 'ws');
    }

    final String _className = query.object.className;
    query.limiters.clear(); //Remove limits in LiveQuery
    final String _where = query._buildQuery().replaceAll('where=', '');

    //Convert where condition to Map
    Map<String, dynamic> _whereMap = Map<String, dynamic>();
    if (_where != '') {
      _whereMap = json.decode(_where);
    }

    final int requestId = _requestIdGenerator();

    try {
      _webSocket = await WebSocket.connect(_liveQueryURL);

      if (_webSocket != null && _webSocket.readyState == WebSocket.open) {
        if (_debug) {
          print('$_printConstLiveQuery: Socket opened');
        }
      } else {
        if (_debug) {
          print('$_printConstLiveQuery: Error when connection client');
          return Future<void>.value(null);
        }
      }

      _channel = IOWebSocketChannel(_webSocket);
      _channel.stream.listen((dynamic message) {
        if (_debug) {
          print('$_printConstLiveQuery: Listen: $message');
        }

        final Map<String, dynamic> actionData = jsonDecode(message);

        if (eventCallbacks.containsKey(actionData['op'])) {
          if (actionData.containsKey('object')) {
            final Map<String, dynamic> map = actionData['object'];
            final String className = map['className'];
            if (className == '_User') {
              eventCallbacks[actionData['op']](
                  ParseUser._getEmptyUser().fromJson(map));
            } else {
              eventCallbacks[actionData['op']](
                  ParseObject(className).fromJson(map));
            }
          } else {
            eventCallbacks[actionData['op']](actionData);
          }
        }
      }, onDone: () {
        if (_debug) {
          print('$_printConstLiveQuery: Done');
        }
      }, onError: (Error error) {
        if (_debug) {
          print(
              '$_printConstLiveQuery: Error: ${error.runtimeType.toString()}');
        }
        return Future<ParseResponse>.value(handleException(
            Exception(error), ParseApiRQ.liveQuery, _debug, _className));
      });

      //The connect message is sent from a client to the LiveQuery server.
      //It should be the first message sent from a client after the WebSocket connection is established.
      _connectMessage = <String, String>{
        'op': 'connect',
        'applicationId': _client.data.applicationId,
        'clientKey': _client.data.clientKey ?? ''
      };
      if (_sendSessionId) {
        _connectMessage['sessionToken'] = _client.data.sessionId;
      }

      if (_debug) {
        print('$_printConstLiveQuery: ConnectMessage: $_connectMessage');
      }
      _channel.sink.add(jsonEncode(_connectMessage));

      //After a client connects to the LiveQuery server,
      //it can send a subscribe message to subscribe a ParseQuery.
      _subscribeMessage = <String, dynamic>{
        'op': 'subscribe',
        'requestId': requestId,
        'query': <String, dynamic>{
          'className': _className,
          'where': _whereMap,
        }
      };
      if (_sendSessionId) {
        _subscribeMessage['sessionToken'] = _client.data.sessionId;
      }

      if (_debug) {
        print('$_printConstLiveQuery: SubscribeMessage: $_subscribeMessage');
      }

      _channel.sink.add(jsonEncode(_subscribeMessage));

      //Mount message for Unsubscribe
      _unsubscribeMessage = <String, dynamic>{
        'op': 'unsubscribe',
        'requestId': requestId,
      };
    } on Exception catch (e) {
      if (_debug) {
        print('$_printConstLiveQuery: Error: ${e.toString()}');
      }
      return handleException(e, ParseApiRQ.liveQuery, _debug, _className);
    }
  }

  void on(LiveQueryEvent op, Function callback) {
    eventCallbacks[_liveQueryEvent[op.index]] = callback;
  }

  Future<void> unSubscribe() async {
    if (_channel != null) {
      if (_channel.sink != null) {
        if (_debug) {
          print(
              '$_printConstLiveQuery: UnsubscribeMessage: $_unsubscribeMessage');
        }
        _channel.sink.add(jsonEncode(_unsubscribeMessage));
        await _channel.sink.close();
      }
    }
    if (_webSocket != null && _webSocket.readyState == WebSocket.open) {
      if (_debug) {
        print('$_printConstLiveQuery: Socket closed');
      }
      await _webSocket.close();
    }
  }
}
