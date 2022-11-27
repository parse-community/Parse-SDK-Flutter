part of flutter_parse_sdk;

/// Handles any errors returned in response
ParseResponse buildErrorResponse(
    ParseResponse response, ParseNetworkResponse apiResponse) {
  final Map<String, dynamic> responseData = json.decode(apiResponse.data);
  response.error = ParseError(
      code: apiResponse.statusCode, message: responseData[keyError].toString());
  response.statusCode = apiResponse.statusCode;
  return response;
}