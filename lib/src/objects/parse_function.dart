part of flutter_parse_sdk;

class ParseCloudFunction extends ParseObject {
  final String functionName;

  @override
  String _path;

  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(this.functionName,
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super(functionName) {
    _path = "/functions/$functionName";

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  /// Executes a cloud function
  ///
  /// To add the parameters, create an object and call [set](value to set)
  execute({Map parameters, Map headers}) async {
    var uri = _client.data.serverUrl + "$_path";
    if (parameters != null) setObjectData(parameters);
    var result = await _client.post(uri, body: json.encode(getObjectData()));
    return handleResponse(this, result, ParseApiRQ.execute, _debug, className);
  }

  /// Executes a cloud function that returns a ParseObject type
  ///
  /// To add the parameters, create an object and call [set](value to set)
  Future<ParseResponse> executeObjectFunction<T extends ParseObject>(
      {Map parameters, Map headers}) async {
    var uri = _client.data.serverUrl + "$_path";
    if (parameters != null) setObjectData(parameters);
    var result = await _client.post(uri, body: json.encode(getObjectData()));
    return handleResponse<T>(
        this, result, ParseApiRQ.executeObjectionFunction, _debug, className);
  }
}
