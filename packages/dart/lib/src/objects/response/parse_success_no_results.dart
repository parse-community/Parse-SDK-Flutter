part of '../../../parse_server_sdk.dart';

/// Handles successful responses with no results
ParseResponse buildSuccessResponseWithNoResults(
    ParseResponse response, int code, String value) {
  response.success = true;
  response.statusCode = 200;
  response.error = ParseError(code: code, message: value);
  return response;
}
