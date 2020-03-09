import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'application_constants.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool initFailed;

  @override
  void initState() {
    super.initState();
    initData().then((bool initFailed) {
      setState(() {
        this.initFailed = initFailed;
      });
    }).catchError((dynamic _) {
      setState(() {
        initFailed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: initFailed == false
            ? const ParseLiveListWidget(
                query: null,
              )
            : Container(
                height: double.infinity,
                alignment: Alignment.center,
                child: initFailed == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          CircularProgressIndicator(),
                          Text('Connecting to the server...'),
                        ],
                      )
                    : const Text('Connecting to the server failed!'),
              ),
      ),
    );
  }

  Future<bool> initData() async {
    await Parse().initialize(keyParseApplicationId, keyParseServerUrl,
        masterKey: keyParseMasterKey,
        debug: true,
        coreStore: await CoreStoreSharedPrefsImp.getInstance());

    return (await Parse().healthCheck()).success;
  }
}
