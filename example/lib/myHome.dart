import 'dart:async';

import 'package:Parse_example/blocProvider.dart';
import 'package:Parse_example/liveQueryBloc.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/network/parse_livequery.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/parse.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  WebSocketChannel channel;
  LiveQuery liveQuery;
  final Function f;
  MyHomePage(
      {Key key,
      @required this.title,
      @required this.channel,
      this.liveQuery,
      this.f})
      : super(key: key) {
    // this.liveQuery.subscribe("post");
    // this.channel = liveQuery.channel as WebSocketChannel;
  }

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = new TextEditingController();
  LiveQueryBloc bloc;

  var info;

  @override
  void initState() {
    bloc = new LiveQueryBloc(liveQuery: widget.liveQuery);
    info = "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final IncrementBloc bloc = BlocProvider.of<IncrementBloc>(context);
    // final LiveQueryBloc bloc = BlocProvider.of<LiveQueryBloc>(context);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Padding(
        padding: const EdgeInsets.all(20.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Form(
              child: new TextFormField(
                controller: _controller,
                decoration: new InputDecoration(labelText: 'Send a message'),
              ),
            ),
            new StreamBuilder(
              stream: bloc.outParseLiveStream,
              builder: (context, snapshot) {
                return new Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: new Text(snapshot.hasData ? '${snapshot.data}' : ''),
                );
              },
            ),
            new Text(widget.liveQuery.channel.closeCode.toString()),
            new Text(info.toString())
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send message',
        child: new Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _sendMessage() {
    // if (_controller.text.isNotEmpty) {
    widget.f();

    // widget.liveQuery.channel.closeCode != null &&
    // if (widget.liveQuery.channel.closeCode == 1002) {
    //   widget.liveQuery = Parse().liveQuery();
    //   widget.liveQuery.subscribe("post");
    //   bloc = new LiveQueryBloc(liveQuery: widget.liveQuery);
    // }

    // widget.liveQuery.close();

    // widget.liveQuery.subscribe("post", widget.channel, widget.f);

    // widget.channel.sink.add(_controller.text);
    // widget.channel.sink.add(widget.function());
    // }
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    // TODO: implement didUpdateWidget

    setState(() {
      info =
          "closeCode: ${widget.liveQuery.channel.closeCode}--${DateTime.now().toString()}";
    });
    if (widget.liveQuery.channel.closeCode == 1002) {
      widget.liveQuery = Parse().liveQuery();
      widget.liveQuery.subscribe("post");
      bloc = new LiveQueryBloc(liveQuery: widget.liveQuery);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // widget.channel.sink.close();
    // liveQuery.dispose();
    bloc.dispose();
    super.dispose();
  }
}
