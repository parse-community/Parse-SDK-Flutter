part of flutter_parse_sdk;

class ParseSubClassHandler {
  final Map<String, ParseObject> _subClassMap = Map<String, ParseObject>();

  void registerSubClass(String className, ParseObject cloneObject) {
    _subClassMap.putIfAbsent(className, () => cloneObject);
  }

  void
}
