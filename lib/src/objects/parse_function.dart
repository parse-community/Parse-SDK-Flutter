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
      {Map<String, dynamic> parameters, Map<String, dynamic> headers}) async {
    final String uri = '${_client.data.serverUrl}$_path';
    if (parameters != null) {
      setObjectData(parameters);
    }

    final Response result =
    await _client.post(uri, body: json.encode(getObjectData()));
    return handleResponse<ParseCloudFunction>(
        this, result, ParseApiRQ.execute, _debug, className);
  }

  /// Executes a cloud function that returns a ParseObject type
  ///
  /// To add the parameters, create an object and call [set](value to set)
  Future<ParseResponse> executeObjectFunction<T extends ParseObject>(
      {Map<String, dynamic> parameters, Map<String, dynamic> headers}) async {
    final String uri = '${_client.data.serverUrl}$_path';
    if (parameters != null) {
      setObjectData(parameters);
    }
    final Response result =
        await _client.post(uri, body: json.encode(getObjectData()));
    return handleResponse<T>(
        this, result, ParseApiRQ.executeObjectionFunction, _debug, className);
  }
}
