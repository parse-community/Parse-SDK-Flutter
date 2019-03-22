part of flutter_parse_sdk;

/// Still under development
class LiveQuery {

  LiveQuery(ParseHTTPClient client) : client = client {
    connectMessage = <String, String>{
      'op': 'connect',
      'applicationId': client.data.applicationId,
    };

    final Map<String, dynamic> whereMap = Map<String, dynamic>();

    subscribeMessage = {
      'op': 'subscribe',
      'requestId': 1,
      'query': {
        'className': null,
        'where': whereMap,
      }
    };
  }

  final ParseHTTPClient client;
  IOWebSocketChannel channel;
  Map<String, Object> connectMessage;
  Map<String, Object> subscribeMessage;
  Map<String, Function> eventCallbacks = {};

  Future<void> subscribe(String className) async {
    final WebSocket webSocket = await WebSocket.connect(client.data.liveQueryURL);
    channel = IOWebSocketChannel(webSocket);
    channel.sink.add(jsonEncode(connectMessage));
    final Map<String, dynamic> classNameMap = subscribeMessage['query'];
    classNameMap['className'] = className;
    channel.sink.add(jsonEncode(subscribeMessage));

    channel.stream.listen((dynamic message) {
      final Map<String, dynamic> actionData = jsonDecode(message);
      if (eventCallbacks.containsKey(actionData['op']))
        eventCallbacks[actionData['op']](actionData);
    });
  }

  void on(String op, Function callback) {
    eventCallbacks[op] = callback;
  }

  Future<void> close() async {
    await channel.sink.close();
  }
}
