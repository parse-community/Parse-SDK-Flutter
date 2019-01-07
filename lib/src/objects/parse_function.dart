part of flutter_parse_sdk;

class ParseCloudFunction extends ParseBase {
  final String functionName;
  String _path;
  bool _debug;
  ParseHTTPClient _client;

  /// Creates a new cloud function object
  ///
  /// {https://docs.parseplatform.org/cloudcode/guide/}
  ParseCloudFunction(this.functionName, {bool debug, ParseHTTPClient client}) {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(debug, _client);
    _path = "/functions/$functionName";
    setObjectData(Map<String, dynamic>());
  }

  /// Executes a cloud function
  ///
  /// To add the paramaters, create an object and call [set](value to set)
  execute() async {
    var uri = _client.data.serverUrl + "$_path";
    var result = await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
    return _handleResult(result, ParseApiFunctionCallType.execute);
  }

  /// Handles an API response
  ParseResponse _handleResult(Response response, ParseApiFunctionCallType type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    if (_client.data.debug || _debug) {
      var responseString = ' \n';

      responseString += "----"
          "\n${_client.data.appName} API Response ($functionName : ${type.toString()}) :";

      if (parseResponse.success && parseResponse.result != null) {
        responseString += "\nStatus Code: ${parseResponse.statusCode}";
        responseString += "\nPayload: ${responseData.toString()}";
      } else if (!parseResponse.success) {
        responseString += "\nStatus Code: ${responseData['code'] == null ? parseResponse.statusCode : responseData['code']}";
        responseString += "\nException: ${responseData['error'] == null ? responseData.toString() : responseData['error']}";
      }

      responseString += "\n----\n";
      print(responseString);
    }

    return parseResponse;
  }
}
