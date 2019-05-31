part of flutter_parse_sdk;

/// Handles any errors returned in response
ParseResponse buildErrorResponse(ParseResponse response, Response apiResponse) {

  if (apiResponse.body == null) {
    return null;
  }

  final Map<String, dynamic> responseData = json.decode(apiResponse.body);
  response.error = ParseError(code: responseData[keyCode], message: responseData[keyError].toString());
  response.statusCode = responseData[keyCode];
  return response;
}
