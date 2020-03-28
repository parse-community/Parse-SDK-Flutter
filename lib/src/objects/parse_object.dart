part of flutter_parse_sdk;

// ignore_for_file: always_specify_types
class ParseObject extends ParseBase implements ParseCloneable {
  /// Creates a new Parse Object
  ///
  /// [String] className refers to the Table Name in your Parse Server,
  /// [bool] debug will overwrite the current default debug settings and
  /// [ParseHttpClient] can be overwritten to create your own HTTP Client
  ParseObject(String className,
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super() {
    parseClassName = className;
    _path = '$keyEndPointClasses$className';
    _aggregatepath = '$keyEndPointAggregate$className';

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
      ParseObject.clone(parseClassName)..fromJson(map);

  String _path;
  String _aggregatepath;
  bool _debug;
  ParseHTTPClient _client;

  /// Gets an object from the server using it's [String] objectId
  Future<ParseResponse> getObject(String objectId) async {
    try {
      String uri = _path;

      if (objectId != null) {
        uri += '/$objectId';
      }

      final Uri url = getSanitisedUri(_client, '$uri');

      final Response result = await _client.get(url);
      return handleResponse<ParseObject>(
          this, result, ParseApiRQ.get, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.get, _debug, parseClassName);
    }
  }

  /// Gets all objects from this table - Limited response at the moment
  Future<ParseResponse> getAll() async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path');
      final Response result = await _client.get(url);
      return handleResponse<ParseObject>(
          this, result, ParseApiRQ.getAll, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getAll, _debug, parseClassName);
    }
  }

  /// Creates a new object and saves it online
  Future<ParseResponse> create() async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path');
      final String body = json.encode(toJson(forApiRQ: true));
      _saveChanges();
      final Response result = await _client.post(url, body: body);

