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
  ParseObject(this.className, {bool debug: false, ParseHTTPClient client})
      : super() {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(debug, _client);
    _path = "/classes/$className";
  }

  /// Gets an object from the server using it's [String] objectId
  getObject(String objectId) async {
    try {
      var uri = _getBasePath(_path);
      if (objectId != null) uri += "/$objectId";
      var result = await _client.get(uri);
      return _handleResponse(result, ParseApiRQ.get);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.delete);
    }
  }

  /// Gets all objects from this table - Limited response at the moment
  getAll() async {
    try {
      var result = await _client.get(_getBasePath(_path));
      return _handleResponse(result, ParseApiRQ.getAll);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.delete);
    }
  }

  /// Creates a new object and saves it online
  create() async {
    try {
      var uri = _client.data.serverUrl + "$_path";
      var result = await _client.post(uri, body: JsonEncoder().convert(getObjectData()));
      return _handleResponse(result, ParseApiRQ.create);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.delete);
    }
  }

  /// Saves the current object online
  save() async {
    if (getObjectData() == null) {
      return create();
    } else {
      try {
        var uri = "${_getBasePath(_path)}/$objectId";
        var result = await _client.put(uri, body: JsonEncoder().convert(getObjectData()));
        return _handleResponse(result, ParseApiRQ.save);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.delete);
      }
    }
  }

  /// Can be used to create custom queries
  query(String query) async {
    try {
      var uri = "${_getBasePath(_path)}?$query";
      var result = await _client.get(uri);
      return _handleResponse(result, ParseApiRQ.query);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.delete);
    }
  }

  /// Deletes the current object locally and online
  delete(String path, String objectId) async {
    try {
      var uri = "${_getBasePath(path)}/$objectId";
      var result = await _client.delete(uri);
      return _handleResponse(result, ParseApiRQ.delete);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.delete);
    }
  }

  /// Generates the path for the object
  _getBasePath(String path) => "${_client.data.serverUrl}$path";

  /// Handles an API response and logs data if [bool] debug is enabled
  ParseResponse _handleResponse(Response response, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  ParseResponse _handleException(Exception exception, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleException(this, exception);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }
}
