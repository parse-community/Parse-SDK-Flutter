part of flutter_parse_sdk;

class ParseCloudFunction extends ParseObject {
  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(
    this.functionName, {
    bool? debug,
    ParseClient? client,
    bool? autoSendSessionId,
  }) : super(
          functionName,
          client: client,
          autoSendSessionId: autoSendSessionId,
          debug: debug,
        ) {
    _path = '/functions/$functionName';
  }

  final String functionName;

  @override
  // ignore: overridden_fields
  late String _path;

  /// Executes a cloud function
  ///
  /// To add the parameters, create an object and call [set](value to set)
  Future<ParseResponse> execute(
      {Map<String, dynamic>? parameters, Map<String, String>? headers}) async {
    final String uri = '${ParseCoreData().serverUrl}$_path';
    if (parameters != null) {
      _setObjectData(parameters);
    }
    try {
      final ParseNetworkResponse result = await _client.post(uri,
          options: ParseNetworkOptions(headers: headers),
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
      {Map<String, dynamic>? parameters, Map<String, String>? headers}) async {
    final String uri = '${ParseCoreData().serverUrl}$_path';
    if (parameters != null) {
      _setObjectData(parameters);
    }
    try {
      final ParseNetworkResponse result = await _client.post(uri,
          options: ParseNetworkOptions(headers: headers),
          data: json.encode(_getObjectData()));
      return handleResponse<T>(this, result,
          ParseApiRQ.executeObjectionFunction, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.executeObjectionFunction, _debug, parseClassName);
    }
  }
}
