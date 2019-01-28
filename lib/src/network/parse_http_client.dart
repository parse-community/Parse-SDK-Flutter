part of flutter_parse_sdk;

/// Creates a custom version of HTTP Client that has Parse Data Preset
class ParseHTTPClient extends BaseClient {
  final Client _client = Client();
  final String _userAgent = "$keyLibraryName $keySdkVersion";
  ParseCoreData data = ParseCoreData();

  ParseHTTPClient();

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers[keyHeaderUserAgent] = _userAgent;
    request.headers[keyHeaderApplicationId] = data.applicationId;
    if (data.clientKey != null)
      request.headers[keyHeaderClientKey] = data.clientKey;
    if (data.masterKey != null)
      request.headers[keyHeaderMasterKey] = data.masterKey;
    return _client.send(request);
  }
}
