part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseError error;
}