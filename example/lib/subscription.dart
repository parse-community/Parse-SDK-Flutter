import 'package:parse_server_sdk/parse.dart';

class SubscriptionParse extends ParseObject implements ParseCloneable {
  SubscriptionParse() : super(_keyTableName);
  SubscriptionParse.clone() : this();

  @override
  clone(Map map) => SubscriptionParse.clone()..fromJson(map);

  static const String _keyTableName = 'Subscription';
  static const String _keyObjectID = 'objectId';
  static const String _keyOperator = 'operator';
  static const String _keyName = 'name';
  static const String _keyDescription = 'description';
  static const String _keyLogo = 'logo';

  String get name => get<String>(_keyName);
  set name(String name) => set<String>(_keyName, name);

  String get description => get<String>(_keyDescription);
  set description(String name) => set<String>(_keyDescription, description);

  String get logo => get<String>(_keyLogo);
  set logo(String logo) => set<String>(_keyLogo, logo);

  String get objectId => get<String>(_keyObjectID);
  set objectId(String objectId) => set<String>(_keyObjectID, objectId);

  String get operatorID => get(_keyOperator).toString();
  set operatorID(String operator) => set<String>(_keyOperator, operator);
}