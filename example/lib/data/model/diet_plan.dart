import 'dart:core';

import 'package:parse_server_sdk/parse_server_sdk.dart';

const String keyDietPlan = 'Diet_Plans';
const String keyName = 'Name';
const String keyDescription = 'Description';
const String keyProtein = 'Protein';
const String keyCarbs = 'Carbs';
const String keyFat = 'Fat';
const String keyStatus = 'Status';

class DietPlan extends ParseObject implements ParseCloneable {
  DietPlan() : super(keyDietPlan);
  DietPlan.clone() : this();

  @override
  DietPlan clone(Map<String, dynamic> map) => DietPlan.clone()..fromJson(map);

  String get name => get<String>(keyName);
  set name(String name) => set<String>(keyName, name);

  String get description => get<String>(keyDescription);
  set description(String description) => set<String>(keyDescription, name);

  num get protein => get<num>(keyProtein);
  set protein(num protein) => super.set<num>(keyProtein, protein);

  num get carbs => get<num>(keyCarbs);
  set carbs(num carbs) => set<num>(keyCarbs, carbs);

  num get fat => get<num>(keyFat);
  set fat(num fat) => set<num>(keyFat, fat);

  bool get status => get<bool>(keyStatus);

  set status(bool status) => set<bool>(keyStatus, status);
}
