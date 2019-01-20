part of flutter_parse_sdk;

class ParseObject extends ParseBase implements ParseCloneable {
  ParseObject.clone(String className) : this('className');

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
  ParseObject(String className, {bool debug: false}) : super() {
    setClassName(className);
    _path = "$keyEndPointClasses$className";
    setClient(ParseHTTPClient());
    setDebug(isDebugEnabled(objectLevelDebug: debug));
  }

  void setDebug(bool debug) {
    _debug = debug;
  }

  void setClient(ParseHTTPClient client) {
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
      var body = json.encode(toJson(forApiRQ: true));
      var result = await _client.post(uri, body: body);
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
        var body = json.encode(toJson(forApiRQ: true));
        var result = await _client.put(uri, body: body);
        return handleResponse(result, ParseApiRQ.save);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.save);
      }
    }
  }

  /// Removes an element from an Arary
  Future<ParseResponse> remove(String key, dynamic values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.remove, "Remove", key, [values]);
    } else {
      return null;
    }
  }

  /// Remove multiple elements from an array of an object
  Future<ParseResponse> removeAll(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.removeAll, "Remove", key, values);
    } else {
      return null;
    }
  }

  /// Add a multiple elements to an array of an object
  Future<ParseResponse> addAll(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.addAll, "Add", key, values);
    } else {
      return null;
    }
  }

  /// Add a multiple elements to an array of an object, but only when they are unique
  Future<ParseResponse> addUnique(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.addUnique, "AddUnique", key, values);
    } else {
      return null;
    }
  }

  /// Add a single element to an array of an object
  Future<ParseResponse> add(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.add, "Add", key, values);
    } else {
      return null;
    }
  }

  /// Can be used to add arrays to a given type
  Future<ParseResponse> _sortArrays(ParseApiRQ apiRQType, String arrayAction, String key, List<dynamic> values) async {
      try {
        var uri = "${ParseCoreData().serverUrl}$_path";
        var body = "{\"$key\":{\"__op\": \"$arrayAction\", \"objects\": ${parseEncode(values)}";
        var result = await _client.put(uri, body: body);
        return handleResponse(result, apiRQType);
      } on Exception catch (e) {
        return handleException(e, apiRQType);
      }
  }

  /// Increases a num of an object by x amount
  Future<ParseResponse> increment(String key, num amount) async {
    if (key != null) {
      return await _increment(ParseApiRQ.increment, "Increment", key, amount);
    } else {
      return null;
    }
  }

  /// Decreases a num of an object by x amount
  Future<ParseResponse> decrement(String key, num amount) async {
    if (key != null) {
      return await _increment(ParseApiRQ.decrement, "Increment", key, -amount);
    } else {
      return null;
    }
  }

  /// Can be used to add arrays to a given type
  Future<ParseResponse> _increment(ParseApiRQ apiRQType, String arrayAction, String key, num amount) async {
    try {
      var uri = "${ParseCoreData().serverUrl}$_path";
      var body = "{\"$key\":{\"__op\": \"$arrayAction\", \"amount\": $amount}";
      var result = await _client.put(uri, body: body);
      return handleResponse(result, apiRQType);
    } on Exception catch (e) {
      return handleException(e, apiRQType);
    }
  }

  /// Can be used to create custom queries
  Future<ParseResponse> query(String query) async {
    try {

      Uri tempUri = Uri.parse(ParseCoreData().serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$_path",
          query: query);

      var result = await _client.get(url);
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
  ParseResponse handleResponse<T extends ParseObject>(Response response, ParseApiRQ type) {

    bool returnAsBaseResult = false;

    if (type == ParseApiRQ.healthCheck ||
        type == ParseApiRQ.execute ||
        type == ParseApiRQ.add ||
        type == ParseApiRQ.addAll ||
        type == ParseApiRQ.addUnique ||
        type == ParseApiRQ.remove ||
        type == ParseApiRQ.removeAll ||
        type == ParseApiRQ.increment ||
        type == ParseApiRQ.decrement){
      returnAsBaseResult = true;
    }

    ParseResponse parseResponse = ParseResponse.handleResponse<T>(this, response, returnAsResult: returnAsBaseResult);

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
