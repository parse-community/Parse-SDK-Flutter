part of flutter_parse_sdk;

/// Handles exception instead of throwing an exception
ParseResponse buildParseResponseWithException(Exception exception) {
  final ParseResponse response = ParseResponse();
  if (exception is DioError) {
    try {
      final Map<String, dynamic> errorResponse =
          json.decode(exception.response?.data?.toString() ?? '{}');

      response.error = ParseError(
        message: errorResponse['error']?.toString(),
        exception: exception,
        code: errorResponse['code'],
      );
    } catch (error) {
      response.error = ParseError(
          message: "Failed to build ParseResponse with exception",
          exception: error);
    }
  } else {
    response.error =
        ParseError(message: exception.toString(), exception: exception);
  }
  return response;
}
