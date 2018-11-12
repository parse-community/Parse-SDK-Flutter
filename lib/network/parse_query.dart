import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class QueryBuilder implements ParseBaseObject {
  // BaseParams
  // String _className;
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

  QueryBuilder();

  void ascending(String attribute) {}

  void descending(String attribute) {}

  void startsWith(String key, dynamic value) {}

  Future<Map> first() {
    Map<String, dynamic> t = {};
    foo() => t;
    return new Future(foo);
  }

  Future<ParseResponse> query() async {
    return object.getQuery(_buildQuery());
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

    print("existsMap: $existsMap");

    // String query = r"""where={"Name":{"$text":{"$search":{"$term":"gg"}}}}""";
    // String s1 = existsMap.toString();
    // print("s1: $s1");
    String query = "where=${JsonEncoder().convert(existsMap.toString())}";
    // String s = r'{"title":{"$text":{"$search":{"$term":"gg"}}}}';
    // String query = "where=${JsonEncoder().convert(s)}";

    // query: where="{\"title\":{\"$text\":{\"$search\":{\"$term\":\"gg\"}}}}"
    // where    : {\"title\":{\"$text\":{\"$search\":{\"$term\":\"gg\"}}}}
    // existsMap: {title: {"text":"{\"search\":\"{\\\"$term\\\":\\\"gg\\\"}\"}"}}
    // existsMap: {title: {"$text":"{\"$search\":\"{\\\"$term\\\":\\\"gg\\\"}\"}"}}
    // request: GET http://118.24.162.252:2018/parse/classes/post?where=%22%7B%5C%22title%5C%22:%7B%5C%22$text%5C%22:%7B%5C%22$search%5C%22:%7B%5C%22$term%5C%22:%5C%22gg%5C%22%7D%7D%7D%7D%22

    if (limit != 0) query += '?limit=$limit';
    if (skip != 0) query += '?skip=$skip';
    print("query: $query");
    return query;
  }

  Map<String, String> _runThroughQueryParams(
      List<dynamic> list, String queryParam) {
    Map<String, String> mapToReturn = Map<String, String>();
    var params = "";

    if (list.isNotEmpty) {
      if (list.length == 1) {
        params = '"${list[0]}"';
      } else {
        for (var listItem in list) {
          params += '"$listItem", ';
        }

        params.substring(0, params.length - 2);
      }
    }

    mapToReturn['"$queryParam"'] = params;
    print(mapToReturn);
    return mapToReturn;
  }

  Map<String, String> _runThroughQueryParamsWithName(
      List<dynamic> list, String queryParam, String fieldName) {
    Map<String, String> mapToReturn = Map<String, String>();
    Map<String, dynamic> mapWithParamData = Map<String, dynamic>();
    List s = new List();
    for (var item in list) {
      // mapWithParamData['"\$$queryParam"'] = '"$item"';
      s.add('"$item"');
    }
    mapWithParamData['"\$$queryParam"'] = s;

    // var params = JsonEncoder().convert(mapWithParamData).toString();
    // mapToReturn[fieldName] = params;
    mapToReturn['"$fieldName"'] = mapWithParamData.toString();

    return mapToReturn;
  }

  Map<String, String> _runThroughQueryParamsWithSearchTerms(
      List<dynamic> list, String queryParam, String fieldName) {
    Map<String, String> mapToReturn = Map<String, String>();
    Map<String, dynamic> mapWithParamData = Map<String, dynamic>();
    Map<String, String> textEntry = Map<String, String>();
    Map<String, String> searchEntry = Map<String, String>();

    for (var item in list) {
      mapWithParamData['"\$$queryParam"'] = '"$item"';
    }

    // var jsonMapWithParamData = JsonEncoder().convert(mapWithParamData);
    // searchEntry['\$search'] = jsonMapWithParamData;
    searchEntry['"\$search"'] = mapWithParamData.toString();

    // var jsonSearchEntry = JsonEncoder().convert(searchEntry);
    // textEntry['\$text'] = jsonSearchEntry;
    textEntry['"\$text"'] = searchEntry.toString();

    // var params = JsonEncoder().convert(textEntry);
    // mapToReturn['$fieldName'] = params;

    // textEntry[fieldName] = textEntry.toString();
    // print(textEntry.toString());
    mapToReturn['"$fieldName"'] = textEntry.toString();
    // print(mapToReturn.toString());

    // mapToReturn = textEntry;

    return mapToReturn;
  }
}
