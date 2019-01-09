part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseError error;

  /// Handles all the ParseObject responses
  ///
  /// There are 3 probable outcomes from a Parse API call,
  /// 1. Fail - [ParseResponse] will be returned with further details
  /// 2. Success but no results. [ParseResponse] is returned.
  /// 3. Success with results. Again [ParseResponse] is returned
  static handleResponse(ParseBase object, Response apiResponse) {
    var parseResponse = ParseResponse();

    if (apiResponse != null) {
      parseResponse.statusCode = apiResponse.statusCode;

      if (apiResponse.statusCode != 200) {
        return _handleError(parseResponse, apiResponse);
      } else if (apiResponse.body == "{\"results\":[]}"){
        return _handleSuccessWithNoResults(parseResponse, "Successful request, but no results found");
      } else {
        return _handleSuccess(parseResponse, object, apiResponse.body);
      }
    } else {
      parseResponse.error = ParseError(message: "Error reaching server, or server response was null");
      return apiResponse;
    }
  }

  /// Handles exception instead of throwing an exception
  static handleException(ParseBase object, Exception exception) {
    var response = ParseResponse();
    response.error = ParseError(message: exception.toString(), isTypeOfException: true);
    return response;
  }

  /// Handles any errors returned in response
  static ParseResponse _handleError(ParseResponse response, Response apiResponse) {
    Map<String, dynamic> responseData = JsonDecoder().convert(apiResponse.body);
    response.error = ParseError(code: responseData['code'], message: responseData['error']);
    return response;
  }

  /// Handles successful responses with no results
  static ParseResponse _handleSuccessWithNoResults(ParseResponse response, String value) {
    response.statusCode = 200;
    response.error = ParseError(code: 1, message: value);
    return response;
  }

  /// Handles successful response with results
  static ParseResponse _handleSuccess(ParseResponse response, ParseBase object, String responseBody) {
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
  static _handleMultipleResults(ParseBase object, dynamic map) {
    var resultsList = List();

    for (var value in map) {
      resultsList.add(_handleSingleResult(object, value));
    }

    return resultsList;
  }

  /// Handles a response with a single result object
  static _handleSingleResult(ParseBase object, map) {
    populateObjectBaseData(object, map);
    return object.fromJson(map);
  }
}
