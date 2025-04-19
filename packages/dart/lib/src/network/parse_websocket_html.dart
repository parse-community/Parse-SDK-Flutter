/// If you change this file, you should apply the same changes to the 'parse_websocket_io.dart' file
library;

import 'package:web/web.dart' as web;

import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  WebSocket._(this._webSocket);

  static const int connecting = 0;
  static const int open = 1;
  static const int closing = 2;
  static const int closed = 3;

  final web.WebSocket _webSocket;

  static Future<WebSocket> connect(String liveQueryURL) async {
    final web.WebSocket webSocket = web.WebSocket(liveQueryURL);
    await webSocket.onOpen.first;
    return WebSocket._(webSocket);
  }

  int get readyState => _webSocket.readyState;

  Future<void> close() async {
    return _webSocket.close();
  }

  WebSocketChannel createWebSocketChannel() {
    return HtmlWebSocketChannel(_webSocket);
  }
}
