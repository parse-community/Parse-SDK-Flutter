import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class QueryBuilder <T extends ParseObject> {

  T object;
  final ParseHTTPClient client = ParseHTTPClient();
  String path;
  String field;
  Map results;
  Map constraint;
  Map<String, Map<String, String>> whereMap = Map();

  // QueryParams
  List<dynamic> equals;
  List<dynamic> lessThan;
  List<dynamic> lessThanOrEqualTo;
  List<dynamic> greaterThan;
  List<dynamic> greaterThanOrEqualTo;
  List<dynamic> notEqualTo;
  List<dynamic> contains;
  List<dynamic> containedIn;
  List<dynamic> notContainedIn;
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

  QueryBuilder(this.object) : super();

  void ascending(String attribute) {}

  void descending(String attribute) {}

  void startsWith(String key, dynamic value) {}

  query() async {
    return object.query(_buildQuery());
  }

  String _buildQuery() {
    var existsMap = Map();

    // START QUERY
    String query = "where=";

    // ADD PARAM TO MAP

    //Needs fixing
    if (equals != null) existsMap = _runThroughQueryParams(equals, field);
    if (contains != null) existsMap = _runThroughQueryParamsWithName(contains, "\$term", field);

    // Works
    if (lessThan != null) existsMap = _runThroughQueryParamsWithName(lessThan, "\$lt", field);
    if (lessThanOrEqualTo != null) existsMap = _runThroughQueryParamsWithName(lessThanOrEqualTo, "\$lte", field);
    if (greaterThan != null) existsMap = _runThroughQueryParamsWithName(greaterThan, "\$gt", field);
    if (greaterThanOrEqualTo != null) existsMap = _runThroughQueryParamsWithName(greaterThanOrEqualTo, "\$gte", field);
    if (notEqualTo != null) existsMap = _runThroughQueryParamsWithName(notEqualTo, "\$ne", field);

    // Not sure
    if (containedIn != null) existsMap = _runThroughQueryParamsWithName(containedIn, "\$in", field);
    if (notContainedIn != null) existsMap = _runThroughQueryParamsWithName(notContainedIn, "\$nin", field);
    if (exists != null) existsMap = _runThroughQueryParamsWithName(exists, "\$exists", field);
    if (select != null) existsMap = _runThroughQueryParamsWithName(select, "\$select", field);
    if (dontSelect != null) existsMap = _runThroughQueryParamsWithName(dontSelect, "\$dontSelect", field);
    if (all != null) existsMap = _runThroughQueryParamsWithName(all, "\$all", field);

    // Works
    if (regEx != null) existsMap = _runThroughQueryParamsWithName(regEx, "\$regex", field);

    // Doesnt
    if (text != null) existsMap = _runThroughQueryParamsWithName(text, "\$text", field);

    // -- BUILD QUERY USING MAP
    for(var item in existsMap.entries){
      query += "{\"${item.key.toString()}\":${item.value}}";
    }

    // -- ADD LIMITER
    if (limit != 0) query += '?limit=$limit';
    if (skip != 0) query += '?skip=$skip';

    // -- TEST
    print("QUERY: $query");

    return query;
  }

  Map _runThroughQueryParams(List<dynamic> list, String queryParam) {
    Map<String, dynamic> mapToReturn = Map<String, dynamic>();
    var params;

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

  Map<String, String> _runThroughQueryParamsWithName(List<dynamic> list, String queryParam, String fieldName) {
    Map<String, String> mapToReturn = Map<String, String>();
    Map<String, dynamic> mapWithParamData = Map<String, dynamic>();

    for (var item in list) {
      mapWithParamData.putIfAbsent(queryParam, item);
    }

    var params =  JsonEncoder().convert(mapWithParamData);

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
