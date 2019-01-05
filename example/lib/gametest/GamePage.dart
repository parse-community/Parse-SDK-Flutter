import 'package:Parse_example/gametest/GameCommunication.dart';
import 'package:flutter/material.dart';

class GamePage extends StatefulWidget {
  GamePage({
    Key key,
    this.opponentName,
    this.character,
  }) : super(key: key);

  ///
  /// Name of the opponent
  ///
  final String opponentName;

  ///
  /// Character to be used by the player for his/her moves ("X" or "O")
  ///
  final String character;

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  ///
  /// One game in terms of grid cells.
  /// When the user plays, one of this cells is filled with "X" or "O"
  ///
  List<String> grid = <String>["", "", "", "", "", "", "", "", ""];

  @override
  void initState() {
    super.initState();

    ///
    /// Ask to be notified when a message from the server
    /// comes in.
    ///
    game.addListener(_onAction);
  }

  @override
  void dispose() {
    game.removeListener(_onAction);
    super.dispose();
  }

  /// ---------------------------------------------------------
  /// The opponent took an action
  /// Handler of these actions
  /// ---------------------------------------------------------
  _onAction(message) {
    switch (message["action"]) {

      ///
      /// The opponent resigned, so let's leave this screen
      ///
      case 'resigned':
        Navigator.of(context).pop();
        break;

      ///
      /// The opponent played a move.
      /// So record it and rebuild the board
      ///
      case 'play':
        var data = (message["data"] as String).split(';');
        grid[int.parse(data[0])] = data[1];

        // Force rebuild
        setState(() {});
        break;
    }
  }

  /// ---------------------------------------------------------
  /// This player resigns
  /// We need to send this notification to the other player
  /// Then, leave this screen
  /// ---------------------------------------------------------
  _doResign() {
    game.send('resign', '');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      top: false,
      bottom: false,
      child: new Scaffold(
        appBar: new AppBar(
            title: new Text('Game against: ${widget.opponentName}',
                style: new TextStyle(fontSize: 16.0)),
            actions: <Widget>[
              new RaisedButton(
                onPressed: _doResign,
                child: new Text('Resign'),
              ),
            ]),
        body: _buildBoard(),
      ),
    );
  }

  /// --------------------------------------------------------
  /// Builds the Game Board.
  /// --------------------------------------------------------
  Widget _buildBoard() {
    return new SafeArea(
      top: false,
      bottom: false,
      child: new GridView.builder(
        gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: 9,
        itemBuilder: (BuildContext context, int index) {
          return _gridItem(index);
        },
      ),
    );
  }

  Widget _gridItem(int index) {
    Color color = grid[index] == "X" ? Colors.blue : Colors.red;

    return new InkWell(
      onTap: () {
        ///
        /// The user taps a cell.
        /// If the latter is empty, let's put this player's character
        /// and notify the other player.
        /// Repaint the board
        ///
        if (grid[index] == "") {
          grid[index] = widget.character;

          ///
          /// To send a move, we provide the cell index
          /// and the character of this player
          ///
          game.send('play', '$index;${widget.character}');

          /// Force the board repaint
          setState(() {});
        }
      },
      child: new GridTile(
        child: new Card(
          child: new FittedBox(
              fit: BoxFit.contain,
              child: new Text(grid[index],
                  style: new TextStyle(
                    fontSize: 50.0,
                    color: color,
                  ))),
        ),
      ),
    );
  }
}
