import 'dart:core';

import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class Day extends ParseObject implements ParseCloneable {
  Day() : super(_keyTableName);

  Day.clone() : this();

  @override
  Day clone(Map<String, dynamic> map) => Day.clone()..fromJson(map);

  @override
  Day fromJson(Map<String, dynamic> objectData) {
    super.fromJson(objectData);
    if (objectData.containsKey(keyOwner)) {
      owner = User.clone().fromJson(objectData[keyOwner]);
    }
    return this;
  }

  static const String _keyTableName = 'FoodDiary_Day';
  static const String keyDate = 'Date';
  static const String keyOwner = 'Owner';
  static const String keyStatus = 'Status';

  DateTime get date => get<DateTime>(keyDate);

  set date(DateTime date) => set<DateTime>(keyDate, date);

  User get owner => get<User>(keyOwner);

  set owner(User owner) => set<User>(keyOwner, owner);

  int get status => get<int>(keyStatus);

  set status(int status) => set<int>(keyStatus, status);
}
