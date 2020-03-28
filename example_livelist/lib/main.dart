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

  QueryBuilder<ParseObject> _queryBuilder;

  @override
  void initState() {
    super.initState();
    initData().then((bool success) {
      setState(() {
        initFailed = !success;
        if (success)
          _queryBuilder = QueryBuilder<ParseObject>(ParseObject('Test'))
            ..orderByAscending('order')
            ..whereNotEqualTo('show', false);
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
          title: const Text('LiveList example app'),
        ),
        body: initFailed == false
            ? buildBody(context)
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
        clientKey: keyParseClientKey,
        debug: keyDebug,
        liveQueryUrl: keyParseLiveServerUrl);

    return (await Parse().healthCheck()).success;
  }

  Widget buildBody(BuildContext context) {
    final GlobalKey<_ObjectFormState> objectFormKey =
        GlobalKey<_ObjectFormState>();
    return Column(
      children: <Widget>[
        Expanded(
          child: ParseLiveListWidget<ParseObject>(
              query: _queryBuilder,
              duration: const Duration(seconds: 1),
              childBuilder: (BuildContext context,
                  ParseLiveListElementSnapshot<ParseObject> snapshot) {
                if (snapshot.failed) {
                  return const Text('something went wrong!');
                } else if (snapshot.hasData) {
                  return ListTile(
                    title: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                              snapshot.loadedData.get<int>('order').toString()),
                          flex: 1,
                        ),
                        Flexible(
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              snapshot.loadedData.get<String>('text'),
                            ),
                          ),
                          flex: 10,
                        ),
                      ],
                    ),
                    onLongPress: () {
                      objectFormKey.currentState.setObject(snapshot.loadedData);
                    },
                  );
                } else {
                  return const ListTile(
                    leading: CircularProgressIndicator(),
                  );
                }
              }),
        ),
        Container(
          color: Colors.black12,
          child: ObjectForm(
            key: objectFormKey,
          ),
        )
      ],
    );
  }
}

class ObjectForm extends StatefulWidget {
  const ObjectForm({Key key}) : super(key: key);

  @override
  _ObjectFormState createState() => _ObjectFormState();
}

class _ObjectFormState extends State<ObjectForm> {
  ParseObject _currentObject;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void setObject(ParseObject object) {
    setState(() {
      _currentObject = object;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _currentObject == null
        ? Container()
        : Form(
            key: _formKey,
            child: ListTile(
              key: UniqueKey(),
              title: Row(
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _currentObject.get<int>('order').toString(),
                      keyboardType: TextInputType.number,
                      onSaved: (String value) {
                        _currentObject.set('order', int.parse(value));
                      },
                    ),
                  ),
                  Flexible(
                    flex: 10,
                    child: TextFormField(
                      initialValue: _currentObject.get<String>('text'),
                      onSaved: (String value) {
                        _currentObject.set('text', value);
                      },
                    ),
                  )
                ],
              ),
              trailing: IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    setState(() {
                      _formKey.currentState.save();
                      final ParseObject object = _currentObject;
                      //Delay to highlight the animation.
                      Future<void>.delayed(const Duration(seconds: 1))
                          .then((_) {
                        object.save();
                      });
                      _currentObject = null;
                    });
                  }),
            ),
          );
  }
}
