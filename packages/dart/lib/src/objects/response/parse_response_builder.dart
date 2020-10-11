part of flutter_parse_sdk;

/// Handles all the ParseObject responses
///
/// There are 4 probable outcomes from a Parse API call,
/// 1. Fail - [ParseResponse()] will be returned with further details
/// 2. Success but no results. [ParseResponse()] is returned.
/// 3. Success with simple OK.
/// 4. Success with results. Again [ParseResponse()] is returned
class _ParseResponseBuilder {
  ParseResponse handleResponse<T>(
      dynamic object, Response<String> apiResponse, ParseApiRQ type) {
    final ParseResponse parseResponse = ParseResponse();
    final bool returnAsResult = shouldReturnAsABaseResult(type);
    if (apiResponse != null) {
      parseResponse.statusCode = apiResponse.statusCode;

      if (isUnsuccessfulResponse(apiResponse)) {
        return buildErrorResponse(parseResponse, apiResponse);
      } else if (isHealthCheck(apiResponse)) {
        parseResponse.success = true;
        return parseResponse;
      } else if (isSuccessButNoResults(apiResponse)) {
        return buildSuccessResponseWithNoResults(
            parseResponse, 1, 'Successful request, but no results found');
      } else if (returnAsResult) {
        return _handleSuccessWithoutParseObject(
            parseResponse, object, apiResponse.data);
      } else {
        return _handleSuccess<T>(parseResponse, object, apiResponse.data, type);
      }
    } else {
      parseResponse.error = ParseError(
          message: 'Error reaching server, or server response was null');
      return parseResponse;
    }
  }

  /// Handles successful response without creating a ParseObject
  ParseResponse _handleSuccessWithoutParseObject(
      ParseResponse response, dynamic object, String responseBody) {
    response.success = true;

    if (responseBody == 'OK') {
      response.result = responseBody;
      return response;
    }

    final Map<String, dynamic> decodedJson = json.decode(responseBody);

    if (decodedJson.containsKey('params')) {
      response.result = decodedJson['params'];
    } else if (decodedJson.containsKey('result')) {
      response.result = decodedJson['result'];
    } else {
      response.result = decodedJson;
    }

    return response;
  }

  /// Handles successful response with results
  ParseResponse _handleSuccess<T>(ParseResponse response, dynamic object,
      String responseBody, ParseApiRQ type) {
    response.success = true;

    final dynamic result = json.decode(responseBody);

    if (type == ParseApiRQ.batch) {
      final List<dynamic> list = result;
      if (object is List && object.length == list.length) {
        response.count = object.length;
        response.results = List<dynamic>();
        for (int i = 0; i < object.length; i++) {
          final Map<String, dynamic> objectResult = list[i];
          if (objectResult.containsKey('success')) {
            final T item = _handleSingleResult<T>(
                object[i], objectResult['success'], false);
            response.results.add(item);
          } else {
            final ParseError error = ParseError(
                code: objectResult[keyCode],
                message: objectResult[keyError].toString());
            response.results.add(error);
          }
        }
      }
    } else if (result is Map) {
      final Map<String, dynamic> map = result;
      if (object is Parse) {
        response.result = map;
      } else if (map != null && map.length == 1 && map.containsKey('results')) {
        final List<dynamic> results = map['results'];
        if (results[0] is String) {
          response.results = results;
          response.result = results;
          response.count = results.length;
        } else {
          final List<T> items = _handleMultipleResults<T>(object, results);
          response.results = items;
          response.result = items;
          response.count = items.length;
        }
      } else if (map != null && map.length == 2 && map.containsKey('count')) {
        final List<int> results = <int>[map['count']];
        response.results = results;
        response.result = results;
        response.count = map['count'];
      } else {
        final T item = _handleSingleResult<T>(object, map, false);
        response.count = 1;
        response.result = item;
        response.results = <T>[item];
      }
    }

    return response;
  }

  /// Handles a response with a multiple result object
  List<T> _handleMultipleResults<T>(T object, List<dynamic> data) {
    final List<T> resultsList = List<T>();
    for (dynamic value in data) {
      resultsList.add(_handleSingleResult<T>(object, value, true));
    }
    return resultsList;
  }

  /// Handles a response with a single result object
  T _handleSingleResult<T>(
      T object, Map<String, dynamic> map, bool createNewObject) {
    if (createNewObject && object is ParseCloneable) {
      return object.clone(map);
    } else if (object is ParseObject) {
      // Merge unsaved changes and response.
      final Map<String, dynamic> unsaved = Map<String, dynamic>();
      unsaved.addAll(object._unsavedChanges);
      unsaved.forEach((String k, dynamic v) {
        if (map[k] != null && map[k] != v) {
          // Changes after save & before response. Keep it.
          map.remove(k);
        }
      });
      return object
        ..fromJson(map)
        .._unsavedChanges.clear()
        .._unsavedChanges.addAll(unsaved);
    } else {
      return null;
    }
  }

  bool isHealthCheck(Response<String> apiResponse) {
    return <String>['{\"status\":\"ok\"}', 'OK'].contains(apiResponse.data);
  }
}
