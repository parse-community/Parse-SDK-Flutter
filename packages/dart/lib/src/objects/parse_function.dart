part of flutter_parse_sdk;

class ParseCloudFunction extends ParseObject {
  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(this.functionName,
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super(functionName) {
    _path = '/functions/$functionName';

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  final String functionName;

  @override
  // ignore: overridden_fields
  String _path;

  /// Executes a cloud function
  ///
  /// To add the parameters, create an object and call [set](value to set)
  Future<ParseResponse> execute(
      {Map<String, dynamic> parameters, Map<String, String> headers}) async {
    final String uri = '${_client.data.serverUrl}$_path';
    if (parameters != null) {
      _setObjectData(parameters);
    }
    try {
      final Response<String> result = await _client.post<String>(uri,
          options: Options(headers: headers),
          data: json.encode(_getObjectData()));
      return handleResponse<ParseCloudFunction>(
          this, result, ParseApiRQ.execute, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.execute, _debug, parseClassName);
    }
  }

  /// Executes a cloud function that returns a ParseObject type
  ///
  /// To add the parameters, create an object and call [set](value to set)
  Future<ParseResponse> executeObjectFunction<T extends ParseObject>(
      {Map<String, dynamic> parameters, Map<String, String> headers}) async {
    final String uri = '${_client.data.serverUrl}$_path';
    if (parameters != null) {
      _setObjectData(parameters);
    }
    try {
      final Response<String> result = await _client.post<String>(uri,
          options: Options(headers: headers),
          data: json.encode(_getObjectData()));
      return handleResponse<T>(this, result,
          ParseApiRQ.executeObjectionFunction, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.executeObjectionFunction, _debug, parseClassName);
    }
  }
}
