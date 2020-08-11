part of flutter_parse_sdk;

/// Handles an API response and logs data if [bool] debug is enabled
@protected
ParseResponse handleResponse<T>(dynamic object, Response<String> response,
    ParseApiRQ type, bool debug, String className) {
  final ParseResponse parseResponse =
      _ParseResponseBuilder().handleResponse<T>(object, response, type);

  if (debug) {
    logAPIResponse(className, type.toString(), parseResponse);
  }

  return parseResponse;
}

/// Handles an API response and logs data if [bool] debug is enabled
@protected
ParseResponse handleException(
    Exception exception, ParseApiRQ type, bool debug, String className) {
  final ParseResponse parseResponse =
      buildParseResponseWithException(exception);

  if (debug) {
    logAPIResponse(className, type.toString(), parseResponse);
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

bool isUnsuccessfulResponse(Response<String> apiResponse) =>
    apiResponse.statusCode != 200 && apiResponse.statusCode != 201;

bool isSuccessButNoResults(Response<String> apiResponse) {
  final dynamic decodedResponse = jsonDecode(apiResponse.data);
  List<dynamic> results;
  if (decodedResponse is Map<String, dynamic>) {
    results = decodedResponse['results'];
  } else if (decodedResponse is List<dynamic>) {
    results = decodedResponse;
  }

  if (results == null) {
    return false;
  }

  return results.isEmpty;
}
