import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/application_constants.dart';
import 'package:parse_server_sdk/parse.dart';
import 'package:parse_server_sdk/parse_user.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initParse();
    initUser();
  }

  Future<void> initParse() async {
    Parse().initialize(
        appId: ApplicationConstants.PARSE_APPLICATION_ID,
        serverUrl: ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY);
  }

  Future<void> initUser() async {
    User()
        .createNewUser("TestFlutter", "TestPassword123", "TestEmail@Email.com");

    User().login().then((val) {
      print(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: new Center(
          child: new Text('Running Parse init'),
        ),
      ),
    );
  }
}