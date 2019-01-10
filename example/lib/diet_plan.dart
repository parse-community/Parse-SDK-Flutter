import 'dart:convert';
import 'dart:core';

import 'package:parse_server_sdk/parse.dart';

class DietPlan extends ParseObject implements ParseCloneable {
  DietPlan() : super(DIET_PLAN);
  DietPlan.clone(): this();

  /// Looks strangely hacky but due to Flutter not using reflection, we have to
  /// mimic a clone
  @override clone(Map map) => DietPlan.clone()..fromJson(map);

  static const String DIET_PLAN = 'Diet_Plans';
  static const String NAME = 'Name';
  static const String DESCRIPTION = 'Description';
  static const String PROTEIN = 'Protein';
  static const String CARBS = 'Carbs';
  static const String FAT = 'Fat';
  static const String STATUS = 'Status';

  String get name => get<String>(NAME);
  set name(String name) => set<String>(NAME, name);

  String get description => get<String>(DESCRIPTION);
  set description(String description) => set<String>(DESCRIPTION, name);

  int get protein => get<int>(PROTEIN);
  set protein(int protein) => super.set<int>(PROTEIN, protein);

  int get carbs => get<int>(CARBS);
  set carbs(int carbs) => set<int>(CARBS, carbs);

  int get fat => get<int>(FAT);
  set fat(int fat) => set<int>(FAT, fat);

  int get status => get<int>(STATUS);
  set status(int status) => set<int>(STATUS, status);

  @override
  String toString() {
    return toJson().toString();
  }
}
