part of '../../../parse_server_sdk.dart';

/// Handles any errors returned in response
ParseResponse buildErrorResponse(
    ParseResponse response, ParseNetworkResponse apiResponse) {
  final Map<String, dynamic> responseData = json.decode(apiResponse.data);

  response.error = ParseError(
    code: responseData[keyCode] ?? ParseError.otherCause,
    message: responseData[keyError].toString(),
  );

  response.statusCode = responseData[keyCode] ?? ParseError.otherCause;

  return response;
}
