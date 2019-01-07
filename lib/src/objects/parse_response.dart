part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseException exception;

  /// Handles all the ParseObject responses
  ///
  /// There are 3 probable outcomes from a Parse API call,
  /// 1. Fail - [ParseResponse] will be returned with further details
  /// 2. Success but no results. [ParseResponse] is returned.
  /// 3. Success with results. Again [ParseResponse] is returned
  static handleResponse(ParseBase object, Response value) {
    var response = ParseResponse();

    if (value != null) {
      response.statusCode = value.statusCode;

      if (value.statusCode != 200) {
        return _handleError(response, value);
      } else if (value.body == "{\"results\":[]}"){
        return _handleSuccessWithNoResults(response, "Successful request, but no results found");
      } else {
        return _handleSuccess(response, object, value.body);
      }
    } else {
      response.exception = ParseException();
      response.exception.message = "Error reaching server, or server response was null";
      return response;
    }
  }

  /// Handles any errors returned in response
  static ParseResponse _handleError(ParseResponse response, Response value) {
    response.exception = ParseException();
    response.exception.message = value.reasonPhrase;
    return response;
  }

  /// Handles successful responses with no results
  static ParseResponse _handleSuccessWithNoResults(ParseResponse response, String value) {
    response.statusCode = 200;
    response.exception = ParseException();
    response.exception.message = value;
    return response;
  }

  /// Handles succsful response with results
  static ParseResponse _handleSuccess(ParseResponse response, ParseObject object, String responseBody) {
    response.success = true;

    var map = JsonDecoder().convert(responseBody) as Map;

    if (map != null && map.length == 1 && map.containsKey('results')) {
      response.result = _handleMultipleResults(object, map.entries.first.value);
    } else {
      response.result = _handleSingleResult(object, map);
    }

    return response;
  }

  /// Handles a response with a multiple result object
  static _handleMultipleResults(ParseObject object, dynamic map) {
    var resultsList = List();

    for (var value in map) {
      resultsList.add(_handleSingleResult(object, value));
    }

    return resultsList;
  }

  /// Handles a response with a single result object
  static _handleSingleResult(ParseObject object, map) {
    populateObjectBaseData(object, map);
    return object.fromJson(map);
  }
}
