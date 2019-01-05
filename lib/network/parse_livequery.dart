import 'dart:async';
import "dart:convert";
import 'package:web_socket_channel/io.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class LiveQuery {
  final ParseHTTPClient client;
  IOWebSocketChannel channel;
  Map<String, dynamic> connectMessage;
  Map<String, dynamic> subscribeMessage;
  Map<String, Function> eventCallbacks = {};

  LiveQuery(ParseHTTPClient client) : client = client {
    connectMessage = {
      "op": "connect",
      "applicationId": client.data.applicationId,
      "masterKey": client.data.masterKey
    };

    subscribeMessage = {
      "op": "subscribe",
      "requestId": 1,
      "query": {
        "className": "post",
        "where": {},
      }
    };
    // channel = new IOWebSocketChannel.connect(client.data.liveQueryURL);
    // _parseController = StreamController.broadcast();
    // _parseController.stream = channel.stream;
    // connect();
  }

  connect() {
    channel = new IOWebSocketChannel.connect(client.data.liveQueryURL);
  }

  subscribe(String className) async {
    connect();
    // var v = channel.closeCode;
    // print("channel.closeCode: $v");
    // if (channel.closeCode == null) connect();

    // if (channel == null)
    //   channel = new IOWebSocketChannel.connect(client.data.liveQueryURL);
    // channel = new IOWebSocketChannel.connect(client.data.liveQueryURL);
    // channel.sink.add(JsonEncoder().convert(connectMessage));
    // subscribeMessage['query']['className'] = className.toString();
    // channel.sink.add(JsonEncoder().convert(subscribeMessage));
    // channel.close(status.goingAway);
    // channel.stream.listen((message) {
    //   // handling of the incoming messages
    // }, onError: (error, StackTrace stackTrace) {
    //   // error handling
    // }, onDone: () {
    //   // communication has been closed
    // });

    // ignore: close_sinks
    // var webSocket = await WebSocket.connect(client.data.liveQueryURL);
    channel.sink.add(JsonEncoder().convert(connectMessage));
    print(JsonEncoder().convert(connectMessage));
    // subscribeMessage['query']['className'] = className;
    channel.sink.add(JsonEncoder().convert(subscribeMessage));
    print(JsonEncoder().convert(subscribeMessage));
    // channel.sink.add(JsonEncoder().convert(parseObject));

    // channel.stream.listen((message) {
    //   print(JsonEncoder().convert(message));

    //   Map<String, dynamic> actionData = JsonDecoder().convert(message);
    //   print(JsonEncoder().convert(actionData));
    //   print(eventCallbacks);
    //   // if (eventCallbacks.containsKey(actionData['op']))
    //   //   eventCallbacks[actionData['op']](actionData);
    // });
    // close();
  }

  subscribe2(String className, channel) async {
    channel.sink.add("received!");
    // ignore: close_sinks
    channel.sink.add(JsonEncoder().convert(connectMessage));
    print(JsonEncoder().convert(connectMessage));
    // subscribeMessage['query']['className'] = className;
    channel.sink.add(JsonEncoder().convert(subscribeMessage));
    print(JsonEncoder().convert(subscribeMessage));
    // channel.sink.add(JsonEncoder().convert(parseObject));

    // var po = {
    //   "op": "subscribe",
    //   "requestId": 1,
    //   "query": {
    //     "className": "post",
    //     "where": {"objectId": "2pNUgv1CKA"},
    //     "fields": ["title"] // Optional
    //   },
    // };

    // channel.sink.add(JsonEncoder().convert(po));
    // channel.sink.add(JsonEncoder().convert(function()));
    // function();
    // var po1 = {
    //   "op": "update",
    //   "requestId": 1,
    //   "object": {
    //     "className": "post",
    //     "objectId": "2pNUgv1CKA",
    //     "title": "",
    //   }
    // };
    // channel.sink.add(JsonEncoder().convert(po1));

    // channel.stream.listen((message) {
    //   print(JsonEncoder().convert(message));

    //   Map<String, dynamic> actionData = JsonDecoder().convert(message);
    //   print(JsonEncoder().convert(actionData));
    //   print(eventCallbacks);
    //   if (eventCallbacks.containsKey(actionData['op']))
    //     eventCallbacks[actionData['op']](actionData);
    // });
  }

  void on(String op, Function callback) {
    eventCallbacks[op] = callback;
  }

  void close() {
    channel.sink.close(status.goingAway);
  }

// other websoket
  // static WebSocket _webSocket1;
  // static num _id = 0;

  // void connect() {
  //   closeSocket();
  //   Future<WebSocket> futureWebSocket = WebSocket.connect(
  //       client.data.liveQueryURL); // Api.WS_URL 为服务器端的 websocket 服务
  //   futureWebSocket.then((WebSocket ws) {
  //     _webSocket1 = ws;
  //     _webSocket1.readyState;
  //     // 监听事件
  //     void onData(dynamic content) {
  //       _id++;
  //       _sendMessage("收到");
  //       _createNotification("新消息", content + _id.toString());
  //     }

  //     _webSocket1.listen(onData,
  //         onError: (a) => print("error"), onDone: () => print("done"));
  //   });
  // }

  // static void closeSocket() {
  //   if (_webSocket1 != null) _webSocket1.close();
  // }

  // // 向服务器发送消息
  // static void _sendMessage(String message) {
  //   _webSocket1.add(message);
  // }

  // // 手机状态栏弹出推送的消息
  // static void _createNotification(String title, String content) async {
  //   print("content: $content");
  //   // await LocalNotifications.createNotification(
  //   //   id: _id,
  //   //   title: title,
  //   //   content: content,
  //   //   onNotificationClick: NotificationAction(
  //   //       actionText: "some action",
  //   //       callback: _onNotificationClick,
  //   //       payload: "接收成功！"),
  //   // );
  // }

  // static _onNotificationClick(String payload) {
  //   // LocalNotifications.removeNotification(_id);
  //   _sendMessage("消息已被阅读");
  // }
}
