import 'dart:core';

import 'package:parse_server_sdk/parse.dart';

class DietPlan extends ParseObject {
  DietPlan() : super(DIET_PLAN);

  String name;
  String description;
  num protein;
  num carbs;
  num fat;
  num status;

  static const String DIET_PLAN = 'Diet_Plans';
  static const String NAME = 'Name';
  static const String DESCRIPTION = 'Description';
  static const String PROTEIN = 'Protein';
  static const String CARBS = 'Carbs';
  static const String FAT = 'Fat';
  static const String STATUS = 'Status';

  @override
  dynamic fromJson(Map objectData) {
    this.name = objectData[NAME];
    this.description = objectData[DESCRIPTION];
    this.protein = objectData[PROTEIN];
    this.carbs = objectData[CARBS];
    this.fat = objectData[FAT];
    this.status = objectData[STATUS];
    return this;
  }

  Map<String, dynamic> toJson() => {
        NAME: name,
        DESCRIPTION: description,
        PROTEIN: protein,
        CARBS: carbs,
        FAT: fat,
        STATUS: status,
      };

  @override
  String toString() {
    return toJson().toString();
  }

  @override
  dynamic copy() {
    return DietPlan();
  }
}
