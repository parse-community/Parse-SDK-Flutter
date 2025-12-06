part of '../../../parse_server_sdk.dart';

/// Handles any errors returned in response
ParseResponse buildErrorResponse(
  ParseResponse response,
  ParseNetworkResponse apiResponse,
) {
  try {
    final Map<String, dynamic> responseData = json.decode(apiResponse.data);

    response.error = ParseError(
      code: responseData[keyCode] ?? ParseError.otherCause,
      message: responseData[keyError].toString(),
    );

    response.statusCode = responseData[keyCode] ?? ParseError.otherCause;
  } on FormatException catch (e) {
    // Handle non-JSON responses (e.g., HTML from proxy/load balancer)
    final String preview = apiResponse.data.length > 100
        ? '${apiResponse.data.substring(0, 100)}...'
        : apiResponse.data;

    response.error = ParseError(
      code: ParseError.otherCause,
      message: 'Invalid response format (expected JSON): $preview',
      exception: e,
    );

    response.statusCode = ParseError.otherCause;
  }

  return response;
}
