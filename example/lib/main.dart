import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/application_constants.dart';
import 'package:flutter_plugin_example/diet_plan.dart';
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
    Parse().initialize(ApplicationConstants.keyParseApplicationId,
        ApplicationConstants.keyParseServerUrl,
        masterKey: ApplicationConstants.keyParseMasterKey, debug: true);

    // Check server is healthy and live - Debug is on in this instance so check logs for result
    var response = await Parse().healthCheck();
    if (response.success) {
      runTestQueries();
    } else {
      print("Server health check failed");
    }
  }

  runTestQueries() {
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

  void createItem() async {
    var newObject = ParseObject('TestObjectForApi');
    newObject.set<String>('name', 'testItem');
    newObject.set<int>('age', 26);

    var apiResponse = await newObject.create();

    if (apiResponse.success && apiResponse.result != null) {
      print(ApplicationConstants.keyAppName +
          ": " +
          apiResponse.result.toString());
    }
  }

  void getAllItemsByName() async {
    var apiResponse = await ParseObject('TestObjectForApi').getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (var testObject in apiResponse.result) {
        print(ApplicationConstants.keyAppName + ": " + testObject.toString());
      }
    }
  }

  void getAllItems() async {
    var apiResponse = await DietPlan().getAll();

    if (apiResponse.success && apiResponse.result != null) {
      for (var plan in apiResponse.result) {
        print(ApplicationConstants.keyAppName + ": " + (plan as DietPlan).name);
      }
    } else {
      print(ApplicationConstants.keyAppName + ": " + apiResponse.error.message);
    }
  }

  void getSingleItem() async {
    var apiResponse = await DietPlan().getObject('R5EonpUDWy');

    if (apiResponse.success && apiResponse.result != null) {
      var dietPlan = (apiResponse.result as DietPlan);

      // Shows example of storing values in their proper type and retrieving them
      dietPlan.set<int>('RandomInt', 8);
      var randomInt = dietPlan.get<int>('RandomInt');

      if (randomInt is int) print('Saving generic value worked!');

      // Shows example of pinning an item
      dietPlan.pin();

      // shows example of retrieving a pin
      var newDietPlanFromPin = DietPlan().fromPin('R5EonpUDWy');
      if (newDietPlanFromPin != null) print('Retreiving from pin worked!');
    } else {
      print(ApplicationConstants.keyAppName + ": " + apiResponse.error.message);
    }
  }

  void query() async {
    var queryBuilder =
        QueryBuilder<ParseObject>(ParseObject('TestObjectForApi'))
          ..whereEqualTo('age', 26)
          ..includeObject(['Day']);

    var apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.result != null) {
      print(
          "Result: ${((apiResponse.result as List<dynamic>).first as ParseObject).toString()}");
    } else {
      print("Result: ${apiResponse.error.message}");
    }
  }

  initUser() async {
    // All return type ParseUser except all
    var user =
        ParseUser("TestFlutter", "TestPassword123", "phill.wiggins@gmail.com");
    var response = await user.signUp();
    if (response.success) user = response.result;

    response = await user.login();
    if (response.success) user = response.result;

    response = await user.requestPasswordReset();
    if (response.success) user = response.result;

    response = await user.verificationEmailRequest();
    if (response.success) user = response.result;

    user = null;
    // Best practice for starting the app. This will check for a valid user
    user = await ParseUser.currentUser();
    await user.logout();
    user = await ParseUser.currentUser();

    response = await ParseUser.getCurrentUserFromServer();
    if (response.success) user = response.result;

    response = await user.save();
    if (response.success) user = response.result;

    var destroyResponse = await user.destroy();
    if (destroyResponse.success) print('object has been destroyed!');

    // Returns type ParseResponse as its a query, not a single result
    response = await ParseUser.all();
    if (response.success) user = response.result;

    var queryBuilder = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereStartsWith(ParseUser.keyUsername, 'phillw');

    var apiResponse = await queryBuilder.query();
    if (apiResponse.success) user = response.result;
  }

  function() async {
    var user =
        ParseUser("TestFlutter", "TestPassword123", "TestFlutterSDK@gmail.com");
    await user.signUp();
    var loginResponse = await user.login();
    if (loginResponse.success) user = loginResponse.result;

    var customClient = ParseHTTPClient();
    customClient.additionalHeaders = {
      keyHeaderSessionToken: ParseCoreData().sessionId
    };
    var function = ParseCloudFunction('hello', client: customClient);
    function.execute();

    user.destroy();
  }

  functionWithParameters() async {
    var function = ParseCloudFunction('hello');
    var params = {'plan': 'paid'};
    function.execute(parameters: params);
  }

  Future getConfigs() async {
    var config = ParseConfig();
    var addResponse = await config.addConfig('TestConfig', 'testing');

    if (addResponse.success) {
      print("Added a config");
    }

    var getResponse = await config.getConfigs();

    if (getResponse.success) {
      print("We have our configs.");
    }
  }
}
