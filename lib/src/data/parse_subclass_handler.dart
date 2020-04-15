part of flutter_parse_sdk;

typedef ObjectConstructor = ParseObject Function();
typedef ParseUserConstructor = ParseUser Function(
    String username, String password, String emailAddress,
    {String sessionToken, bool debug, ParseHTTPClient client});

class ParseSubClassHandler {
  final Map<String, ObjectConstructor> _subClassMap =
      Map<String, ObjectConstructor>();
  ParseUserConstructor _parseUserConstructor;

  void registerSubClass(String className, ObjectConstructor objectConstructor) {
    if (className != keyClassUser &&
        className != keyClassInstallation &&
        className != keyClassSession)
      _subClassMap.putIfAbsent(className, () => objectConstructor);
  }

  void registerUserSubClass(ParseUserConstructor parseUserConstructor) {
    _parseUserConstructor ??= parseUserConstructor;
  }

  ParseObject createObject(String classname) {
    if (classname == keyClassUser) return createParseUser(null, null, null);
    if (_subClassMap.containsKey(classname)) return _subClassMap[classname]();
    return ParseObject(classname);
  }

  ParseUser createParseUser(
      String username, String password, String emailAddress,
      {String sessionToken, bool debug, ParseHTTPClient client}) {
    return _parseUserConstructor != null
        ? _parseUserConstructor(username, password, emailAddress,
            sessionToken: sessionToken, debug: debug, client: client)
        : ParseUser(username, password, emailAddress,
            sessionToken: sessionToken, debug: debug, client: client);
  }
}
