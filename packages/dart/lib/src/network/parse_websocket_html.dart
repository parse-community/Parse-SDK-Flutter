/// If you change this file, you should apply the same changes to the 'parse_websocket_io.dart' file
library;


import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  WebSocket._(this._webSocket);

  static const int connecting = 0;
  static const int open = 1;
  static const int closing = 2;
  static const int closed = 3;

  final IO.Socket _webSocket;

  static final Map<String, int> _states={
    'closed':3,
    'opening':0,
    'open':1,
    'closing':2
  };
  static Future<WebSocket> connect(String liveQueryURL) async {
    Completer<WebSocket> completer= Completer();
    final IO.Socket webSocket = IO.io(
      liveQueryURL,
      IO.OptionBuilder().setTransports(['websocket']).enableReconnection().build()
    );
    webSocket.connect();
    webSocket.onConnect((handler){
      if(!completer.isCompleted){
        completer.complete(WebSocket._(webSocket));
      }
    });
    webSocket.onConnectError((handler){
      if(!completer.isCompleted){
        completer.completeError('unable to connect to the server $handler');
      }
    });

    

    return completer.future;
  }

  int get readyState => _states[_webSocket.io.readyState]!;

  Future<IO.Socket> close() async {
    return _webSocket.disconnect();
  }

  WebSocketChannel createWebSocketChannel() {
    return HtmlWebSocketChannel(_webSocket);
  }
}
