part of flutter_parse_sdk;

class ParseConfig extends ParseObject {
  /// Creates an instance of ParseConfig so that you can grab all configs from the server
  ParseConfig({bool debug, ParseClient client, bool autoSendSessionId})
      : super('config') {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseCoreData().clientCreator(
          sendSessionId: autoSendSessionId,
        );
  }

  /// Gets all configs from the server
  Future<ParseResponse> getConfigs() async {
    try {
      final String uri = '${ParseCoreData().serverUrl}/config';
      final ParseNetworkResponse result = await _client.get(uri);
      return handleResponse<ParseConfig>(
          this, result, ParseApiRQ.getConfigs, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getConfigs, _debug, parseClassName);
    }
  }

  /// Adds a new config
  Future<ParseResponse> addConfig(String key, dynamic value) async {
    try {
      final String uri = '${ParseCoreData().serverUrl}/config';
      final String body = '{\"params\":{\"$key\": \"${parseEncode(value)}\"}}';
      final ParseNetworkResponse result =
          await _client.put(uri, data: body);
      return handleResponse<ParseConfig>(
          this, result, ParseApiRQ.addConfig, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.addConfig, _debug, parseClassName);
    }
  }
}
