part of flutter_parse_sdk;

/// Handles exception instead of throwing an exception
ParseResponse buildParseResponseWithException(Exception exception) {
  if (exception is DioError) {
    Map<String, dynamic> errorResponse = {};
    try {
      errorResponse = json.decode(exception.response?.data?.toString() ?? '{}');
    } on FormatException catch (_) {}

    final errorMessage =
        errorResponse['error']?.toString() ?? exception.response?.statusMessage;

    final errorCode =
        int.tryParse(errorResponse['code']) ?? exception.response?.statusCode;

    return ParseResponse(
        error: ParseError(
      message: errorMessage ?? exception.toString(),
      exception: exception,
      code: errorCode ?? -1,
    ));
  }

  return ParseResponse(
      error: ParseError(message: exception.toString(), exception: exception));
  ;
}
