import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/domain/constants/application_constants.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'home_page.dart';
import 'login_page.dart';

class DecisionPage extends StatefulWidget {
  @override
  _DecisionPageState createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage> {
  String _parseServerState = 'Checking Parse Server...';

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParse();
    });
    return Scaffold(
      body: Container(
        child: Center(
          child: Text(_parseServerState),
        ),
      ),
    );
  }

  Future<void> _initParse() async {
    try {
      Parse().initialize(keyParseApplicationId, keyParseServerUrl,
          masterKey: keyParseMasterKey, debug: true);
      final ParseResponse response = await Parse().healthCheck();

      if (response.success) {
        final ParseUser user = await ParseUser.currentUser();
        if (user != null) {
          _redirectToPage(context, HomePage());
        } else {
          _redirectToPage(context, LoginPage());
        }
      } else {
        setState(() {
          _parseServerState =
              'Parse Server Not avaiable\n due to ${response.error.toString()}';
        });
      }
    } catch (e) {
      setState(() {
        _parseServerState = e.toString();
      });
    }
  }

  void _redirectToPage(BuildContext context, Widget page) {
    final MaterialPageRoute newRoute =
        MaterialPageRoute<void>(builder: (BuildContext context) => page);

    Navigator.of(context)
        .pushAndRemoveUntil<void>(newRoute, ModalRoute.withName('/'));
  }
}
