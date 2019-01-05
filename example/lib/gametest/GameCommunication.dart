import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'WebSocketsNotifications.dart';

///
/// Again, application-level global variable
///
GameCommunication game = new GameCommunication();

class GameCommunication {
  static final GameCommunication _game = new GameCommunication._internal();

  ///
  /// At first initialization, the player has not yet provided any name
  ///
  String _playerName = "";

  ///
  /// Before the "join" action, the player has no unique ID
  ///
  String _playerID = "";

  factory GameCommunication() {
    return _game;
  }

  GameCommunication._internal() {
    ///
    /// Let's initialize the WebSockets communication
    ///
    sockets.initCommunication();

    ///
    /// and ask to be notified as soon as a message comes in
    ///
    sockets.addListener(_onMessageReceived);
  }

  ///
  /// Getter to return the player's name
  ///
  String get playerName => _playerName;

  /// ----------------------------------------------------------
  /// Common handler for all received messages, from the server
  /// ----------------------------------------------------------
  _onMessageReceived(serverMessage) {
    ///
    /// As messages are sent as a String
    /// let's deserialize it to get the corresponding
    /// JSON object
    ///
    Map message = json.decode(serverMessage);

    switch (message["action"]) {

      ///
      /// When the communication is established, the server
      /// returns the unique identifier of the player.
      /// Let's record it
      ///
      case 'connect':
        _playerID = message["data"];
        break;

      ///
      /// For any other incoming message, we need to
      /// dispatch it to all the listeners
      ///
      default:
        _listeners.forEach((Function callback) {
          callback(message);
        });
        break;
    }
  }

  /// ----------------------------------------------------------
  /// Common method to send requests to the server
  /// ----------------------------------------------------------
  send(String action, String data) {
    ///
    /// When a player joins, we need to record the name
    /// he provides
    ///
    if (action == 'join') {
      _playerName = data;
    }

    ///
    /// Send the action to the server
    /// To send the message, we need to serialize the JSON
    ///
    sockets.send(json.encode({"action": action, "data": data}));
  }

  /// ==========================================================
  ///
  /// Listeners to allow the different pages to be notified
  /// when messages come in
  ///
  ObserverList<Function> _listeners = new ObserverList<Function>();

  /// ---------------------------------------------------------
  /// Adds a callback to be invoked in case of incoming
  /// notification
  /// ---------------------------------------------------------
  addListener(Function callback) {
    _listeners.add(callback);
  }

  removeListener(Function callback) {
    _listeners.remove(callback);
  }
}
