part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;

  /// If result is a singular result, i.e. getByObjectID
  dynamic result;

  /// All results stored as a list - Even if only one response is returned
  // ignore: always_specify_types
  List results;
  int count = 0;
  ParseError error;
}
