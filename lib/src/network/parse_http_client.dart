part of flutter_parse_sdk;

/// Creates a custom version of HTTP Client that has Parse Data Preset
class ParseHTTPClient extends BaseClient {
  final Client _client = new Client();
  final String _userAgent = "Dart Parse SDK 0.1";
  ParseDataServer data = ParseDataServer();

  ParseHTTPClient();

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    request.headers['X-Parse-Application-Id'] = data.applicationId;
    request.headers['Content-Type'] = 'application/json';
    if (data.masterKey != null)
      request.headers['X-Parse-Master-Key'] = data.masterKey;
    return _client.send(request);
  }
}
