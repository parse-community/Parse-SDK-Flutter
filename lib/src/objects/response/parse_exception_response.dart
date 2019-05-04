part of flutter_parse_sdk;

/// Handles exception instead of throwing an exception
ParseResponse buildParseResponseWithException(Exception exception) {
  final ParseResponse response = ParseResponse();
  response.error =
      ParseError(message: exception.toString(), isTypeOfException: true);
  return response;
}
