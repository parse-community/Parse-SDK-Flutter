import 'dart:convert';

import 'package:http/http.dart';
import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/objects/parse_exception.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/utils/parse_utils_objects.dart';

class ParseResponse {
  bool success = false;
  int statusCode = -1;
  dynamic result;
  ParseException exception;

  static handleResponse(ParseBase object, Response value) {
    var response = ParseResponse();

    if (value != null) {
      response.statusCode = value.statusCode;

      if (value.statusCode != 200) {
        return _handleError(response, value);
      } else if (value.body == "{\"results\":[]}"){
        return _handleSuccessWithNoResults(response, "Successful request, but no results found");
      } else {
        return _handleSuccess(response, object, value.body);
      }
    } else {
      response.exception = ParseException();
      response.exception.message = "Error reaching server, or server response was null";
      return response;
    }
  }

  static ParseResponse _handleError(ParseResponse response, Response value) {
    response.exception = ParseException();
    response.exception.message = value.reasonPhrase;
    return response;
  }

  static ParseResponse _handleSuccessWithNoResults(ParseResponse response, String value) {
    response.statusCode = 200;
    response.exception = ParseException();
    response.exception.message = value;
    return response;
  }

  static ParseResponse _handleSuccess(ParseResponse response, ParseObject object, String responseBody) {
    response.success = true;

    var map = JsonDecoder().convert(responseBody) as Map;

    if (map != null && map.length == 1 && map.containsKey('results')) {
      response.result = _handleMultipleResults(object, map.entries.first.value);
    } else {
      response.result = _handleSingleResult(object, map);
    }

    return response;
  }

  static _handleMultipleResults(ParseObject object, dynamic map) {
    var resultsList = List();

    for (var value in map) {
      resultsList.add(_handleSingleResult(object, value));
    }

    return resultsList;
  }

  static _handleSingleResult(ParseObject object, map) {
    populateObjectBaseData(object, map);
    return object.fromJson(map);
  }
}
