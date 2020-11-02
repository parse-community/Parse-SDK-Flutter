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
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();

    initFuture.then((_) async {
      final ParseUser currentUser = await ParseUser.currentUser();
      setState(() {
        loggedIn = currentUser != null;
        print(loggedIn);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login test',
      home: FutureBuilder<Parse>(
        future: initFuture,
        builder: (BuildContext context, AsyncSnapshot<Parse> snapshot) {
          if (snapshot.hasData) {
            if (!loggedIn) {
              return MyLoginPage(
                title: 'Flutter Demo Home Page',
                afterLogin: () {
                  setState(() {
                    loggedIn = true;
                  });
                },
              );
            } else {
              return HelloPage(
                afterLogout: () {
                  setState(() {
                    loggedIn = false;
                  });
                },
              );
            }
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

class HelloPage extends StatelessWidget {
  final VoidCallback afterLogout;

  const HelloPage({Key key, @required this.afterLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text('You are logged in!'),
            OutlineButton(
              onPressed: () async {
                (await ParseUser.currentUser() as ParseUser)
                    ?.logout()
                    ?.then((ParseResponse response) {
                  if (response.success) {
                    afterLogout();
                  }
                });
              },
              child: const Text('logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyLoginPage extends StatelessWidget {
  MyLoginPage({Key key, this.title, @required this.afterLogin})
      : _rnd = Random(),
        super(key: key);

  final String title;
  final VoidCallback afterLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: OutlineButton(
          onPressed: () async {
            final String email = '${getRandomString(10)}@example.com';
            final ParseResponse response =
                await ParseUser(email, getRandomString(10), email).signUp();
            print(
                'Sign up was ${!(response?.success ?? false) ? 'not ' : ''}success full. Response is ${response == null ? '' : 'not '}null.');
            if (response.success) {
              afterLogin();
            }
          },
          child: Text("sign up"),
        ),
      ),
    );
  }

  static const String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd;

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  void signUp({String email, String pass, String username}) async {
    print('SignUp started');
    ParseUser user = ParseUser.createUser(username, pass, email);
    print(user);
    final ParseResponse response = await user.signUp();
    print(response);
    if (response.success) {
      print('SignUp Success');
    }
  }
}
