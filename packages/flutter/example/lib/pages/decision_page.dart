import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_api_diet_plan.dart';
import 'package:flutter_plugin_example/domain/constants/application_constants.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

import 'home_page.dart';
import 'login_page.dart';

class DecisionPage extends StatefulWidget {
  const DecisionPage({Key? key}) : super(key: key);

  @override
  State<DecisionPage> createState() => _DecisionPageState();
}

class _DecisionPageState extends State<DecisionPage> {
  String _parseServerState = 'Checking Parse Server...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initParse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _showLogo(),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: Text(_parseServerState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showLogo() {
    return Hero(
      tag: 'hero',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/parse.png'),
        ),
      ),
    );
  }

  Future<void> _initParse() async {
    try {
      await Parse().initialize(keyParseApplicationId, keyParseServerUrl,
          clientKey: keyParseClientKey, debug: true);
      final ParseResponse response = await Parse().healthCheck();
      if (response.success) {
        ParseUser? user = await ParseUser.currentUser();
        if (user != null) {
          _redirectToPage(context as dynamic, HomePage(DietPlanProviderApi()));
        } else {
          _redirectToPage(context as dynamic, const LoginPage());
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

  Future<void> _redirectToPage(dynamic context, Widget page) async {
    final MaterialPageRoute<bool> newRoute =
        MaterialPageRoute<bool>(builder: (BuildContext context) => page);

    final bool? nav = await Navigator.of(context)
        .pushAndRemoveUntil<bool>(newRoute, ModalRoute.withName('/'));
    if (nav == true) {
      _initParse();
    }
  }
}
