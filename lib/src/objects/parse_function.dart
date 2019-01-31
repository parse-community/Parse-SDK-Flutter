part of flutter_parse_sdk;

class ParseCloudFunction extends ParseObject {
  final String functionName;

  @override
  String _path;

  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(this.functionName, {bool debug, ParseHTTPClient client})
      : super(functionName) {
    _path = "/functions/$functionName";

    if (debug != null) setDebug(debug);
    if (client != null) setClient(client);
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
}
