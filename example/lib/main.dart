import 'dart:convert';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/repository_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/user/repository_user.dart';
import 'package:flutter_plugin_example/domain/constants/application_constants.dart';
import 'package:flutter_plugin_example/domain/utils/db_utils.dart';
import 'package:json_table/json_table.dart';
// import 'package:flutter_stetho/flutter_stetho.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() {
  // Stetho.initialize();
  _setTargetPlatformForDesktop();

  runApp(MyApp());
}

void _setTargetPlatformForDesktop() {
  TargetPlatform targetPlatform;
  if (Platform.isMacOS) {
    targetPlatform = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    targetPlatform = TargetPlatform.android;
  }
  if (targetPlatform != null) {
    debugDefaultTargetPlatformOverride = targetPlatform;
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with AutomaticKeepAliveClientMixin {
  DietPlanRepository dietPlanRepo;
  UserRepository userRepo;
  // Map<String, dynamic> _result;
  List<Map<String, dynamic>> _result = [];

  String info = "";
  String text = '';
  LiveQuery liveQuery;
  @override
  void initState() {
    super.initState();
    initData();
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Parse sdk live test'),
          ),
          body: Container(
            margin: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                // JsonTable(
                //   jsonDecode(_result.isEmpty ? "[{}]" : _result[0].toString()),
                //   tableHeaderBuilder: (String header) {
                //     return Container(
                //       padding:
                //           EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                //       decoration: BoxDecoration(
                //           border: Border.all(width: 0.5),
                //           color: Colors.grey[300]),
                //       child: Text(
                //         header,
                //         textAlign: TextAlign.center,
                //         style: Theme.of(context).textTheme.display1.copyWith(
                //             fontWeight: FontWeight.w700,
                //             fontSize: 14.0,
                //             color: Colors.black87),
                //       ),
                //     );
                //   },
                //   tableCellBuilder: (dynamic value) {
                //     return Container(
                //       padding:
                //           EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                //       decoration: BoxDecoration(
                //           border: Border.all(
                //               width: 0.5, color: Colors.grey.withOpacity(0.5))),
                //       child: Text(
                //         value,
                //         textAlign: TextAlign.center,
                //         style: Theme.of(context)
                //             .textTheme
                //             .display1
                //             .copyWith(fontSize: 14.0, color: Colors.grey[900]),
                //       ),
                //     );
                //   },
                // ),
                Flexible(
                    child: ListView(
                  children:
                      _result.map((location) => _ResultItem(location)).toList(),
                )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // Button(label: '开始监听', onPressed: _listen()),
                    RaisedButton(
                        onPressed: () {
                          updateSingleItem(context);
                        },
                        color: Colors.blue[400],
                        child: new Text('更新',
                            style: new TextStyle(color: Colors.white))),
                  ],
                ),
                // RaisedButton(
                //     onPressed: () {
                //       _listen();
                //     },
                //     color: Colors.blue[400],
                //     child:
                //         new Text('开始监听', style: new TextStyle(color: Colors.white))),
                // RaisedButton(
                //     onPressed: () {
                //       _change(context);
                //     },
                //     color: Colors.blue[400],
                //     child:
                //         new Text('修改数据', style: new TextStyle(color: Colors.white))),
              ],
            ),
          )),
    );
  }

  Future<void> _listen() async {
    QueryBuilder<ParseObject> query = QueryBuilder<ParseObject>(DietPlan())
      ..whereEqualTo('objectId', 'jSH0CHYwjL');
    // LiveQuery liveQuery = LiveQuery();
    // print("=====query: $query");
    await liveQuery.subscribe(query);

    liveQuery.on(LiveQueryEvent.update, (dynamic value) {
      print("监听数据连接成功，开始订阅消息！");

      print('*** UPDATE ***: ${DateTime.now().toString()}\n $value');
      print((value as ParseObject).objectId);
      print((value as ParseObject).updatedAt);
      print((value as ParseObject).createdAt);
      // print((value as ParseObject).get('objectId'));
      // print((value as ParseObject).get('updatedAt'));
      // print((value as ParseObject).get('createdAt'));

      print("监听到数据变化：" + (value as ParseObject).toJson().toString());
      // _result.add(value);
    });
  }

  Future<void> updateSingleItem(BuildContext context) async {
    final ParseResponse apiResponse = await DietPlan().getObject('jSH0CHYwjL');

    if (apiResponse.success && apiResponse.count > 0) {
      final DietPlan dietPlan = apiResponse.result;

      // Shows example of storing values in their proper type and retrieving them
      var s = new WordPair.random().asPascalCase;
      dietPlan.set<String>('Name', s);
      await dietPlan.save();
      // await createItem();
      // Shows example of pinning an item
      // await dietPlan.pin();

      // shows example of retrieving a pin
      setState(() {});
    } else {
      print(keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> initData() async {
    // Initialize repository
    await initRepository();

    // Initialize parse
    Parse().initialize(keyParseApplicationId, keyParseServerUrl,
        masterKey: keyParseMasterKey,
        liveQueryUrl: keyParseLiveServerUrl,
        // clientKey: "XXXi3GejX3SIxpDgSbKHHV8uHUUP3QGiPPTlxxxx",
        sessionId: "1212121",
        autoSendSessionId: true,
        debug: true);
    // ParseHTTPClient client = ParseHTTPClient();

    liveQuery = LiveQuery();
    //parse serve with secure store and desktop support

    //    Parse().initialize(keyParseApplicationId, keyParseServerUrl,
    //        masterKey: keyParseMasterKey,
    //        debug: true,
    //        coreStore: CoreStoreImp.getInstance());

    // Check server is healthy and live - Debug is on in this instance so check logs for result
    final ParseResponse response = await Parse().healthCheck();

    if (response.success) {
      // await _listen();
      QueryBuilder<ParseObject> query = QueryBuilder<ParseObject>(DietPlan())
        ..whereEqualTo('objectId', 'jSH0CHYwjL');
      // LiveQuery liveQuery = LiveQuery();
      // print("=====query: $query");
      await liveQuery.subscribe(query);

      await liveQuery.on(LiveQueryEvent.update, (dynamic value) {
        print("监听数据连接成功，开始订阅消息！");

        print('*** UPDATE ***: ${DateTime.now().toString()}\n $value');
        print((value as ParseObject).objectId);
        print((value as ParseObject).updatedAt);
        print((value as ParseObject).createdAt);
        print((value as ParseObject).get<String>('Name'));
        // print((value as ParseObject).get('updatedAt'));
        // print((value as ParseObject).get('createdAt'));
        _result.clear();
        print("监听到数据变化：" + (value as ParseObject).toJson().toString());
        _result.add(value.toJson());
        print(_result.toString());
      });
      // await runTestQueries();
      // text += 'runTestQueries\n';
      // print(text);
    } else {
      text += 'Server health check failed';
      print(text);
    }
  }

  Future<void> runTestQueries() async {
    // Basic repository example
    await repositoryAddUser();
    await repositoryAddItems();
    await repositoryGetAllItems();

    //Basic usage
    await createItem();
    await getAllItems();
    await getAllItemsByName();
    await getSingleItem();
    await getConfigs();
    await query();
    await initUser();
    await initInstallation();
    await function();
    await functionWithParameters();
    await test();
  }

  Future<void> initInstallation() async {
    final ParseInstallation installation =
        await ParseInstallation.currentInstallation();
    final ParseResponse response = await installation.create();
    print(response);
  }

  Future<void> test() async {
    User user = User('unreal0', 'hhhhhh', 'unreal0@sina.cn');
    final ParseResponse signUpResponse = await user.signUp();

    if (signUpResponse.success) {
      user = signUpResponse.result;
    } else {
      final ParseResponse loginResponse = await user.login();

      if (loginResponse.success) {
        user = loginResponse.result;
      }
    }

    final QueryBuilder<DietPlan> query = QueryBuilder<DietPlan>(DietPlan())
      ..whereEqualTo(keyProtein, 30);
    final ParseResponse item = await query.query();
    print(item.toString());
  }

  Future<void> createItem() async {
    final ParseObject newObject = ParseObject('TestObjectForApi');
    newObject.set<String>('name', 'testItem');
    newObject.set<int>('age', 26);

    final ParseResponse apiResponse = await newObject.create();

    if (apiResponse.success && apiResponse.count > 0) {
      print(keyAppName + ': ' + apiResponse.result.toString());
    }
  }

  Future<void> getAllItemsByName() async {
    final ParseResponse apiResponse =
        await ParseObject('TestObjectForApi').getAll();

    if (apiResponse.success && apiResponse.count > 0) {
      for (final ParseObject testObject in apiResponse.results) {
        print(keyAppName + ': ' + testObject.toString());
      }
    }
  }

  Future<void> getAllItems() async {
    final ParseResponse apiResponse = await DietPlan().getAll();

    if (apiResponse.success && apiResponse.count > 0) {
      for (final DietPlan plan in apiResponse.results) {
        print(keyAppName + ': ' + plan.name);
      }
    } else {
      print(keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> getSingleItem() async {
    final ParseResponse apiResponse = await DietPlan().getObject('B0xtU0Ekqi');

    if (apiResponse.success && apiResponse.count > 0) {
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
      print(keyAppName + ': ' + apiResponse.error.message);
    }
  }

  Future<void> query() async {
    final QueryBuilder<ParseObject> queryBuilder =
        QueryBuilder<ParseObject>(ParseObject('TestObjectForApi'))
          ..whereLessThan(keyVarCreatedAt, DateTime.now());

    final ParseResponse apiResponse = await queryBuilder.query();

    if (apiResponse.success && apiResponse.count > 0) {
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
    if (response?.success ?? false) {
      user = response.result;
    }

    /// log user out
    response = await user?.logout();
    if (response?.success ?? false) {
      user = response.result;
    }

    user = await ParseUser.currentUser();

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

    // Returns type ParseResponse as its a query, not a single result
    response = await ParseUser.all();
    if (response.success) {
      // We have a list of all users (LIMIT SET VIA SDK)
      print(response.results);
    }

    final QueryBuilder<ParseUser> queryBuilder =
        QueryBuilder<ParseUser>(ParseUser.forQuery())
          ..whereStartsWith(ParseUser.keyUsername, 'phillw');

    final ParseResponse apiResponse = await queryBuilder.query();
    if (apiResponse.success && apiResponse.count > 0) {
      final List<ParseUser> users = response.result;
      for (final ParseUser user in users) {
        print(keyAppName + ': ' + user.toString());
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

  Future<void> repositoryAddUser() async {
    final User user = User('test_username', 'password', 'test@gmail.com');

    final ApiResponse response = await userRepo.save(user);

    if (!response.success) {
      await userRepo.login(user);
    }

    final User currentUser =
        await ParseUser.currentUser(customUserObject: User.clone());
    print(currentUser);
  }

  Future<void> repositoryAddItems() async {
    final List<DietPlan> dietPlans = <DietPlan>[];

    final List<dynamic> json = const JsonDecoder().convert(dietPlansToAdd);
    for (final Map<String, dynamic> element in json) {
      final DietPlan dietPlan = DietPlan().fromJson(element);
      dietPlans.add(dietPlan);
    }

    await initRepository();
    final ApiResponse response = await dietPlanRepo.addAll(dietPlans);
    if (response.success) {
      print(response.result);
    }
  }

  Future<void> repositoryGetAllItems() async {
    final ApiResponse response = await dietPlanRepo.getAll();
    if (response.success) {
      print(response.result);
    }
  }

  Future<void> initRepository() async {
    dietPlanRepo ??= DietPlanRepository.init(await getDB());
    userRepo ??= UserRepository.init(await getDB());
  }
}

const String dietPlansToAdd =
    '[{"className":"Diet_Plans","Name":"Textbook","Description":"For an active lifestyle and a straight forward macro plan, we suggest this plan.","Fat":25,"Carbs":50,"Protein":25,"Status":0},'
    '{"className":"Diet_Plans","Name":"Body Builder","Description":"Default Body Builders Diet","Fat":20,"Carbs":40,"Protein":40,"Status":0},'
    '{"className":"Diet_Plans","Name":"Zone Diet","Description":"Popular with CrossFit users. Zone Diet targets similar macros.","Fat":30,"Carbs":40,"Protein":30,"Status":0},'
    '{"className":"Diet_Plans","Name":"Low Fat","Description":"Low fat diet.","Fat":15,"Carbs":60,"Protein":25,"Status":0},'
    '{"className":"Diet_Plans","Name":"Low Carb","Description":"Low Carb diet, main focus on quality fats and protein.","Fat":35,"Carbs":25,"Protein":40,"Status":0},'
    '{"className":"Diet_Plans","Name":"Paleo","Description":"Paleo diet.","Fat":60,"Carbs":25,"Protein":10,"Status":0},'
    '{"className":"Diet_Plans","Name":"Ketogenic","Description":"High quality fats, low carbs.","Fat":65,"Carbs":5,"Protein":30,"Status":0}]';

class _ResultItem extends StatelessWidget {
  final Map<String, dynamic> _data;

  const _ResultItem(this._data, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            DateTime.now().toIso8601String(),
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(width: 4.0, height: 4.0),
          // Text(
          //   "$_data",
          //   style: TextStyle(color: Colors.black87),
          // ),
          Text(
            jsonFormat(_data),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String jsonFormat(Map<String, Object> json) {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }
}

// class DietPlan extends ParseObject {
//   DietPlan() : super(DIET_PLAN);

//   String name;
//   String description;
//   num protein;
//   num carbs;
//   num fat;
//   num status;

//   static const String DIET_PLAN = 'post';
//   static const String NAME = 'title';
//   // static const String DESCRIPTION = 'text';
//   // static const String PROTEIN = 'Protein';
//   // static const String CARBS = 'Carbs';
//   // static const String FAT = 'Fat';
//   // static const String STATUS = 'Status';

//   @override
//   dynamic fromJson(Map<String, dynamic> objectData) {
//     this.name = objectData[NAME];
//     // this.description = objectData[DESCRIPTION];
//     // this.protein = objectData[PROTEIN];
//     // this.carbs = objectData[CARBS];
//     // this.fat = objectData[FAT];
//     // this.status = objectData[STATUS];
//     return this;
//   }

//   // Map<String, dynamic> toJson() => {
//   //       NAME: name,
//   //       // DESCRIPTION: description,
//   //       // PROTEIN: protein,
//   //       // CARBS: carbs,
//   //       // FAT: fat,
//   //       // STATUS: status,
//   //     };

//   @override
//   String toString() {
//     return toJson().toString();
//   }

//   @override
//   dynamic copy() {
//     return DietPlan();
//   }
// }
