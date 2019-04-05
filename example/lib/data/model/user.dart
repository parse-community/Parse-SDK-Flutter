import 'dart:core';

import 'package:parse_server_sdk/parse_server_sdk.dart';

class User extends ParseUser implements ParseCloneable {
  User(String username, String password, String emailAddress)
      : super(username, password, emailAddress);

  User.clone() : this(null, null, null);

  @override
  User clone(Map<String, dynamic> map) => User.clone()..fromJson(map);

  static const String keyDob = 'DOB';
  static const String keyGender = 'Gender';
  static const String keyHeight = 'Height';
  static const String keyFirebaseID = 'FirebaseID';
  static const String keyName = 'Name';
  static const String keyDisplayPicture = 'DisplayPicture';
  static const String keyProUser = 'ProUser';

  DateTime get dob => get<DateTime>(keyDob);
  set dob(DateTime dob) => set<DateTime>(keyDob, dob);

  num get gender => get<num>(keyGender);
  set gender(num gender) => set<num>(keyGender, gender);

  num get height => get<num>(keyHeight);
  set height(num height) => set<num>(keyHeight, height);

  String get firebaseId => get<String>(keyHeight);
  set firebaseId(String firebaseId) => set<String>(keyHeight, firebaseId);

  String get name => get<String>(keyName);
  set name(String name) => set<String>(keyName, name);

  String get displayPicture => get<String>(keyDisplayPicture);
  set displayPicture(String displayPicture) =>
      set<String>(keyDisplayPicture, displayPicture);

  bool get proUser => get<bool>(keyProUser);
  set proUser(bool proUser) => set<bool>(keyProUser, proUser);
}
