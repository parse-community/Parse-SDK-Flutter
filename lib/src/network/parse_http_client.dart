part of flutter_parse_sdk;

/// Creates a custom version of HTTP Client that has Parse Data Preset
class ParseHTTPClient extends BaseClient {
  final Client _client = Client();
  final String _userAgent = "$keyLibraryName $keySdkVersion";
  ParseCoreData data = ParseCoreData();
  Map<String, String> additionalHeaders;

  ParseHTTPClient();

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers[keyHeaderUserAgent] = _userAgent;
    request.headers[keyHeaderApplicationId] = data.applicationId;

    if (data.clientKey != null) request.headers[keyHeaderClientKey] = data.clientKey;
    if (data.masterKey != null) request.headers[keyHeaderMasterKey] = data.masterKey;

    /// If developer wants to add custom headers, extend this class and add headers needed.
    if (additionalHeaders != null && additionalHeaders.length > 0){
      additionalHeaders.forEach((k,v) => request.headers[k] = v);
    }

    return _client.send(request);
  }
}
