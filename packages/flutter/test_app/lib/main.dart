import 'dart:math';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  _MyAppState()
      : initFuture = CoreStoreSharedPrefsImp.getInstance().then(
          (CoreStore coreStore) => Parse().initialize(
            'Parse-Demo',
            'https://parse-demo.thomax-it.com/parseserver',
            clientKey: 'jyHsBFje6ShMWe6TW3FXQtuWW87HWPLx2YHFCWKS9ua8FY8nbT',
            liveQueryUrl: 'https://parse-demo.thomax-it.com/parseserver',
            autoSendSessionId: true,
            coreStore: coreStore,
            debug: true,
          ),
        );

  final Future<Parse> initFuture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login test',
      home: FutureBuilder<Parse>(
        future: initFuture,
        builder: (BuildContext context, AsyncSnapshot<Parse> snapshot) {
          if (snapshot.hasData) {
            return MyLoginPage(title: 'Flutter Demo Home Page');
          } else {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}

class MyLoginPage extends StatelessWidget {
  MyLoginPage({Key key, this.title})
      : _rnd = Random(),
        super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          OutlineButton(
            onPressed: () async {
              signUp(
                  username: getRandomString(10),
                  pass: getRandomString(10),
                  email: "${getRandomString(10)}@example.com");
              // final ParseUser user = ParseUser(getRandomString(10),
              //     getRandomString(10), "${getRandomString(10)}@example.com");
              // print('method signIn, user is: $user');
              //
              // final ParseResponse response = await user.signUp();
              // print(
              //     'auth_service_parse.dart, method signIn, response is: ${response}');
              //
              // if (response.success) {
              //   print('user logged in with id: ${user.objectId}');
              //   return user;
              // } else {
              //   print('user logging in error: ${response.error.message}');
              // }
              //
              // print('user sign in is null');
              // return null;
            },
            child: const Text("sign up"),
          ),
          RaisedButton(
            onPressed: () async {
              final ParseUser user = ParseUser(
                  "${getRandomString(10)}@example.com",
                  getRandomString(10),
                  "${getRandomString(10)}@example.com");
              print('method signIn, user is: $user');

              user.signUp().then((singUpResponse) async {
                print('singUpResponse: ${singUpResponse.success}');

                ParseResponse response = await user.login();
                print(
                    'auth_service_parse.dart, method signIn, response is: ${response.success}');

                if (response.success) {
                  print('user logged in with id: ${user.objectId}');
                  return user;
                } else {
                  print('user logging in error: ${response.error.message}');
                }

                print('user sign in is null');
                return null;
              });
            },
            child: const Text("sign up 2"),
          ),
        ],
      ),
    );
  }

  static const String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd;

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  void signUp({String email, String pass, String username}) async {
    print("SignUp started");
    ParseUser user = ParseUser.createUser(username, pass, email);
    print(user);
    ParseResponse response = await user.signUp();
    print(response);
    if (response.success) {
      print("SignUp Success");
    }
  }
}
