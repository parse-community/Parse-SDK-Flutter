part of flutter_parse_sdk;

class ParseCloudFunction extends ParseObject {
  final String functionName;
  bool _debug;
  ParseHTTPClient _client;

  @override
  String _path;

  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(this.functionName, {bool debug, ParseHTTPClient client}) : super (functionName) {
    _path = "/functions/$functionName";

    if (debug != null) setDebug(debug);
    if (client != null) setClient(client);
  }

  /// Executes a cloud function
  ///
  /// To add the paramaters, create an object and call [set](value to set)
  execute() async {
    var uri = _client.data.serverUrl + "$_path";
    var result = await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
    return super.handleResponse(result, ParseApiRQ.execute);
  }
}
