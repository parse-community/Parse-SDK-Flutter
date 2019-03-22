part of flutter_parse_sdk;

class ParseObject extends ParseBase implements ParseCloneable {
  /// Creates a new Parse Object
  ///
  /// [String] className refers to the Table Name in your Parse Server,
  /// [bool] debug will overwrite the current default debug settings and
  /// [ParseHttpClient] can be overwritten to create your own HTTP Client
  ParseObject(String className,
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super() {
    setClassName(className);
    _path = '$keyEndPointClasses$className';

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  ParseObject.clone(String className) : this(className);

  @override
  dynamic clone(Map<String, dynamic> map) =>
      ParseObject.clone(className)..fromJson(map);

  String _path;
  bool _debug;
  ParseHTTPClient _client;

  /// Gets an object from the server using it's [String] objectId
  Future<ParseResponse> getObject(String objectId) async {
    try {
      String uri =_path;

      if (objectId != null) {
        uri += '/$objectId';
      }

      final Uri url = getSanitisedUri(_client, '$uri');

      final Response result = await _client.get(url);
      return handleResponse<ParseObject>(this, result, ParseApiRQ.get, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.get, _debug, className);
    }
  }

  /// Gets all objects from this table - Limited response at the moment
  Future<ParseResponse> getAll() async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path');
      final Response result = await _client.get(url);
      return handleResponse<ParseObject>(this, result, ParseApiRQ.getAll, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getAll, _debug, className);
    }
  }

  /// Creates a new object and saves it online
  Future<ParseResponse> create() async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path');
      final String body = json.encode(toJson(forApiRQ: true));
      final Response result = await _client.post(url, body: body);

      //Set the objectId on the object after it is created.
      //This allows you to perform operations on the object after creation
      if (result.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(result.body);
        objectId = map['objectId'].toString();
      }

      return handleResponse<ParseObject>(this, result, ParseApiRQ.create, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.create, _debug, className);
    }
  }

  /// Saves the current object online
  Future<ParseResponse> save() async {
    if (getObjectData()[keyVarObjectId] == null) {
      return create();
    } else {
      try {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final String body = json.encode(toJson(forApiRQ: true));
        final Response result = await _client.put(url, body: body);
        return handleResponse<ParseObject>(this, result, ParseApiRQ.save, _debug, className);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.save, _debug, className);
      }
    }
  }

  /// Removes an element from an Array
  @Deprecated('Prefer to use the setRemove() method in save()')
  Future<ParseResponse> remove(String key, dynamic values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.remove, 'Remove', key, values);
    } else {
      return null;
    }
  }

  /// Removes an element from an Array
  void setRemove(String key, dynamic values) {
    _arrayOperation('Remove', key, values);
  }

  /// Remove multiple elements from an array of an object
  @Deprecated('Prefer to use the setRemoveAll() method in save()')
  Future<ParseResponse> removeAll(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.removeAll, 'Remove', key, values);
    } else {
      return null;
    }
  }

  /// Remove multiple elements from an array of an object
  void setRemoveAll(String key, List<dynamic> values) {
    _arrayOperation('Remove', key, values);
  }

  /// Add a multiple elements to an array of an object
  @Deprecated('Prefer to use the setAddAll() method in save()')
  Future<ParseResponse> addAll(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.addAll, 'Add', key, values);
    } else {
      return null;
    }
  }

  /// Add a multiple elements to an array of an object
  void setAddAll(String key, List<dynamic> values) {
    _arrayOperation('Add', key, values);
  }

  /// Add a multiple elements to an array of an object, but only when they are unique
  @Deprecated('Prefer to use the setAddAll() method in save()')
  Future<ParseResponse> addUnique(String key, List<dynamic> values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.addUnique, 'AddUnique', key, values);
    } else {
      return null;
    }
  }

  /// Add a multiple elements to an array of an object
  void setAddUnique(String key, List<dynamic> values) {
    _arrayOperation('AddUnique', key, values);
  }

  /// Add a single element to an array of an object
  @Deprecated('Prefer to use the setAdd() method in save()')
  Future<ParseResponse> add(String key, dynamic values) async {
    if (key != null) {
      return await _sortArrays(ParseApiRQ.add, 'Add', key, values);
    } else {
      return null;
    }
  }

  /// Add a single element to an array of an object
  void setAdd(String key, dynamic values) {
    _arrayOperation('Add', key, values);
  }

  /// Can be used to add arrays to a given type
  Future<ParseResponse> _sortArrays(ParseApiRQ apiRQType, String arrayAction,
      String key, List<dynamic> values) async {
    try {
      if (objectId != null) {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final String body =
            '{\"$key\":{\"__op\":\"$arrayAction\",\"objects\":${json.encode(parseEncode(values))}}}';
        final Response result = await _client.put(url, body: body);
        return handleResponse<ParseObject>(this, result, apiRQType, _debug, className);
      } else {
        return null;
      }
    } on Exception catch (e) {
      return handleException(e, apiRQType, _debug, className);
    }
  }

  /// Used in array Operations in save() method
  void _arrayOperation(String arrayAction, String key, List<dynamic> values) {
    set<Map<String, dynamic>>(key, <String, dynamic>{'__op': arrayAction, 'objects': values});
  }

  /// Increases a num of an object by x amount
  @Deprecated('Prefer to use the setIncrement() method in save()')
  Future<ParseResponse> increment(String key, num amount) async {
    if (key != null) {
      return await _increment(ParseApiRQ.increment, 'Increment', key, amount);
    } else {
      return null;
    }
  }

  /// Increases a num of an object by x amount
  void setIncrement(String key, num amount) {
    set<Map<String, dynamic>>(
        key,  <String, dynamic>{'__op': 'Increment', 'amount': amount});
  }

  /// Decreases a num of an object by x amount
  @Deprecated('Prefer to use the setDecrement() method in save()')
  Future<ParseResponse> decrement(String key, num amount) async {
    if (key != null) {
      return await _increment(ParseApiRQ.decrement, 'Increment', key, -amount);
    } else {
      return null;
    }
  }

  /// Decreases a num of an object by x amount
  void setDecrement(String key, num amount) {
    set<Map<String, dynamic>>(
        key,  <String, dynamic>{'__op': 'Increment', 'amount': -amount});
  }

  /// Can be used to add arrays to a given type
  Future<ParseResponse> _increment(
      ParseApiRQ apiRQType, String countAction, String key, num amount) async {
    try {
      if (objectId != null) {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final String body = '{\"$key\":{\"__op\":\"$countAction\",\"amount\":$amount}}';
        final Response result = await _client.put(url, body: body);
        return handleResponse<ParseObject>(this, result, apiRQType, _debug, className);
      } else {
        return null;
      }
    } on Exception catch (e) {
      return handleException(e, apiRQType, _debug, className);
    }
  }

  /// Can be used to create custom queries
  Future<ParseResponse> query(String query) async {
    try {
      final Uri tempUri = Uri.parse(ParseCoreData().serverUrl);

      final Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          port: tempUri.port,
          path: '${tempUri.path}$_path',
          query: query);
      final Response result = await _client.get(url);
      return handleResponse<ParseObject>(this, result, ParseApiRQ.query, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.query, _debug, className);
    }
  }

  /// Deletes the current object locally and online
  Future<ParseResponse> delete({String objectId, String path}) async {
    try {
      path ??= _path;
      objectId ??= objectId;
      final Uri url = getSanitisedUri(_client, '$_path/$objectId');
      final Response result = await _client.delete(url);
      return handleResponse<ParseObject>(this, result, ParseApiRQ.delete, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.delete, _debug, className);
    }
  }
}
