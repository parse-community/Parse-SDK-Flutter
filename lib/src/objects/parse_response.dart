part of flutter_parse_sdk;

class ParseResponse<T extends ParseBase> {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseError error;
}
