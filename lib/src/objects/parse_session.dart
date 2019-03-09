part of flutter_parse_sdk;

class ParseSession extends ParseObject implements ParseCloneable {
  @override
  clone(Map map) {
    return this.fromJson(map);
  }

  static final String keyVarUser = 'user';
  static final String keyVarCreatedWith = 'createdWith';
  static final String keyVarRestricted = 'restricted';
  static final String keyVarExpiresAt = 'expiresAt';
  static final String keyVarInstallationId = 'installationId';

  String get sessionToken => super.get<String>(keyVarSessionToken);

  ParseObject get user => super.get<ParseObject>(keyVarUser);

  Map<String, dynamic> get createdWith =>
      super.get<Map<String, dynamic>>(keyVarCreatedWith);

  bool get restricted => super.get<bool>(keyVarRestricted);

  DateTime get expiresAt => super.get<DateTime>(keyVarExpiresAt);

  String get installationId => super.get<String>(keyVarInstallationId);

  ParseSession({String sessionToken, bool debug, ParseHTTPClient client})
      : super(keyClassSession) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId: true,
            securityContext: ParseCoreData().securityContext);
  }

  Future<ParseResponse> getCurrentSessionFromServer() async {
    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointSessions/me");

      final response = await _client.get(url);

      return _handleResponse(
          this, response, ParseApiRQ.logout, _debug, className);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.logout, _debug, className);
    }
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  static ParseResponse _handleException(
      Exception exception, ParseApiRQ type, bool debug, String className) {
    ParseResponse parseResponse = ParseResponse.handleException(exception);

    if (debug) {
      logger(
          ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles all the response data for this class
  static ParseResponse _handleResponse(ParseSession session, Response response,
      ParseApiRQ type, bool debug, String className) {
    ParseResponse parseResponse =
        ParseResponse.handleResponse<ParseSession>(session, response);

    if (debug) {
      logger(
          ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }
}
