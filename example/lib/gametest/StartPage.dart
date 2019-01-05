import 'package:Parse_example/gametest/GameCommunication.dart';
import 'package:Parse_example/gametest/GamePage.dart';
import 'package:flutter/material.dart';

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  static final TextEditingController _name = new TextEditingController();
  String playerName;
  List<dynamic> playersList = <dynamic>[];

  @override
  void initState() {
    super.initState();

    ///
    /// Ask to be notified when messages related to the game
    /// are sent by the server
    ///
    game.addListener(_onGameDataReceived);
  }

  @override
  void dispose() {
    game.removeListener(_onGameDataReceived);
    super.dispose();
  }

  /// -------------------------------------------------------------------
  /// This routine handles all messages that are sent by the server.
  /// In this page, only the following 2 actions have to be processed
  ///  - players_list
  ///  - new_game
  /// -------------------------------------------------------------------
  _onGameDataReceived(message) {
    switch (message["action"]) {

      ///
      /// Each time a new player joins, we need to
      ///   * record the new list of players
      ///   * rebuild the list of all the players
      ///
      case "players_list":
        playersList = message["data"];

        // force rebuild
        setState(() {});
        break;

      ///
      /// When a game is launched by another player,
      /// we accept the new game and automatically redirect
      /// to the game board.
      /// As we are not the new game initiator, we will be
      /// using the "O"
      ///
      case 'new_game':
        Navigator.push(
            context,
            new MaterialPageRoute(
              builder: (BuildContext context) => new GamePage(
                    opponentName: message["data"], // Name of the opponent
                    character: 'O',
                  ),
            ));
        break;
    }
  }

  /// -----------------------------------------------------------
  /// If the user has not yet joined, let the user enter
  /// his/her name and join the list of players
  /// -----------------------------------------------------------
  Widget _buildJoin() {
    if (game.playerName != "") {
      return new Container();
    }
    return new Container(
      padding: const EdgeInsets.all(16.0),
      child: new Column(
        children: <Widget>[
          new TextField(
            controller: _name,
            keyboardType: TextInputType.text,
            decoration: new InputDecoration(
              hintText: 'Enter your name',
              contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              border: new OutlineInputBorder(
                borderRadius: new BorderRadius.circular(32.0),
              ),
              icon: const Icon(Icons.person),
            ),
          ),
          new Padding(
            padding: const EdgeInsets.all(8.0),
            child: new RaisedButton(
              onPressed: _onGameJoin,
              child: new Text('Join...'),
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------------------------------------------
  /// The user wants to join, so let's send his/her name
  /// As the user has a name, we may now show the other players
  /// ------------------------------------------------------
  _onGameJoin() {
    game.send('join', _name.text);

    /// Force a rebuild
    setState(() {});
  }

  /// ------------------------------------------------------
  /// Builds the list of players
  /// ------------------------------------------------------
  Widget _playersList() {
    ///
    /// If the user has not yet joined, do not display
    /// the list of players
    ///
    if (game.playerName == "") {
      return new Container();
    }

    ///
    /// Display the list of players.
    /// For each of them, put a Button that could be used
    /// to launch a new game
    ///
    List<Widget> children = playersList.map((playerInfo) {
      return new ListTile(
        title: new Text(playerInfo["name"]),
        trailing: new RaisedButton(
          onPressed: () {
            _onPlayGame(playerInfo["name"], playerInfo["id"]);
          },
          child: new Text('Play'),
        ),
      );
    }).toList();

    return new Column(
      children: children,
    );
  }

  /// --------------------------------------------------------------
  /// We launch a new Game, we need to:
  ///    * send the action "new_game", together with the ID
  ///      of the opponent we choosed
  ///    * redirect to the game board
  ///      As we are the game initiator, we will play with the "X"
  /// --------------------------------------------------------------
  _onPlayGame(String opponentName, String opponentId) {
    // We need to send the opponentId to initiate a new game
    game.send('new_game', opponentId);

    Navigator.push(
        context,
        new MaterialPageRoute(
          builder: (BuildContext context) => new GamePage(
                opponentName: opponentName,
                character: 'X',
              ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      bottom: false,
      top: false,
      child: Scaffold(
        appBar: new AppBar(
          title: new Text('TicTacToe'),
        ),
        body: SingleChildScrollView(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildJoin(),
              new Text('List of players:'),
              _playersList(),
            ],
          ),
        ),
      ),
    );
  }
}
