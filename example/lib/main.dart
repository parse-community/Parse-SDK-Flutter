import 'package:flutter/material.dart';
import 'dart:async';

import 'package:parse/parse.dart';
import 'package:parse_example/application_constants.dart';
import 'package:parse_example/diet_plan.dart';

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
  }

  Future<void> initParse() async {
    Parse().initialize(
        appId: ApplicationConstants.PARSE_APPLICATION_ID,
        serverUrl: ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY);

    DietPlan().get('R5EonpUDWy').then((plan) {
      print(DietPlan.fromJson(plan).name);
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
