import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/application_constants.dart';
import 'package:flutter_plugin_example/diet_plan.dart';
import 'package:parse_server_sdk/network/parse_query.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
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
    runTestQueries();
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
        floatingActionButton:
            new FloatingActionButton(onPressed: runTestQueries),
      ),
    );
  }

  initParse() async {
    // Initialize parse
    Parse().initialize(ApplicationConstants.PARSE_APPLICATION_ID,
        ApplicationConstants.PARSE_SERVER_URL,
        masterKey: ApplicationConstants.PARSE_MASTER_KEY,
        appName: ApplicationConstants.APP_NAME,
        debug: true);
  }

  runTestQueries() {
    //getAllItems();
    //getAllItemsByName();
    //getSingleItem();
    query();
    //initUser();
  }

  void getAllItemsByName() async {
    var apiResponse = await ParseObject('ParseTableName').getAll();

    if (apiResponse.success) {
      for (var testObject in apiResponse.result) {
        print(ApplicationConstants.APP_NAME + ": " + testObject.toString());
      }
    }
  }

  void getAllItems() async {
    var response = await DietPlan().getAll();

    if (response.success) {
      for (var plan in response.result) {
        print(ApplicationConstants.APP_NAME + ": " + (plan as DietPlan).name);
      }
    } else {
      print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
    }
  }

  void getSingleItem() async {
    var response = await DietPlan().get('R5EonpUDWy');

    if (response.success) {
      print(ApplicationConstants.APP_NAME +
          ": " +
          (response.result as DietPlan).toString());
    } else {
      print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
    }
  }

  void query() async {
    // Query for an object by name
    var queryBuilder = QueryBuilder<DietPlan>(DietPlan())
      ..startsWith(DietPlan.NAME, "Keto")
      ..greaterThan(DietPlan.FAT, 64)
      ..lessThan(DietPlan.FAT, 66)
      ..equals(DietPlan.CARBS, 5);

    var response = await queryBuilder.query();

    if (response.success) {
      print(ApplicationConstants.APP_NAME + ": " + ((response.result as List<dynamic>).first as DietPlan).toString());
    } else {
      print(ApplicationConstants.APP_NAME + ": " + response.exception.message);
    }
  }

  initUser() async {
    ParseUser()
        .create("TestFlutter", "TestPassword123", "TestFlutterSDK@gmail.com");
    var user = await ParseUser().signUp();
    user = await ParseUser().login();
    user = await ParseUser().currentUser(fromServer: true);
    user = await ParseUser().requestPasswordReset();
    user = await ParseUser().verificationEmailRequest();
    user = await ParseUser().all();
    user = await ParseUser().save();
    user = await ParseUser().destroy();
  }
}
