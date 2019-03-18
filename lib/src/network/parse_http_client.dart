part of flutter_parse_sdk;

/// Creates a custom version of HTTP Client that has Parse Data Preset
class ParseHTTPClient extends BaseClient {
  ParseHTTPClient({bool sendSessionId = false, SecurityContext securityContext})
      : _sendSessionId = sendSessionId,
        _client = securityContext != null
            ? IOClient(HttpClient(context: securityContext))
            : IOClient();

  final Client _client;
  final bool _sendSessionId;
  final String _userAgent = '$keyLibraryName $keySdkVersion';
  ParseCoreData data = ParseCoreData();
  Map<String, String> additionalHeaders;

  /// Overrides the call method for HTTP Client and adds custom headers
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers[keyHeaderUserAgent] = _userAgent;
    request.headers[keyHeaderApplicationId] = data.applicationId;
    if ((_sendSessionId == true) &&
        (data.sessionId != null) &&
        (request.headers[keyHeaderSessionToken] == null))
      request.headers[keyHeaderSessionToken] = data.sessionId;

    if (data.clientKey != null)
      request.headers[keyHeaderClientKey] = data.clientKey;
    if (data.masterKey != null)
      request.headers[keyHeaderMasterKey] = data.masterKey;

    /// If developer wants to add custom headers, extend this class and add headers needed.
    if (additionalHeaders != null && additionalHeaders.isNotEmpty) {
      additionalHeaders
          .forEach((String key, String value) => request.headers[key] = value);
    }

    if (data.debug) {
      _logging(request);
    }

    return _client.send(request);
  }

  void _logging(BaseRequest request) {
    String curlCmd = 'curl';
    curlCmd += ' -X ' + request.method;
    bool compressed = false;
    request.headers.forEach((String name, String value) {
      if (name?.toLowerCase() == 'accept-encoding' &&
          value?.toLowerCase() == 'gzip') {
        compressed = true;
      }
      curlCmd += ' -H \'$name: $value\'';
    });
    if (request.method == 'POST' || request.method == 'PUT') {
      if (request is Request) {
        final String body = latin1.decode(request.bodyBytes);
        curlCmd += ' -d \'$body\'';
      }
    }
    curlCmd += (compressed ? ' --compressed ' : ' ') + request.url.toString();
    print('╭-- cURL');
    print(curlCmd);
    print('╰-- (copy and paste the above line to a terminal)');
  }
}
