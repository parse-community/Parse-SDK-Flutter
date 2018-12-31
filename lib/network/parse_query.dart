import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class QueryBuilder {

  ParseObject object;
  final ParseHTTPClient client = ParseHTTPClient();
  String path;
  String field;
  Map results;
  Map constraint;
  Map<String, Map<String, String>> whereMap =
      Map<String, Map<String, String>>();

  // QueryParams
  List<dynamic> equals;
  List<dynamic> lessThan;
  List<dynamic> lessThanOrEqualTo;
  List<dynamic> greaterThan;
  List<dynamic> greaterThanOrEqualTo;
  List<dynamic> notEqualTo;
  List<dynamic> contains;
  List<dynamic> containedIn;
  List<dynamic> notContainerIn;
  List<dynamic> exists;
  List<dynamic> select;
  List<dynamic> dontSelect;
  List<dynamic> all;
  List<dynamic> regEx;
  List<dynamic> text;
  int limit = 0;
  int skip = 0;

  String get objectId => null;
  Map<String, dynamic> objectData = {};

  QueryBuilder() : super();

  void ascending(String attribute) {}

  void descending(String attribute) {}

  void startsWith(String key, dynamic value) {}

  Future<Map> first() {
    Map<String, dynamic> t = {};
    foo() => t;
    return new Future(foo);
  }

  query() async {
    return object.query(_buildQuery());
  }

  String _buildQuery() {
    var existsMap = Map<String, String>();

    if (equals != null) existsMap = _runThroughQueryParams(equals, field);
    if (containedIn != null)
      existsMap = _runThroughQueryParamsWithName(containedIn, "in", field);
    if (regEx != null)
      existsMap = _runThroughQueryParamsWithName(regEx, "regex", field);
    if (greaterThan != null)
      existsMap = _runThroughQueryParamsWithName(greaterThan, "gt", field);
    if (contains != null)
      existsMap =
          _runThroughQueryParamsWithSearchTerms(contains, "term", field);

    //String query = r"""where={"Name":{"$text":{"$search":{"$term":"Diet"}}}}""";
    String query = "where=${JsonEncoder().convert(existsMap)}";

    if (limit != 0) query += '?limit=$limit';
    if (skip != 0) query += '?skip=$skip';

    return query;
  }

  Map<String, String> _runThroughQueryParams(
      List<dynamic> list, String queryParam) {
    Map<String, String> mapToReturn = Map<String, String>();
    var params = "";

    if (list.isNotEmpty) {
      if (list.length == 1) {
        params = list[0];
      } else {
        for (var listItem in list) {
          params += "$listItem, ";
        }

        params.substring(0, params.length - 2);
      }
    }

    mapToReturn[queryParam] = params;

    return mapToReturn;
  }

  Map<String, String> _runThroughQueryParamsWithName(
      List<dynamic> list, String queryParam, String fieldName) {
    Map<String, String> mapToReturn = Map<String, String>();
    Map<String, dynamic> mapWithParamData = Map<String, dynamic>();

    for (var item in list) {
      mapWithParamData["\$$queryParam"] = item;
    }

    var params = JsonEncoder().convert(mapWithParamData).toString();

    mapToReturn[fieldName] = params;

    return mapToReturn;
  }

  Map<String, String> _runThroughQueryParamsWithSearchTerms(
      List<dynamic> list, String queryParam, String fieldName) {
    Map<String, String> mapToReturn = Map<String, String>();
    Map<String, dynamic> mapWithParamData = Map<String, dynamic>();
    Map<String, String> textEntry = Map<String, String>();
    Map<String, String> searchEntry = Map<String, String>();

    for (var item in list) {
      mapWithParamData["\$$queryParam"] = item;
    }

    var jsonMapWithParamData = JsonEncoder().convert(mapWithParamData);
    searchEntry['search'] = jsonMapWithParamData;

    var jsonSearchEntry = JsonEncoder().convert(searchEntry);
    textEntry['text'] = jsonSearchEntry;

    var params = JsonEncoder().convert(textEntry).toString();
    mapToReturn[fieldName] = params;

    return mapToReturn;
  }
}
