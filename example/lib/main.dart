import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/application_constants.dart';
import 'package:flutter_plugin_example/diet_plan.dart';
import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  Stetho.initialize();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initParse();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: const Text('Running Parse init'),
        ),
        floatingActionButton: FloatingActionButton(onPressed: runTestQueries),
      ),
    );
  }

  Future<void> initParse() async {
    // Initialize parse
    Parse().initialize(ApplicationConstants.keyParseApplicationId,
        ApplicationConstants.keyParseServerUrl,
        masterKey: ApplicationConstants.keyParseMasterKey, debug: true);

    // Check server is healthy and live - Debug is on in this instance so check logs for result
    final ParseResponse response = await Parse().healthCheck();
    if (response.success) {
      runTestQueries();
    } else {
      print('Server health check failed');
    }
  }

  void runTestQueries() {
    createItem();
    getAllItems();
    getAllItemsByName();
    getSingleItem();
    getConfigs();
    query();
    initUser();
    function();
    functionWithParameters();
  }

  Future<void> createItem() async {
    //Create user Anonymous
    ParseUser user = ParseUser('', '', '');
    final ParseResponse response = await user.loginAnonymous();

    if (response.success) {
      user = response.result as ParseUser;
    }

    //Creates a temporary file in local storage to upload to Parse Server
    //The file can be selected using ImagePicker
    //File file = await ImagePicker.pickImage(source: ImageSource.gallery);
    final File file = await _downloadFile(
        'https://i2.wp.com/blog.openshift.com/wp-content/uploads/parse-server-logo-1.png',
        'image.png');

    final ParseFile parseFile = ParseFile(file, name: 'image.png');
    final ParseResponse fileResponse = await parseFile.save();

    if (fileResponse.success) {
      print('Upload with success');
    } else {
      print('Upload with error');
    }

    final ParseObject newObject = ParseObject('TestObjectForApi');
    newObject.set<String>('name', 'testItem');
    newObject.set<int>('age', 26);
    newObject.set<double>('price', 1.99);
    newObject.set<bool>('found', true);
    newObject.set<List<String>>('listString', ['a', 'b', 'c', 'd']);
    newObject.set<List<int>>('listNumber', [0, 1]);
    newObject.set<DateTime>('dateTest', DateTime.now());
    newObject.set<ParseGeoPoint>('location',
        ParseGeoPoint(latitude: 37.4230567, longitude: -122.0924609));
    
    if (user != null) {
      newObject.set<ParseUser>('user', user); //save Pointer to user
      newObject.set<List<ParseUser>>(
          'users', [user, user]); //save array Pointer to users
    }

    if (parseFile.url != null) {
      newObject.set<ParseFile>('fileImage', parseFile); //save ParseFile
      newObject.set<List<ParseFile>>(
          'fileImages', [parseFile, parseFile]); //save array ParseFile
    }

    final ParseResponse apiResponse = await newObject.create();

    if (apiResponse.success && apiResponse.result != null) {
      print(ApplicationConstants.keyAppName +
          ': ' +
          apiResponse.result.toString());
    }
  }

  Future<void> getAllItemsByName() async {
    final ParseResponse apiResponse =
        await ParseObject('TestObjectForApi').getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (final ParseObject testObject in apiResponse.result) {
        print(ApplicationConstants.keyAppName + ': ' + testObject.toString());
      }
    }
  }

  Future<void> getAllItems() async {
    final ParseResponse apiResponse = await DietPlan().getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (final DietPlan plan in apiResponse.result) {
        print(ApplicationConstants.keyAppName + ': ' + plan.name);
      }
    } else {
      print(ApplicationConstants.keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> getSingleItem() async {
    final ParseResponse apiResponse = await DietPlan().getObject('R5EonpUDWy');

    if (apiResponse.success && apiResponse.result != null) {
      final DietPlan dietPlan = apiResponse.result;

      // Shows example of storing values in their proper type and retrieving them
      dietPlan.set<int>('RandomInt', 8);
      final int randomInt = dietPlan.get<int>('RandomInt');

      if (randomInt is int) {
        print('Saving generic value worked!');
      }

      // Shows example of pinning an item
      await dietPlan.pin();

      // shows example of retrieving a pin
      final DietPlan newDietPlanFromPin =
          await DietPlan().fromPin('R5EonpUDWy');
      if (newDietPlanFromPin != null) {
        print('Retreiving from pin worked!');
      }
    } else {
      print(ApplicationConstants.keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> query() async {

    final ParseUser user = await ParseUser.currentUser();
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder<ParseObject>(ParseObject('TestObjectForApi'))
          ..whereEqualTo('user', user.toPointer()) //query using Pointer
          ..whereLessThan(keyVarCreatedAt, DateTime.now());

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.result != null) {
      final List<ParseObject> listFromApi = apiResponse.result;
      final ParseObject parseObject = listFromApi?.first;
      print('Result: ${parseObject.toString()}');
    } else {
      print('Result: ${apiResponse.error.message}');
    }
  }

  Future<void> initUser() async {
    // All return type ParseUser except all
    ParseUser user =
        ParseUser('TestFlutter', 'TestPassword123', 'test.flutter@gmail.com');

    /// Sign-up
    ParseResponse response = await user.signUp();
    if (response.success) {
      user = response.result;
    }

    /// Login
    response = await user.login();
    if (response.success) {
      user = response.result;
    }

    /// Reset password
    response = await user.requestPasswordReset();
    if (response.success) {
      user = response.result;
    }

    /// Verify email
    response = await user.verificationEmailRequest();
    if (response.success) {
      user = response.result;
    }

    // Best practice for starting the app. This will check for a valid user from a previous session from a local storage
    user = await ParseUser.currentUser();

    /// Update current user from server - Best done to verify user is still a valid user
    response = await ParseUser.getCurrentUserFromServer(
        token: user?.get<String>(keyHeaderSessionToken));
    if (response.success) {
      user = response.result;
    }

    /// log user out
    response = await user.logout();
    if (response.success) {
      user = response.result;
    }

    user =
        ParseUser('TestFlutter', 'TestPassword123', 'phill.wiggins@gmail.com');
    response = await user.login();
    if (response.success) {
      user = response.result;
    }

    response = await user.save();
    if (response.success) {
      user = response.result;
    }

    /// Remove a user and delete
    final ParseResponse destroyResponse = await user.destroy();
    if (destroyResponse.success) {
      print('object has been destroyed!');
    }

    // Returns type ParseResponse as its a query, not a single result
    response = await ParseUser.all();
    if (response.success) {
      // We have a list of all users (LIMIT SET VIA SDK)
    }

    final QueryBuilder<ParseUser> queryBuilder =
        QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereStartsWith(ParseUser.keyUsername, 'phillw');

    final ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success) {
      final List<ParseUser> users = response.result;
      for (final ParseUser user in users) {
        print(ApplicationConstants.keyAppName + ': ' + user.toString());
      }
    }
  }

  Future<void> function() async {
    final ParseCloudFunction function = ParseCloudFunction('hello');
    final ParseResponse result =
        await function.executeObjectFunction<ParseObject>();
    if (result.success) {
      if (result.result is ParseObject) {
        final ParseObject parseObject = result.result;
        print(parseObject.className);
      }
    }
  }

  Future<void> functionWithParameters() async {
    final ParseCloudFunction function = ParseCloudFunction('hello');
    final Map<String, String> params = <String, String>{'plan': 'paid'};
    function.execute(parameters: params);
  }

  Future<void> getConfigs() async {
    final ParseConfig config = ParseConfig();
    final ParseResponse addResponse =
        await config.addConfig('TestConfig', 'testing');

    if (addResponse.success) {
      print('Added a config');
    }

    final ParseResponse getResponse = await config.getConfigs();

    if (getResponse.success) {
      print('We have our configs.');
    }
  }

  //Create a temporary file in local storage for upload in Parse
  Future<File> _downloadFile(String url, String filename) async {
    final http.Client _client = http.Client();
    final http.Response req = await _client.get(Uri.parse(url));
    final Uint8List bytes = req.bodyBytes;
    final String dir = (await getApplicationDocumentsDirectory()).path;
    final File file = File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
