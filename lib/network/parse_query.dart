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
    var queries = List<String>();

    // START QUERY
    const String QUERY_START = "where={";
    const String QUERY_END = "}";

    var query = QUERY_START;

    // ADD PARAM TO MAP
    //Needs fixing
    if (equals != null) queries.add(_runThroughQueryParams(equals, field));
    if (contains != null) queries.add(_buildQueryWithOperatorAndField(contains, "\$term", field));

    // Works
    if (lessThan != null) queries.add(_buildQueryWithOperatorAndField(lessThan, "\$lt", field));
    if (lessThanOrEqualTo != null) queries.add(_buildQueryWithOperatorAndField(lessThanOrEqualTo, "\$lte", field));
    if (greaterThan != null) queries.add(_buildQueryWithOperatorAndField(greaterThan, "\$gt", field));
    if (greaterThanOrEqualTo != null) queries.add(_buildQueryWithOperatorAndField(greaterThanOrEqualTo, "\$gte", field));
    if (notEqualTo != null) queries.add(_buildQueryWithOperatorAndField(notEqualTo, "\$ne", field));

    // Not sure
    if (containedIn != null) queries.add(_buildQueryWithOperatorAndField(containedIn, "\$in", field));
    if (notContainedIn != null) queries.add(_buildQueryWithOperatorAndField(notContainedIn, "\$nin", field));
    if (exists != null) queries.add(_buildQueryWithOperatorAndField(exists, "\$exists", field));
    if (select != null) queries.add(_buildQueryWithOperatorAndField(select, "\$select", field));
    if (dontSelect != null) queries.add( _buildQueryWithOperatorAndField(dontSelect, "\$dontSelect", field));
    if (all != null) queries.add(_buildQueryWithOperatorAndField(all, "\$all", field));

    // Works
    if (regEx != null) queries.add(_buildQueryWithOperatorAndField(regEx, "\$regex", field));

    // Doesnt
    if (text != null) queries.add(_buildQueryWithOperatorAndField(text, "\$text", field));

    // -- BUILD QUERY USING MAP
    for(var item in queries){
      if (query == QUERY_START) {
        query += item;
      } else {
        query += ",$item";
      }
    }

    // -- ADD LIMITER
    if (limit != 0) query += '?limit=$limit';
    if (skip != 0) query += '?skip=$skip';

    query += QUERY_END;

    // -- TEST
    print("QUERY: $query");

    return query;
  }

  _buildQueryWithOperatorAndField(List<dynamic> listOfValuesToQuery, String queryOperator, String tableNameToQuery) {

    var queryOperatorAndValueMap = Map();
    var queryString = "\"$tableNameToQuery\":";

    for (var queryValue in listOfValuesToQuery) {
      queryOperatorAndValueMap[queryOperator] = queryValue;
    }

    var formattedQueryOperatorAndValue = JsonEncoder().convert(queryOperatorAndValueMap);
    queryString += "$formattedQueryOperatorAndValue";

    return queryString;
  }

  _runThroughQueryParams(List<dynamic> list, String queryParam) {
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

    return JsonEncoder().convert(mapToReturn);
  }

  Map<String, String> _runThroughQueryParamsWithSearchTerms(List<dynamic> list, String queryParam, String fieldName) {
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
