import "dart:convert";
import 'package:web_socket_channel/io.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'dart:io';

class LiveQuery {
  final ParseHTTPClient client;
  var channel;
  Map<String, dynamic> connectMessage;
  Map<String, dynamic> subscribeMessage;
  Map<String, Function> eventCallbacks = {};

  LiveQuery(ParseHTTPClient client) : client = client {
    connectMessage = {
      "op": "connect",
      "applicationId": client.data.applicationId,
    };

    subscribeMessage = {
      "op": "subscribe",
      "requestId": 1,
      "query": {
        "className": null,
        "where": {},
      }
    };
  }

  subscribe(String className) async {
    // ignore: close_sinks
    var webSocket = await WebSocket.connect(client.data.liveQueryURL);
    channel = new IOWebSocketChannel(webSocket);
    channel.sink.add(JsonEncoder().convert(connectMessage));
    subscribeMessage['query']['className'] = className;
    channel.sink.add(JsonEncoder().convert(subscribeMessage));
    channel.stream.listen((message) {
      Map<String, dynamic> actionData = JsonDecoder().convert(message);
      if (eventCallbacks.containsKey(actionData['op']))
        eventCallbacks[actionData['op']](actionData);
    });
  }

  void on(String op, Function callback) {
    eventCallbacks[op] = callback;
  }

  void close() {
    channel.close();
  }
}
