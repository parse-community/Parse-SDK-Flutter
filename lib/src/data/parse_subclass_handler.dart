part of flutter_parse_sdk;

typedef ParseObjectConstructor = ParseObject Function();
typedef ParseUserConstructor = ParseUser Function(
    String username, String password, String emailAddress,
    {String sessionToken, bool debug, ParseHTTPClient client});

class ParseSubClassHandler {

  ParseSubClassHandler({Map<String, ParseObjectConstructor> registeredSubClassMap,
    ParseUserConstructor parseUserConstructor}){
    _subClassMap = registeredSubClassMap ?? Map<String, ParseObjectConstructor>();
    _parseUserConstructor = parseUserConstructor;
  }

  Map<String, ParseObjectConstructor> _subClassMap;
  ParseUserConstructor _parseUserConstructor;

  void registerSubClass(
      String className, ParseObjectConstructor objectConstructor) {
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
