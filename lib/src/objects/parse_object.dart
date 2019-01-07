part of flutter_parse_sdk;

class ParseObject extends ParseBase {
  final String className;
  String _path;
  bool _debug;
  ParseHTTPClient _client;

  ParseObject(this.className, {bool debug: false, ParseHTTPClient client}) {

    client == null ? _client = ParseHTTPClient() : _client = client;

    if (_debug == null) {
      _client.data.debug != null ? _debug = _client.data.debug : _debug = false;
    } else {
      _debug = _debug;
    }

    _path = "/classes/$className";
    setObjectData(Map<String, dynamic>());
  }

  get(String objectId) async {
    var uri = _getBasePath(_path);
    if (objectId != null) uri += "/$objectId";
    var result = await _client.get(uri);
    return _handleResult(result, ParseApiObjectCallType.get);
  }

  getAll() async {
    var result = await _client.get(_getBasePath(_path));
    return _handleResult(result, ParseApiObjectCallType.getAll);
  }

  create([Map<String, dynamic> objectData]) async {
    var uri = _client.data.serverUrl + "$_path";
    var result =
        await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
    return _handleResult(result, ParseApiObjectCallType.create);
  }

  save() async {
    if (getObjectData() == null) {
      return create();
    } else {
      var uri = "${_getBasePath(_path)}/$objectId";
      var result =
          await _client.put(uri, body: JsonEncoder().convert(getObjectData()));
      return _handleResult(result, ParseApiObjectCallType.save);
    }
  }

  query(String query) async {
    var uri = "${_getBasePath(_path)}?$query";
    var result = await _client.get(uri);
    return _handleResult(result, ParseApiObjectCallType.query);
  }

  delete(String path, String objectId) async {
    var uri = "${_getBasePath(path)}/$objectId";
    var result = await _client.delete(uri);
    return _handleResult(result, ParseApiObjectCallType.delete);
  }

  _getBasePath(String path) => "${_client.data.serverUrl}$path";

  ParseResponse _handleResult(Response response, ParseApiObjectCallType type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    if (_client.data.debug || _debug) {
      var responseString = ' \n';

      responseString += "----"
          "\n${_client.data.appName} API Response ($className : ${ParseApiObjectCallTypeUtil.getEnumValue(type)}) :";

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
