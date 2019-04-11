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
    _sendSessionId = autoSendSessionId ?? ParseCoreData().autoSendSessionId;

    _connectMessage = {
      'op': 'connect',
      'applicationId': _client.data.applicationId,
      'clientKey': _client.data.clientKey
    };
    if (_sendSessionId) {
      _connectMessage['sessionToken'] = _client.data.sessionId;
    }
  }

  WebSocket _webSocket;
  ParseHTTPClient _client;
  bool _debug;
  bool _sendSessionId;
  IOWebSocketChannel _channel;
  Map<String, dynamic> _connectMessage;
  Map<String, dynamic> _disconnectMessage;
  Map<String, dynamic> _subscribeMessage;
  Map<String, Function> eventCallbacks = {};
  Map<String, dynamic> _whereMap = Map<String, dynamic>();
  int _requestIdCount = 1;
  List<String> _liveQueryEvent = [
    'create',
    'enter',
    'update',
    'leave',
    'delete',
    'error'
  ];

  int _requestIdGenerator() {
    return _requestIdCount++;
  }

  Future<void> subscribe(QueryBuilder query) async {
    String _liveQueryURL = _client.data.liveQueryURL;
    if (_liveQueryURL.contains('https')) {
      _liveQueryURL = _liveQueryURL.replaceAll('https', 'wws');
    } else if (_liveQueryURL.contains('http')) {
      _liveQueryURL = _liveQueryURL.replaceAll('http', 'ww');
    }

    final String _className = query.object.className;
    //Remove limites in LiveQuery
    query.limiters.clear();
    final String _where = query._buildQuery().replaceAll('where=', '');
    if (_where != '') {
      _whereMap = json.decode(_where);
    }

    final int requestId = _requestIdGenerator();

    try {
      _webSocket = await WebSocket.connect(
        _liveQueryURL,
      );

      if (_webSocket != null && _webSocket.readyState == WebSocket.OPEN) {
        if (_debug) {
          print('Livequery: Socket opened');
        }
      } else {
        if (_debug) {
          print('Livequery: Error when connection client');
          return;
        }
      }
      _channel = IOWebSocketChannel(_webSocket);

      _channel.stream.listen((dynamic message) {
        if (_debug) {
          print('Livequery: Listen: ${message}');
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
          print("Livequery: Task Done");
        }
      }, onError: (error) {
        return handleException(error, ParseApiRQ.liveQuery, _debug, _className);
      });

      //The connect message is sent from a client to the LiveQuery server.
      //It should be the first message sent from a client after the WebSocket connection is established.
      _channel.sink.add(jsonEncode(_connectMessage));

      _subscribeMessage = {
        'op': 'subscribe',
        'requestId': requestId,
        'query': {
          'className': _className,
          'where': _whereMap,
        }
      };
      if (_sendSessionId) {
        _subscribeMessage['sessionToken'] = _client.data.sessionId;
      }

      //After a client connects to the LiveQuery server,
      //it can send a subscribe message to subscribe a ParseQuery.
      _channel.sink.add(jsonEncode(_subscribeMessage));

      _disconnectMessage = {
        'op': 'unsubscribe',
        'requestId': requestId,
      };
    } on Exception catch (e) {
      print('Error: ${e.toString()}');
      return handleException(e, ParseApiRQ.liveQuery, _debug, _className);
    }
  }

  void on(LiveQueryEvent op, Function callback) {
    eventCallbacks[_liveQueryEvent[op.index]] = callback;
  }

  Future<void> unSubscribe() async {
    if (_channel != null) {
      if (_channel.sink != null) {
        await _channel.sink.add(jsonEncode(_disconnectMessage));
        await _channel.sink.close();
      }
    }
    if (_webSocket != null && _webSocket.readyState == WebSocket.OPEN) {
      await _webSocket.close();
    }
  }
}