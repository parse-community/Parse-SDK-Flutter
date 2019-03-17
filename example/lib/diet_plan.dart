import 'dart:core';

import 'package:parse_server_sdk/parse_server_sdk.dart';

class DietPlan extends ParseObject implements ParseCloneable {
  DietPlan() : super(_keyTableName);
  DietPlan.clone() : this();

  /// Looks strangely hacky but due to Flutter not using reflection, we have to
  /// mimic a clone
  @override
  DietPlan clone(Map<String, dynamic> map) => DietPlan.clone()..fromJson(map);

  static const String _keyTableName = 'Diet_Plans';
  static const String keyName = 'Name';
  static const String keyDescription = 'Description';
  static const String keyProtein = 'Protein';
  static const String keyCarbs = 'Carbs';
  static const String keyFat = 'Fat';
  static const String keyStatus = 'Status';

  String get name => get<String>(keyName);
  set name(String name) => set<String>(keyName, name);

  String get description => get<String>(keyDescription);
  set description(String description) => set<String>(keyDescription, name);

  int get protein => get<int>(keyProtein);
  set protein(int protein) => super.set<int>(keyProtein, protein);

  int get carbs => get<int>(keyCarbs);
  set carbs(int carbs) => set<int>(keyCarbs, carbs);

  int get fat => get<int>(keyFat);
  set fat(int fat) => set<int>(keyFat, fat);

  int get status => get<int>(keyStatus);
  set status(int status) => set<int>(keyStatus, status);
}
