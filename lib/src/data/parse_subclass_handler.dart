part of flutter_parse_sdk;

typedef ObjectConstructor = ParseObject Function();

class ParseSubClassHandler {
  final Map<String, ObjectConstructor> _subClassMap =
      Map<String, ObjectConstructor>();

  void registerSubClass(String className, ObjectConstructor objectConstructor) {
    _subClassMap.putIfAbsent(className, () => objectConstructor);
  }

  ParseObject createObject(String classname) {
    if (_subClassMap.containsKey(classname)) return _subClassMap[classname]();
    if (classname == '_User') return ParseUser._getEmptyUser();
    return ParseObject(classname);
  }
}
