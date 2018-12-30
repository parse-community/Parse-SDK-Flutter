import 'dart:convert';

import 'package:parse_server_sdk/objects/parse_exception.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/utils/parse_utils_objects.dart';
import 'package:http/http.dart';

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseException exception;

  static ParseResponse _handleSuccess(
      ParseResponse response, ParseObject object, String responseBody) {
    response.success = true;

    var map = JsonDecoder().convert(responseBody) as Map;

    if (map != null && map.length == 1 && map.containsKey('results')) {
      response.result = _handleMultipleResults(object, map.entries.first.value);
    } else {
      response.result = _handleSingleResult(object, map);
    }

    response = _checkForEmptyResult(response);

    return response;
  }

  static ParseResponse _checkForEmptyResult(ParseResponse response) {
    if (response.result == null ||
        ((response.result == List) &&
            (response.result as List<ParseObject>).length == 0)) {
      response.exception = ParseException();
      response.exception.message = "No result found for query";
      response.success = false;
    }

    return response;
  }

  static List<ParseObject> _handleMultipleResults(
      ParseObject object, dynamic map) {
    var resultsList = List<ParseObject>();

    for (var value in map) {
      resultsList.add(_handleSingleResult(object.copy(), value));
    }

    return resultsList;
  }

  static ParseObject _handleSingleResult(ParseObject object, map) {
    ParseUtilsObjects.populateObjectBaseData(object, map);
    return object.fromJson(map);
  }

  static ParseResponse _handleError(
      ParseResponse response, Response value) {
    response.exception = ParseException();
    response.exception.message = value.reasonPhrase;
    return response;
  }

  static handleResponse(ParseObject object, Response value) {
    var response = ParseResponse();

    if (value != null) {
      response.statusCode = value.statusCode;

      if (value.statusCode != 200) {
        return _handleError(response, value);
      } else {
        return _handleSuccess(response, object, value.body);
      }
    } else {
      response.exception = ParseException();
      response.exception.message =
          "Error reaching server, or server response was null";
      return response;
    }
  }
}
