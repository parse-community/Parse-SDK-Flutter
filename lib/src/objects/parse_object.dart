part of flutter_parse_sdk;

class ParseObject extends ParseBase {
  final String className;
  String _path;
  bool _debug;
  ParseHTTPClient _client;

  /// Creates a new Parse Object
  ///
  /// [String] className refers to the Table Name in your Parse Server,
  /// [bool] debug will overwrite the current default debug settings and
  /// [ParseHttpClient] can be overwritten to create your own HTTP Client
  ParseObject(this.className, {bool debug: false, ParseHTTPClient client}) {

    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(debug, _client);

    _path = "/classes/$className";
    setObjectData(Map<String, dynamic>());
  }

  /// Gets an object from the server using it's [String] objectId
  getObject(String objectId) async {
    var uri = _getBasePath(_path);
    if (objectId != null) uri += "/$objectId";
    var result = await _client.get(uri);
    return _handleResult(result, ParseApiObject.get);
  }

  /// Gets all objects from this table - Limited response at the moment
  getAll() async {
    var result = await _client.get(_getBasePath(_path));
    return _handleResult(result, ParseApiObject.getAll);
  }

  /// Creates a new object and saves it online
  create() async {
    var uri = _client.data.serverUrl + "$_path";
    var result =
        await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
    return _handleResult(result, ParseApiObject.create);
  }

  /// Saves the current object online
  save() async {
    if (getObjectData() == null) {
      return create();
    } else {
      var uri = "${_getBasePath(_path)}/$objectId";
      var result =
          await _client.put(uri, body: JsonEncoder().convert(getObjectData()));
      return _handleResult(result, ParseApiObject.save);
    }
  }

  /// Can be used to create custom queries
  query(String query) async {
    var uri = "${_getBasePath(_path)}?$query";
    var result = await _client.get(uri);
    return _handleResult(result, ParseApiObject.query);
  }

  /// Deletes the current object locally and online
  delete(String path, String objectId) async {
    var uri = "${_getBasePath(path)}/$objectId";
    var result = await _client.delete(uri);
    return _handleResult(result, ParseApiObject.delete);
  }

  /// Generates the path for the object
  _getBasePath(String path) => "${_client.data.serverUrl}$path";

  /// Handles an API response and logs data if [bool] debug is enabled
  ParseResponse _handleResult(Response response, ParseApiObject type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    if (_client.data.debug || _debug) {
      var responseString = ' \n';

      responseString += "----"
          "\n${_client.data.appName} API Response ($className : ${type.toString()}) :";

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
