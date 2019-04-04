part of flutter_parse_sdk;

class ParseResponse {
  bool success = false;
  int statusCode = -1;

  /// If result is a singular result, i.e. getByObjectID
  ///
  /// This is now deprecated - Please use results. This will contain a list of
  /// results, no need to check if its a list or a list of elements anymore.
  dynamic result;

  /// All results stored as a list - Even if only one response is returned
  // ignore: always_specify_types
  List results;
  int count = 0;
  ParseError error;
}
