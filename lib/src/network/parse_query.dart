part of flutter_parse_sdk;

/// Class to create complex queries
class QueryBuilder<T extends ParseObject> {

  static const String _NO_OPERATOR_NEEDED = "NO_OP";

  T object;
  var queries = List<MapEntry>();
  var limiters = Map();

  /// Class to create complex queries
  QueryBuilder(this.object) : super();

  /// Adds a limit to amount of results return from Parse
  void limit(int limit){
    limiters["limit"] = limit;
  }

  /// Useful for pagination, skips [int] amount of results
  void skip(int skip){
    limiters["skip"] = skip;
  }

  /// Creates a query based on where
  void where(String where){
    limiters['where'] = where;
  }

  /// Orders the results ascedingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void ascending(String order){
    limiters["order"] = order;
  }

  /// Orders the results descendingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void descending(String order){
    limiters["order"] = "-$order";
  }

  /// Define which keys in an object to return.
  ///
  /// [String] keys will only return the columns of a result you want the data for,
  /// this is useful for large objects
  void keys(String keys){
    limiters["keys"] = keys;
  }

  /// Includes other ParseObjects stored as a Pointer
  void include(String include){
    limiters["include"] = include;
  }

  /// Returns an object where the [String] column starts with [value]
  void startsWith(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, "^$value"), "\$regex"));
  }

  /// Returns an object where the [String] column ends with [value]
  void endsWith(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, "$value^"), "\$regex"));
  }

  /// Returns an object where the [String] column equals [value]
  void equals(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), _NO_OPERATOR_NEEDED));
  }

  /// Returns an object where the [String] column contains a value less than
  /// value
  void lessThan(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$lt"));
  }

  /// Returns an object where the [String] column contains a value less or equal
  /// to than value
  void lessThanOrEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$lte"));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than value
  void greaterThan(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$gt"));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than equal to value
  void greaterThanOrEqualsTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$gte"));
  }

  /// Returns an object where the [String] column is not equal to value
  void notEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$ne"));
  }

  /// Returns an object where the [String] column contains value
  void contains(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$term"));
  }

  /// Returns an object where the [String] column is containedIn
  void containedIn(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$in"));
  }

  /// Returns an object where the [String] column is notContainedIn
  void notContainedIn(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$nin"));
  }

  /// Returns an object where the [String] column is exists
  void exists(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$exists"));
  }

  /// Returns an object where the [String] column contains select
  void select(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$select"));
  }

  /// Returns an object where the [String] column doesn't select
  void dontSelect(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$dontSelect"));
  }

  /// Returns an object where the [String] column contains all
  void all(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$all"));
  }

  /// Returns an object where the [String] column has a regEx performed on,
  /// this can include ^StringsWith, or ^EndsWith
  void regEx(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$regex"));
  }

  /// Returns an object where the [String] column contains the text
  void text(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$text"));
  }

  /// Finishes the query and calls the server
  ///
  /// Make sure to call this after defining your queries
  Future<ParseResponse> query() async {
    return object.query(_buildQuery());
  }

  /// Builds the query for Parse
  String _buildQuery() {
    queries = _checkForMultipleColumnInstances(queries);
    var query = "where={${buildQueries(queries)}}${getLimiters(limiters)}";
    return "$query";
  }

  /// Runs through all queries and adds them to a query string
  String buildQueries(List<MapEntry> queries) {

    String queryBuilder = "";

    for (var item in queries) {
      if (item == queries.first) {
        queryBuilder += item.value;
      } else {
        queryBuilder += ",${item.value}";
      }
    }

    return queryBuilder;
  }

  /// Creates a query param using the column, the value and the queryOperator
  /// that the column and value are being queried against
  MapEntry _buildQueryWithColumnValueAndOperator(MapEntry columnAndValue, String queryOperator) {

    var key = columnAndValue.key;
    var value = convertValueToCorrectType(columnAndValue.value);

    if (queryOperator == _NO_OPERATOR_NEEDED){
      return MapEntry(_NO_OPERATOR_NEEDED, "\"${columnAndValue.key}\": $value");
    } else {
      var queryString = "\"$key\":";

      var queryOperatorAndValueMap = Map();
      queryOperatorAndValueMap[queryOperator] = columnAndValue.value;

      var formattedQueryOperatorAndValue = JsonEncoder().convert(queryOperatorAndValueMap);
      queryString += "$formattedQueryOperatorAndValue";

      return MapEntry(key, queryString);
    }
  }

  /// This joins queries that should be joined together... e.g. age > 10 &&
  /// age < 20, this would be similar to age > 10 < 20
  List _checkForMultipleColumnInstances(List<MapEntry> queries) {
    List<MapEntry> sanitisedQueries = List();
    List<String> keysAlreadyCompacted = List();

    // Run through each query
    for (var query in queries){

      // Add queries that don't need sanitising
      if (query.key == _NO_OPERATOR_NEEDED) {
        sanitisedQueries.add(MapEntry(_NO_OPERATOR_NEEDED, query.value));
      }

      // Check if query with same column name has been sanitised
      if (!keysAlreadyCompacted.contains(query.key) && query.key != _NO_OPERATOR_NEEDED) {

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

  /// Adds the limiters to the query, i.e. skip=10, limit=10
  String getLimiters(Map map) {
    String result = "";
    map.forEach((key, value) {
      result = (result != null) ? result + "&$key=$value" : "&$key=$value";
    });
    return result;
  }

  /// Converts the object to the correct value for JSON,
  ///
  /// Strings are wrapped with "" but ints and others are not
  convertValueToCorrectType(dynamic value) {
    if (value is String) {
      return "\"$value\"";
    } else {
      return value;
    }
  }
}