      return handleResponse<ParseObject>(
          this, result, ParseApiRQ.create, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.create, _debug, parseClassName);
    }
  }

  Future<ParseResponse> update() async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path/$objectId');
      final String body = json.encode(toJson(forApiRQ: true));
      _saveChanges();
      final Map<String, String> headers = {
        keyHeaderContentType: keyHeaderContentTypeJson
      };
      final Response result =
          await _client.put(url, body: body, headers: headers);
      return handleResponse<ParseObject>(
          this, result, ParseApiRQ.save, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.save, _debug, parseClassName);
    }
  }

  /// Saves the current object online
  Future<ParseResponse> save() async {
    final ParseResponse childrenResponse = await _saveChildren(this);
    if (childrenResponse.success) {
      ParseResponse response;
      if (objectId == null) {
        response = await create();
      } else if (_isDirty(false)) {
        response = await update();
      }

      if (response != null) {
        if (response.success) {
          _savingChanges.clear();
        } else {
          _revertSavingChanges();
        }
        return response;
      }
    }
    return childrenResponse;
  }

  Future<ParseResponse> _saveChildren(dynamic object) async {
    final Set<ParseObject> uniqueObjects = Set<ParseObject>();
    final Set<ParseFile> uniqueFiles = Set<ParseFile>();
    if (!_collectionDirtyChildren(object, uniqueObjects, uniqueFiles,
        Set<ParseObject>(), Set<ParseObject>())) {
      final ParseResponse response = ParseResponse();
      return response;
    }
    if (object is ParseObject) {
      uniqueObjects.remove(object);
    }
    for (ParseFile file in uniqueFiles) {
      final ParseResponse response = await file.save();
      if (!response.success) {
        return response;
      }
    }
    List<ParseObject> remaining = uniqueObjects.toList();
    final List<ParseObject> finished = List<ParseObject>();
    final ParseResponse totalResponse = ParseResponse()
      ..success = true
      ..results = List<dynamic>()
      ..statusCode = 200;
    while (remaining.isNotEmpty) {
      /* Partition the objects into two sets: those that can be save immediately,
      and those that rely on other objects to be created first. */
      final List<ParseObject> current = List<ParseObject>();
      final List<ParseObject> nextBatch = List<ParseObject>();
      for (ParseObject object in remaining) {
        if (object._canbeSerialized(finished)) {
          current.add(object);
        } else {
          nextBatch.add(object);
        }
      }
      remaining = nextBatch;
      // TODO(yulingtianxia): lazy User
      /* Batch requests have currently a limit of 50 packaged requests per single request
      This splitting will split the overall array into segments of upto 50 requests
      and execute them concurrently with a wrapper task for all of them. */
      final List<List<ParseObject>> chunks = <List<ParseObject>>[];
      for (int i = 0; i < current.length; i += 50) {
        chunks.add(current.sublist(i, min(current.length, i + 50)));
      }

      for (List<ParseObject> chunk in chunks) {
        final List<dynamic> requests = chunk.map<dynamic>((ParseObject obj) {
          return obj._getRequestJson(obj.objectId == null ? 'POST' : 'PUT');
        }).toList();
        for (ParseObject obj in chunk) {
          obj._saveChanges();
        }
        final ParseResponse response = await batchRequest(requests, chunk);
        totalResponse.success &= response.success;
        if (response.success) {
          totalResponse.results.addAll(response.results);
          totalResponse.count += response.count;
          for (int i = 0; i < response.count; i++) {
            if (response.results[i] is ParseError) {
              // Batch request succeed, but part of batch failed.
              chunk[i]._revertSavingChanges();
            } else {
              chunk[i]._savingChanges.clear();
            }
          }
        } else {
          // If there was an error, we want to roll forward the save changes before rethrowing.
          for (ParseObject obj in chunk) {
            obj._revertSavingChanges();
          }
          totalResponse.statusCode = response.statusCode;
          totalResponse.error = response.error;
        }
      }
      finished.addAll(current);
    }
    return totalResponse;
  }

  void _saveChanges() {
    _savingChanges.clear();
    _savingChanges.addAll(_unsavedChanges);
    _unsavedChanges.clear();
  }

  void _revertSavingChanges() {
    _savingChanges.addAll(_unsavedChanges);
    _unsavedChanges.addAll(_savingChanges);
    _savingChanges.clear();
  }

  dynamic _getRequestJson(String method) {
    final Uri tempUri = Uri.parse(_client.data.serverUrl);
    final String parsePath = tempUri.path;
    final dynamic request = <String, dynamic>{
      'method': method,
      'path': '$parsePath$_path' + (objectId != null ? '/$objectId' : ''),
      'body': toJson(forApiRQ: true)
    };
    return request;
  }

  bool _canbeSerialized(List<dynamic> aftersaving, {dynamic value}) {
    if (value != null) {
      if (value is ParseObject) {
        if (value.objectId == null && !aftersaving.contains(value)) {
          return false;
        }
      } else if (value is Map) {
        for (dynamic child in value.values) {
          if (!_canbeSerialized(aftersaving, value: child)) {
            return false;
          }
        }
      } else if (value is List) {
        for (dynamic child in value) {
          if (!_canbeSerialized(aftersaving, value: child)) {
            return false;
          }
        }
      }
    } else if (!_canbeSerialized(aftersaving, value: _getObjectData())) {
      return false;
    }
    // TODO(yulingtianxia): handle ACL
    return true;
  }

  bool _collectionDirtyChildren(
      dynamic object,
      Set<ParseObject> uniqueObjects,
      Set<ParseFile> uniqueFiles,
      Set<ParseObject> seen,
      Set<ParseObject> seenNew) {
    if (object is List) {
      for (dynamic child in object) {
        if (!_collectionDirtyChildren(
            child, uniqueObjects, uniqueFiles, seen, seenNew)) {
          return false;
        }
      }
    } else if (object is Map) {
      for (dynamic child in object.values) {
        if (!_collectionDirtyChildren(
            child, uniqueObjects, uniqueFiles, seen, seenNew)) {
          return false;
        }
      }
    } else if (object is ParseACL) {
      // TODO(yulingtianxia): handle ACL
    } else if (object is ParseFile) {
      if (object.url == null) {
        uniqueFiles.add(object);
      }
    } else if (object is ParseObject) {
      /* Check for cycles of new objects.  Any such cycle means it will be
      impossible to save this collection of objects, so throw an exception. */
      if (object.objectId != null) {
        seenNew = Set<ParseObject>();
      } else {
        if (seenNew.contains(object)) {
          // TODO(yulingtianxia): throw an error?
          return false;
        }
        seenNew.add(object);
      }

      /* Check for cycles of any object.  If this occurs, then there's no
      problem, but we shouldn't recurse any deeper, because it would be
      an infinite recursion. */
      if (seen.contains(object)) {
        return true;
      }
      seen.add(object);

      if (!_collectionDirtyChildren(
          object._getObjectData(), uniqueObjects, uniqueFiles, seen, seenNew)) {
        return false;
      }

      if (object._isDirty(false)) {
        uniqueObjects.add(object);
      }
    }
    return true;
  }

  /// Get the instance of ParseRelation class associated with the given key.
  ParseRelation getRelation(String key) {
    return ParseRelation(parent: this, key: key);
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
  void setRemove(String key, dynamic value) {
    _arrayOperation('Remove', key, <dynamic>[value]);
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

  void setAddUnique(String key, dynamic value) {
    _arrayOperation('AddUnique', key, <dynamic>[value]);
  }

  /// Add a multiple elements to an array of an object
  void setAddAllUnique(String key, List<dynamic> values) {
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
  void setAdd(String key, dynamic value) {
    _arrayOperation('Add', key, <dynamic>[value]);
  }

  void addRelation(String key, List<dynamic> values) {
    _arrayOperation('AddRelation', key, values);
  }

  void removeRelation(String key, List<dynamic> values) {
    _arrayOperation('RemoveRelation', key, values);
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
        return handleResponse<ParseObject>(
            this, result, apiRQType, _debug, parseClassName);
      } else {
        return null;
      }
    } on Exception catch (e) {
      return handleException(e, apiRQType, _debug, parseClassName);
    }
  }

  /// Used in array Operations in save() method
  void _arrayOperation(String arrayAction, String key, List<dynamic> values) {
    // TODO(yulingtianxia): Array operations should be incremental. Merge add and remove operation.
    set<Map<String, dynamic>>(
        key, <String, dynamic>{'__op': arrayAction, 'objects': values});
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
        key, <String, dynamic>{'__op': 'Increment', 'amount': amount});
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
        key, <String, dynamic>{'__op': 'Increment', 'amount': -amount});
  }

  /// Can be used to add arrays to a given type
  Future<ParseResponse> _increment(
      ParseApiRQ apiRQType, String countAction, String key, num amount) async {
    try {
      if (objectId != null) {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final String body =
            '{\"$key\":{\"__op\":\"$countAction\",\"amount\":$amount}}';
        final Response result = await _client.put(url, body: body);
        return handleResponse<ParseObject>(
            this, result, apiRQType, _debug, parseClassName);
      } else {
        return null;
      }
    } on Exception catch (e) {
      return handleException(e, apiRQType, _debug, parseClassName);
    }
  }

  /// Can be used set an objects variable to undefined rather than null
  ///
  /// If object is not saved remotely, set offlineOnly to true to avoid api calls.
  Future<ParseResponse> unset(String key, {bool offlineOnly = false}) async {
    final dynamic object = _objectData[key];
    _objectData.remove(key);
    _unsavedChanges.remove(key);
    _savingChanges.remove(key);

    if (offlineOnly) {
      return ParseResponse()..success = true;
    }

    try {
      if (objectId != null) {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final String body = '{\"$key\":{\"__op\":\"Delete\"}}';
        final Response result = await _client.put(url, body: body);
        final ParseResponse response = handleResponse<ParseObject>(
            this, result, ParseApiRQ.unset, _debug, parseClassName);
        if (!response.success) {
          _objectData[key] = object;
          _unsavedChanges[key] = object;
          _savingChanges[key] = object;
        } else {
          return ParseResponse()..success = true;
        }
      }
    } on Exception {
      _objectData[key] = object;
      _unsavedChanges[key] = object;
      _savingChanges[key] = object;
    }

    return ParseResponse()..success = false;
  }

  /// Can be used to create custom queries
  Future<ParseResponse> query<T extends ParseObject>(String query) async {
    try {
      final Uri url = getSanitisedUri(_client, '$_path', query: query);
      final Response result = await _client.get(url);
      return handleResponse<T>(
          this, result, ParseApiRQ.query, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.query, _debug, parseClassName);
    }
  }

  Future<ParseResponse> distinct<T extends ParseObject>(String query) async {
    try {
      final Uri url = getSanitisedUri(_client, '$_aggregatepath', query: query);
      final Response result = await _client.get(url);
      return handleResponse<T>(
          this, result, ParseApiRQ.query, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.query, _debug, parseClassName);
    }
  }

  /// Deletes the current object locally and online
  Future<ParseResponse> delete<T extends ParseObject>(
      {String id, String path}) async {
    try {
      path ??= _path;
      id ??= objectId;
      final Uri url = getSanitisedUri(_client, '$_path/$id');
      final Response result = await _client.delete(url);
      return handleResponse<T>(
          this, result, ParseApiRQ.delete, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.delete, _debug, parseClassName);
    }
  }
}
