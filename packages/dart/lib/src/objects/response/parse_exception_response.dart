part of flutter_parse_sdk;

/// Handles exception instead of throwing an exception
ParseResponse buildParseResponseWithException(Exception exception) {
  final ParseResponse response = ParseResponse();
  if (exception is DioError) {
    try {
      Map<String, dynamic> errorResponse;

      try {
        errorResponse =
            json.decode(exception.response?.data?.toString() ?? '{}');
      } catch (_) {}

      errorResponse ??= <String, dynamic>{};

      response.error = ParseError(
        message: errorResponse['error']?.toString() ??
            exception.response?.statusMessage,
        exception: exception,
        code: errorResponse['code'] ?? exception.response?.statusCode,
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
