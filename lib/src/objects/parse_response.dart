part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseError error;

  /// Handles all the ParseObject responses
  ///
  /// There are 4 probable outcomes from a Parse API call,
  /// 1. Fail - [ParseResponse()] will be returned with further details
  /// 2. Success but no results. [ParseResponse()] is returned.
  /// 3. Success with simple OK.
  /// 4. Success with results. Again [ParseResponse()] is returned
  static handleResponse<T extends ParseBase>(
      dynamic object, Response apiResponse,
      {bool returnAsResult: false}) {
    var parseResponse = ParseResponse();

    if (apiResponse != null) {
      parseResponse.statusCode = apiResponse.statusCode;

      if (apiResponse.statusCode != 200 && apiResponse.statusCode != 201) {
        return _handleError(parseResponse, apiResponse);
      } else if (apiResponse.body == "{\"results\":[]}") {
        return _handleSuccessWithNoResults(
            parseResponse, 1, "Successful request, but no results found");
      } else if (returnAsResult) {
        return _handleSuccessWithoutParseObject(
            parseResponse, object, apiResponse.body);
      } else {
        return _handleSuccess<T>(parseResponse, object, apiResponse.body);
      }
    } else {
      parseResponse.error = ParseError(
          message: "Error reaching server, or server response was null");
      return apiResponse;
    }
  }

  /// Handles exception instead of throwing an exception
  static ParseResponse handleException(Exception exception) {
    var response = ParseResponse();
    response.error =
        ParseError(message: exception.toString(), isTypeOfException: true);
    return response;
  }

  /// Handles any errors returned in response
  static ParseResponse _handleError(
      ParseResponse response, Response apiResponse) {
    Map<String, dynamic> responseData = json.decode(apiResponse.body);
    response.error = ParseError(
        code: responseData['code'], message: responseData['error'].toString());
    response.statusCode = responseData['code'];
    return response;
  }

  /// Handles successful responses with no results
  static ParseResponse _handleSuccessWithNoResults(
      ParseResponse response, int code, String value) {
    response.success = true;
    response.statusCode = 200;
    response.error = ParseError(code: code, message: value);
    return response;
  }

  /// Handles successful response without creating a ParseObject
  static ParseResponse _handleSuccessWithoutParseObject(
      ParseResponse response, dynamic object, String responseBody) {
    response.success = true;

    if (responseBody == "OK") {
      response.result = responseBody;
    } else if (json.decode(responseBody).containsKey('params')) {
      response.result = json.decode(responseBody)['params'];
    } else {
      response.result = json.decode(responseBody);
    }

    return response;
  }

  /// Handles successful response with results
  static ParseResponse _handleSuccess<T extends ParseBase>(
      ParseResponse response, dynamic object, String responseBody) {
    response.success = true;

    var map = json.decode(responseBody) as Map;

    if (map != null && map.length == 1 && map.containsKey('results')) {
      response.result =
          _handleMultipleResults<T>(object, map.entries.first.value);
    } else {
      response.result = _handleSingleResult<T>(object, map);
    }

    return response;
  }

  /// Handles a response with a multiple result object
  static List<T> _handleMultipleResults<T extends ParseBase>(
      dynamic object, dynamic map) {
    var resultsList = List<T>();

    for (var value in map) {
      resultsList.add(_handleSingleResult<T>(object, value));
    }

    return resultsList;
  }

  /// Handles a response with a single result object
  static T _handleSingleResult<T extends ParseBase>(dynamic object, map) {
    if (object is Parse) return map;
    if (object is ParseCloneable) return object.clone(map);
    return null;
  }
}

/// Handles an API response and logs data if [bool] debug is enabled
@protected
ParseResponse handleResponse<T extends ParseObject>(ParseCloneable object,
    Response response, ParseApiRQ type, bool debug, String className) {
  ParseResponse parseResponse = ParseResponse.handleResponse<T>(
      object, response,
      returnAsResult: shouldReturnAsABaseResult(type));

  if (debug) {
    logger(ParseCoreData().appName, className, type.toString(), parseResponse);
  }

  return parseResponse;
}

/// Handles an API response and logs data if [bool] debug is enabled
@protected
ParseResponse handleException(
    Exception exception, ParseApiRQ type, bool debug, String className) {
  ParseResponse parseResponse = ParseResponse.handleException(exception);

  if (debug) {
    logger(ParseCoreData().appName, className, type.toString(), parseResponse);
  }

  return parseResponse;
}

bool shouldReturnAsABaseResult(ParseApiRQ type) {
  if (type == ParseApiRQ.healthCheck ||
      type == ParseApiRQ.execute ||
      type == ParseApiRQ.add ||
      type == ParseApiRQ.addAll ||
      type == ParseApiRQ.addUnique ||
      type == ParseApiRQ.remove ||
      type == ParseApiRQ.removeAll ||
      type == ParseApiRQ.increment ||
      type == ParseApiRQ.decrement ||
      type == ParseApiRQ.getConfigs ||
      type == ParseApiRQ.addConfig) {
    return true;
  } else {
    return false;
  }
}
