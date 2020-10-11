/// If you change this file, you should apply the same changes to the 'parse_websocket_io.dart' file

import 'dart:html' as html;

import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocket {
  WebSocket._(this._webSocket);

  static const int CONNECTING = 0;
  static const int OPEN = 1;
  static const int CLOSING = 2;
  static const int CLOSED = 3;

  final html.WebSocket _webSocket;

  static Future<WebSocket> connect(String liveQueryURL) async {
    final html.WebSocket webSocket = html.WebSocket(liveQueryURL);
    await webSocket.onOpen.first;
    return WebSocket._(webSocket);
  }

  int get readyState => _webSocket.readyState;

  Future close() async {
    return _webSocket.close();
  }

  WebSocketChannel createWebSocketChannel() {
    return HtmlWebSocketChannel(_webSocket);
  }
}
