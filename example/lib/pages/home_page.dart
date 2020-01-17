import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class HomePage extends StatefulWidget {
  const HomePage(this._dietPlanProvider);

  final DietPlanProviderContract _dietPlanProvider;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DietPlan> randomDietPlans = <DietPlan>[];

  @override
  void initState() {
    super.initState();
    final List<dynamic> json = const JsonDecoder().convert(dietPlansToAdd);
    for (final Map<String, dynamic> element in json) {
      final DietPlan dietPlan = DietPlan();
      element.forEach(
          (String k, dynamic v) => dietPlan.set<dynamic>(k, parseDecode(v)));
      randomDietPlans.add(dietPlan);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Parse Server demo'),
            actions: <Widget>[
              FlatButton(
                  child: Text('Logout',
                      style: TextStyle(fontSize: 17.0, color: Colors.white)),
                  onPressed: () async {
                    final ParseUser user = await ParseUser.currentUser();
                    user.logout(deleteLocalUserData: true);
                    Navigator.pop(context, true);
                  })
            ],
          ),
          body: _showDietList(),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final DietPlan dietPlan =
                  randomDietPlans[Random().nextInt(randomDietPlans.length - 1)];
              final ParseUser user = await ParseUser.currentUser();
              dietPlan.set('user', user);
              await widget._dietPlanProvider.add(dietPlan);
              setState(() {});
            },
            tooltip: 'Add Diet Plans',
            child: const Icon(Icons.add),
          )),
    );
  }

  Widget _showDietList() {
    return FutureBuilder<ApiResponse>(
        future: widget._dietPlanProvider.getAll(),
        builder: (BuildContext context, AsyncSnapshot<ApiResponse> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.success) {
              if (snapshot.data.results == null ||
                  snapshot.data.results.isEmpty) {
                return Center(
                  child: const Text('No Data'),
                );
              }
            }
            return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.results.length,
                itemBuilder: (BuildContext context, int index) {
                  final DietPlan dietPlan = snapshot.data.results[index];
                  final String id = dietPlan.objectId;
                  final String name = dietPlan.name;
                  final String description = dietPlan.description;
                  final bool status = dietPlan.status;
                  return Dismissible(
                    key: Key(id),
                    background: Container(color: Colors.red),
                    onDismissed: (DismissDirection direction) async {
                      widget._dietPlanProvider.remove(dietPlan);
                    },
                    child: ListTile(
                      title: Text(
                        name,
                        style: TextStyle(fontSize: 20.0),
                      ),
                      subtitle: Text(description),
                      trailing: IconButton(
                          icon: status
                              ? const Icon(
                                  Icons.done_outline,
                                  color: Colors.green,
                                  size: 20.0,
                                )
                              : const Icon(Icons.done,
                                  color: Colors.grey, size: 20.0),
                          onPressed: () async {
                            dietPlan.status = !dietPlan.status;
                            await dietPlan.save();
                            setState(() {});
                          }),
                    ),
                  );
                });
          } else {
            return Center(
              child: const Text('No Data'),
            );
          }
        });
  }

  String dietPlansToAdd =
      '[{"className":"Diet_Plans","Name":"Textbook","Description":"For an active lifestyle and a straight forward macro plan, we suggest this plan.","Fat":25,"Carbs":50,"Protein":25,"Status":false},'
      '{"className":"Diet_Plans","Name":"Body Builder","Description":"Default Body Builders Diet","Fat":20,"Carbs":40,"Protein":40,"Status":true},'
      '{"className":"Diet_Plans","Name":"Zone Diet","Description":"Popular with CrossFit users. Zone Diet targets similar macros.","Fat":30,"Carbs":40,"Protein":30,"Status":true},'
      '{"className":"Diet_Plans","Name":"Low Fat","Description":"Low fat diet.","Fat":15,"Carbs":60,"Protein":25,"Status":false},'
      '{"className":"Diet_Plans","Name":"Low Carb","Description":"Low Carb diet, main focus on quality fats and protein.","Fat":35,"Carbs":25,"Protein":40,"Status":true},'
      '{"className":"Diet_Plans","Name":"Paleo","Description":"Paleo diet.","Fat":60,"Carbs":25,"Protein":10,"Status":false},'
      '{"className":"Diet_Plans","Name":"Ketogenic","Description":"High quality fats, low carbs.","Fat":65,"Carbs":5,"Protein":30,"Status":true}]';
}
