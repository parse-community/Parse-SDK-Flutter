part of flutter_parse_sdk;

class ParseSession extends ParseObject implements ParseCloneable {
  ParseSession({bool debug, ParseHTTPClient client}) : super(keyClassSession) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId: true,
            securityContext: ParseCoreData().securityContext);
  }

  @override
  ParseSession clone(Map<String, dynamic> map) {
    return fromJson(map);
  }

  String get sessionToken => super.get<String>(keyVarSessionToken);

  ParseObject get user => super.get<ParseObject>(keyVarUser);

  Map<String, dynamic> get createdWith =>
      super.get<Map<String, dynamic>>(keyVarCreatedWith);

  bool get restricted => super.get<bool>(keyVarRestricted);

  DateTime get expiresAt => super.get<DateTime>(keyVarExpiresAt);

  String get installationId => super.get<String>(keyVarInstallationId);

  Future<ParseResponse> getCurrentSessionFromServer() async {
    try {
      final Uri tempUri = Uri.parse(_client.data.serverUrl);

      final Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: '${tempUri.path}$keyEndPointSessions/me');

      final Response response = await _client.get(url);

      return handleResponse<ParseSession>(
          this, response, ParseApiRQ.logout, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.logout, _debug, className);
    }
  }
}
