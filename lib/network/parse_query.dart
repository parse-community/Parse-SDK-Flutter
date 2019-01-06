import 'dart:convert';

import 'package:parse_server_sdk/objects/parse_object.dart';

class QueryBuilder<T extends ParseObject> {

  T object;

  // QueryParams
  List<MapEntry> _equalsQueries = List();
  List<MapEntry> _lessThanQueries = List();
  List<MapEntry> _lessThanOrEqualToQueries = List();
  List<MapEntry> _greaterThanQueries = List();
  List<MapEntry> _greaterThanOrEqualToQueries = List();
  List<MapEntry> _notEqualToQueries = List();
  List<MapEntry> _containsQueries = List();
  List<MapEntry> _containedInQueries = List();
  List<MapEntry> _notContainedInQueries = List();
  List<MapEntry> _existsQueries = List();
  List<MapEntry> _selectQueries = List();
  List<MapEntry> _dontSelectQueries = List();
  List<MapEntry> _allQueries = List();
  List<MapEntry> _regExQueries = List();
  List<MapEntry> _textQueries = List();
  int limit = 0;
  int skip = 0;

  QueryBuilder(this.object) : super();

  void startsWith(String key, dynamic value) {
    _regExQueries.add(MapEntry(key, "^$value"));
  }

  void endsWith(String key, dynamic value) {
    _regExQueries.add(MapEntry(key, "$value^"));
  }

  void equals(String column, dynamic value) {
    _equalsQueries.add(MapEntry(column, value));
  }

  void lessThan(String column, dynamic value) {
    _lessThanQueries.add(MapEntry(column, value));
  }

  void lessThanOrEqualTo(String column, dynamic value) {
    _lessThanOrEqualToQueries.add(MapEntry(column, value));
  }

  void greaterThan(String column, dynamic value) {
    _greaterThanQueries.add(MapEntry(column, value));
  }

  void greaterThanOrEqualsTo(String column, dynamic value) {
    _greaterThanOrEqualToQueries.add(MapEntry(column, value));
  }

  void notEqualTo(String column, dynamic value) {
    _notEqualToQueries.add(MapEntry(column, value));
  }

  void contains(String column, dynamic value) {
    _containsQueries.add(MapEntry(column, value));
  }

  void containedIn(String column, dynamic value) {
    _containedInQueries.add(MapEntry(column, value));
  }

  void exists(String column, dynamic value) {
    _existsQueries.add(MapEntry(column, value));
  }

  void select(String column, dynamic value) {
    _selectQueries.add(MapEntry(column, value));
  }

  void dontSelect(String column, dynamic value) {
    _dontSelectQueries.add(MapEntry(column, value));
  }

  void all(String column, dynamic value) {
    _allQueries.add(MapEntry(column, value));
  }

  void regEx(String column, dynamic value) {
    _regExQueries.add(MapEntry(column, value));
  }

  void text(String column, dynamic value) {
    _textQueries.add(MapEntry(column, value));
  }

  query() async {
    return object.query(_buildQuery());
  }

