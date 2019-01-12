part of flutter_parse_sdk;

class ParseObject extends ParseBase implements ParseCloneable {

  ParseObject.clone(String className): this('className');

  @override
  clone(Map map) => ParseObject.clone(className)..fromJson(map);

  String _path;
  bool _debug;
  ParseHTTPClient _client;

  /// Creates a new Parse Object
  ///
  /// [String] className refers to the Table Name in your Parse Server,
  /// [bool] debug will overwrite the current default debug settings and
  /// [ParseHttpClient] can be overwritten to create your own HTTP Client
  ParseObject(String className, {bool debug: false}): super() {
    setClassName(className);
    _path = "$keyEndPointClasses$className";
    setClient(ParseHTTPClient());
    setDebug(isDebugEnabled(objectLevelDebug: debug));
  }

  void setDebug(bool debug){
    _debug = debug;
  }

  void setClient(ParseHTTPClient client){
    _client = client;
  }

  /// Gets an object from the server using it's [String] objectId
  Future<ParseResponse> getObject(String objectId) async {
    try {
      var uri = "${ParseCoreData().serverUrl}$_path";
      if (objectId != null) uri += "/$objectId";
      var result = await _client.get(uri);
      return handleResponse(result, ParseApiRQ.get);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.get);
    }
  }

  /// Gets all objects from this table - Limited response at the moment
  Future<ParseResponse> getAll() async {
    try {
      var result = await _client.get("${ParseCoreData().serverUrl}$_path");
      return handleResponse(result, ParseApiRQ.getAll);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getAll);
    }
  }

  /// Creates a new object and saves it online
  Future<ParseResponse> create() async {
    try {
      var uri = _client.data.serverUrl + "$_path";
      var result = await _client.post(uri, body: toJson(forApiRQ: true));
      return handleResponse(result, ParseApiRQ.create);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.create);
    }
  }

  /// Saves the current object online
  Future<ParseResponse> save() async {
    if (getObjectData() == null) {
      return create();
    } else {
      try {
        var uri = "${ParseCoreData().serverUrl}$_path/$objectId";
        var result = await _client.put(uri, body: toJson(forApiRQ: true));
        return handleResponse(result, ParseApiRQ.save);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.save);
      }
    }
  }

  /// Can be used to create custom queries
  Future<ParseResponse> query(String query) async {
    try {
      var uri = "${ParseCoreData().serverUrl}$_path?$query";
      var result = await _client.get(uri);
      return handleResponse(result, ParseApiRQ.query);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.query);
    }
  }

  /// Deletes the current object locally and online
  Future<ParseResponse> delete(String path, String objectId) async {
    try {
      var uri = "${ParseCoreData().serverUrl}$_path/$objectId";
      var result = await _client.delete(uri);
      return handleResponse(result, ParseApiRQ.delete);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.delete);
    }
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  @protected
  ParseResponse handleResponse(Response response, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleResponse(this, response);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  @protected
  ParseResponse handleException(Exception exception, ParseApiRQ type) {
    ParseResponse parseResponse = ParseResponse.handleException(exception);

    if (_debug) {
      logger(ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }
}
