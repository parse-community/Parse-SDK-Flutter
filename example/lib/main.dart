import 'dart:async';
import 'dart:convert';

import 'package:Parse_example/application_constants.dart';
import 'package:Parse_example/diet_plan.dart';
import 'package:Parse_example/myHome.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/network/parse_livequery.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/network/parse_query.dart';
import 'package:parse_server_sdk/objects/parse_user.dart';
import 'package:parse_server_sdk/parse.dart';
import 'package:web_socket_channel/io.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initParse();
    super.initState();
    // getAllItems();
    // getSingleItem();
    // query();
    // queryByContainedIn();
    // initUser();
    // updatePost();
  }

  LiveQuery live;
  AppLifecycleState _lastLifecycleState;
  Future<void> initParse() async {
    // Initialize parse
    Parse().initialize(ApplicationConstants.PARSE_APPLICATION_ID,
        ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY,
        liveQueryUrl: ApplicationConstants.PARSE_LIVE_SERVER_URL);
    // parse.liveQuery().connect();
    live = Parse().liveQuery();
    // live.connect();
    live.subscribe("post");

    // live.subscribe("post");
    // live.on('subscribed', updatePost);

    // Parse().liveQuery().on("update", () => print("object updated!!"));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // live.subscribe("post");
      // _timerLink = new Timer(const Duration(milliseconds: 1), () {
      //   _retrieveDynamicLink();
      // });
    }
    print("state: $state");
    setState(() {
      _lastLifecycleState = state;
    });
  }

  t() {
    print('subscription opened');
  }

  updatePost() {
    DietPlan().get('2pNUgv1CKA').then((response) {
      if (response.success) {
        print("response.result: ${response.result}");
        var dd = response.result as DietPlan;
        dd.objectId = "2pNUgv1CKA";
        dd.name = new WordPair.random().asPascalCase;
        //     Map<String, dynamic> bodyData = {};
        // bodyData["title"] = userData.emailAddress;
        // print(ApplicationConstants.APP_NAME +
        //     ":: ${DietPlan.DIET_PLAN}---${(response.result as DietPlan).objectId}---  " +
        //     (response.result as DietPlan).toString());
        print("dd: $dd");
        var m = new Map<String, dynamic>();
        m.putIfAbsent("title", () => dd.name);
        dd.createObjectData(m);
        // return dd;
        dd.save();
      } else {
        print(
            ApplicationConstants.APP_NAME + ": " + response.exception.message);
      }
    });
  }

  void getAllItems() {
    DietPlan().getAll().then((response) {
      if (response.success) {
        for (var plan in response.result) {
          if ((plan as DietPlan).name != null) {
            print(ApplicationConstants.APP_NAME +
                ": ${DietPlan.DIET_PLAN}------ " +
                (plan as DietPlan).name);
          } else {
            print(ApplicationConstants.APP_NAME +
                ": ${DietPlan.DIET_PLAN}---${(plan as DietPlan).objectId}--- null");
          }
        }
      } else {
        print(
            ApplicationConstants.APP_NAME + ": " + response.exception.message);
      }
    });
  }

  void getSingleItem() {
    DietPlan().get('2pNUgv1CKA').then((response) {
      if (response.success) {
        print("response.result: ${response.result}");
        print(ApplicationConstants.APP_NAME +
            ":: ${DietPlan.DIET_PLAN}---${(response.result as DietPlan).objectId}---  " +
            (response.result as DietPlan).toString());
      } else {
        print(
            ApplicationConstants.APP_NAME + ": " + response.exception.message);
      }
    });
  }

  void query() {
    // Query for an object by name
    QueryBuilder()
      ..object = DietPlan()
      ..field = DietPlan.NAME
      ..equals = ['fff444']
      ..query().then((response) {
        if (response.success) {
          print(ApplicationConstants.APP_NAME +
              "::: ${DietPlan.DIET_PLAN}---${((response.result as List<ParseObject>)[0] as DietPlan).name}---  " +
              ((response.result as List<ParseObject>)[0] as DietPlan)
                  .objectId
                  .toString());
        } else {
          print(ApplicationConstants.APP_NAME +
              ": " +
              response.exception.message);
        }
      });
  }

  void queryByContainedIn() {
    // Query for an object by name
    QueryBuilder()
      ..object = DietPlan()
      ..field = DietPlan.NAME
      ..containedIn = ['dfg']
      ..query().then((response) {
        if (response.success) {
          print("queryByContainedIn-result: ${response.result}");
          print(ApplicationConstants.APP_NAME +
              ": " +
              ((response.result as List<ParseObject>).length > 0
                  ? ((response.result as List<ParseObject>)[0] as DietPlan)
                      .toString()
                  : ""));
        } else {
          print(ApplicationConstants.APP_NAME +
              ": " +
              response.exception.message);
        }
      });
  }

  Future<void> initUser() async {
    User()
        .createNewUser("TestFlutter", "TestPassword123", "TestEmail@Email.com");
    User().signUp();

    User().login().then((val) {
      print("val: $val");
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = 'WebSocket Demo';
    return new MaterialApp(
      title: title,
      // home: new StartPage(),
      home: new MyHomePage(
        title: title,
        channel: live.channel,
        //     new IOWebSocketChannel.connect("ws://118.24.162.252:2018/parse"),
        liveQuery: live,
        f: updatePost,
      ),
    );
  }

  @override
  void dispose() {
    live.channel.sink.close();
    super.dispose();
  }
}
