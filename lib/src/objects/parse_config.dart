part of flutter_parse_sdk;

class ParseConfig extends ParseObject {
  var _client = ParseHTTPClient();

  /// Creates an instance of ParseConfig so that you can grab all configs from the server
  ParseConfig({bool debug, ParseHTTPClient client}) : super('config') {
    if (debug != null) setDebug(debug);
    if (client != null) setClient(client);
  }

  /// Gets all configs from the server
  Future<ParseResponse> getConfigs() async {
    try {
      var uri = "${ParseCoreData().serverUrl}/config";
      var result = await _client.get(uri);
      return handleResponse(result, ParseApiRQ.getConfigs);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getConfigs);
    }
  }

  /// Adds a new config
  Future<ParseResponse> addConfig(String key, dynamic value) async {
    try {
      var uri = "${ParseCoreData().serverUrl}/config";
      var body = "{\"params\":{\"$key\": ${parseEncode(value)}}}";
      var result = await _client.put(uri, body: body);
      return handleResponse(result, ParseApiRQ.addConfig);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.addConfig);
    }
  }
}
