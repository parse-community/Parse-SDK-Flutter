part of flutter_parse_sdk;

class ParseConfig extends ParseObject {
  /// Creates an instance of ParseConfig so that you can grab all configs from the server
  ParseConfig({bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super('config') {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  /// Gets all configs from the server
  Future<ParseResponse> getConfigs() async {
    try {
      var uri = "${ParseCoreData().serverUrl}/config";
      var result = await _client.get(uri);
      return handleResponse(
          this, result, ParseApiRQ.getConfigs, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getConfigs, _debug, className);
    }
  }

  /// Adds a new config
  Future<ParseResponse> addConfig(String key, dynamic value) async {
    try {
      var uri = "${ParseCoreData().serverUrl}/config";
      var body = "{\"params\":{\"$key\": \"${parseEncode(value)}\"}}";
      var result = await _client.put(uri, body: body);
      return handleResponse(
          this, result, ParseApiRQ.addConfig, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.addConfig, _debug, className);
    }
  }
}
