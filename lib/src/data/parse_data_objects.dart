part of flutter_parse_sdk;

class ParseDataObjects {
  static ParseDataObjects _instance;

  static ParseDataObjects get instance => _instance;

  static void init(objects) =>
      _instance ??= ParseDataObjects._init(objects);

  Map<ParseObject, String> objects;

  ParseDataObjects._init(this.objects);

  factory ParseDataObjects() => _instance;

  @override
  String toString() => "";
}