  String _buildQuery() {
    var queries = List<MapEntry>();

    // START QUERY
    const String QUERY_START = "where={";
    const String QUERY_END = "}";

    var query = QUERY_START;

    // ADD PARAM TO MAP
    //Needs fixing
    if (_equalsQueries.length != 0) queries.addAll(_runThroughQueryParams(_equalsQueries));
    if (_containsQueries.length != 0) queries.addAll(_getAllQueries(_containsQueries, "\$term"));

    // Works
    if (_lessThanQueries.length != 0) queries.addAll(_getAllQueries(_lessThanQueries, "\$lt"));
    if (_lessThanOrEqualToQueries.length != 0) queries.addAll(_getAllQueries(_lessThanOrEqualToQueries, "\$lte"));
    if (_greaterThanQueries.length != 0) queries.addAll(_getAllQueries(_greaterThanQueries, "\$gt"));
    if (_greaterThanOrEqualToQueries.length != 0) queries.addAll(_getAllQueries(_greaterThanOrEqualToQueries, "\$gte"));
    if (_notEqualToQueries.length != 0) queries.addAll(_getAllQueries(_notEqualToQueries, "\$ne"));

    // Not sure
    if (_containedInQueries.length != 0) queries.addAll(_getAllQueries(_containedInQueries, "\$in"));
    if (_notContainedInQueries.length != 0) queries.addAll(_getAllQueries(_notContainedInQueries, "\$nin"));
    if (_existsQueries.length != 0) queries.addAll(_getAllQueries(_existsQueries, "\$exists"));
    if (_selectQueries.length != 0) queries.addAll(_getAllQueries(_selectQueries, "\$select"));
    if (_dontSelectQueries.length != 0) queries.addAll(_getAllQueries(_dontSelectQueries, "\$dontSelect"));
    if (_allQueries.length != 0) queries.addAll(_getAllQueries(_allQueries, "\$all"));

    // Works
    if (_regExQueries.length != 0) queries.addAll(_getAllQueries(_regExQueries, "\$regex"));

    // Doesnt
    if (_textQueries.length != 0) queries.addAll(_getAllQueries(_textQueries, "\$text"));

    queries = _checkForMultipleColumnInstances(queries);

    // -- BUILD QUERY USING MAP
    for (var item in queries) {
      if (query == QUERY_START) {
        query += item.value;
      } else {
        query += ",${item.value}";
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

  _getAllQueries(List<MapEntry> queries, String queryOperator){
    List<MapEntry> queriesToReturn = List();
    for (var query in queries){
      queriesToReturn.add(_buildQueryWithColumnValueAndOperator(query, queryOperator));
    }
    return queriesToReturn;
  }

  _buildQueryWithColumnValueAndOperator(MapEntry columnAndValue, String queryOperator) {

    var queryString = "\"${columnAndValue.key}\":";

    var queryOperatorAndValueMap = Map();
    queryOperatorAndValueMap[queryOperator] = columnAndValue.value;

    var formattedQueryOperatorAndValue = JsonEncoder().convert(queryOperatorAndValueMap);
    queryString += "$formattedQueryOperatorAndValue";

    return MapEntry(columnAndValue.key, queryString);
  }

  _runThroughQueryParams(List<MapEntry> list) {
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

    mapToReturn["wasField"] = params;

    return JsonEncoder().convert(mapToReturn);
  }
  _runThroughQueryParamsWithSearchTerms(List<dynamic> list, String queryParam, String fieldName) {
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

  _checkForMultipleColumnInstances(List<MapEntry> queries) {
    List<MapEntry> sanitisedQueries = List();
    List<String> keysAlreadyCompacted = List();

    // Run through each query
    for (var query in queries){

      // Check if query with same column name has been sanitised
      if (!keysAlreadyCompacted.contains(query.key)) {

        // If not, check that it now has
        keysAlreadyCompacted.add(query.key);

        // Build a list of all queries with the same column name
        var listOfQueriesCompact = queries.where((i) => query.key == i.key).toList();

        // Build first part of query
        var queryStart = "\"${query.key}\":";
        var queryEnd = "";

        // Compact all the queries in the correct format
        for (var queryToCompact in listOfQueriesCompact) {

          var queryToCompactValue = queryToCompact.value.toString();
          queryToCompactValue = queryToCompactValue.replaceFirst("{", "");
          queryToCompactValue = queryToCompactValue.replaceAll("}", "");

          if (listOfQueriesCompact.first == queryToCompact){
            queryEnd += (queryToCompactValue.replaceAll(queryStart, " "));
          } else {
            queryEnd += (queryToCompactValue.replaceAll(queryStart, ", "));
          }
        }

        sanitisedQueries.add(MapEntry(query.key, queryStart += "{$queryEnd}"));
      }
    }

    return sanitisedQueries;
  }
}
