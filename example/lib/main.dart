import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/application_constants.dart';
import 'package:flutter_plugin_example/diet_plan.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/network/parse_query.dart';
import 'package:parse_server_sdk/objects/parse_user.dart';
import 'package:parse_server_sdk/parse.dart';

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
    getAllItems();
    getSingleItem();
    query();
    queryByContainedIn();
    initUser();
  }

  Future<void> initParse() async {

    // Initialize parse
    Parse().initialize(
        appId: ApplicationConstants.PARSE_APPLICATION_ID,
        serverUrl: ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY);
  }

  void getAllItems() {
    DietPlan().getAll().then((response) {
      if (response.success){

        for (var plan in response.result) {
          print(ApplicationConstants.APP_NAME + ": " + (plan as DietPlan).name);
        }

      } else {
        print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
      }
    });
  }

  void getSingleItem() {
    DietPlan().get('R5EonpUDWy').then((response) {
      if (response.success){
        print(ApplicationConstants.APP_NAME + ": " + (response.result as DietPlan).toString());
      } else {
        print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
      }
    });
  }

  void query() {
    // Query for an object by name
    QueryBuilder()
      ..object = DietPlan()
      ..field = DietPlan.NAME
      ..equals = ['Paleo']
      ..query().then((response){

        if (response.success){
          print(ApplicationConstants.APP_NAME + ": " + ((response.result as List<ParseObject>)[0] as DietPlan).toString());
        } else {
          print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
        }
      });
  }

  void queryByContainedIn() {
    // Query for an object by name
    QueryBuilder()
      ..object = DietPlan()
      ..field = DietPlan.NAME
      ..contains = ['Diet']
      ..query().then((response){

        if (response.success){
          print(ApplicationConstants.APP_NAME + ": " + ((response.result as List<ParseObject>)[0] as DietPlan).toString());
        } else {
          print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
        }
      });
  }

  Future<void> initUser() async {
   User().createNewUser("TestFlutter", "TestPassword123", "TestEmail@Email.com");

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
