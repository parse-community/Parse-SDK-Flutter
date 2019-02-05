part of flutter_parse_sdk;

/// Class to create complex queries
class QueryBuilder<T extends ParseObject> {
  static const String _NO_OPERATOR_NEEDED = "NO_OP";
  static const String _SINGLE_QUERY = "SINGLE_QUERY";

  T object;
  var queries = List<MapEntry>();
  var limiters = Map();

  /// Class to create complex queries
  QueryBuilder(this.object) : super();

  /// Adds a limit to amount of results return from Parse
  void setLimit(int limit) {
    limiters["limit"] = limit;
  }

  /// Useful for pagination, skips [int] amount of results
  void setAmountToSkip(int skip) {
    limiters["skip"] = skip;
  }

  /// Creates a query based on where
  void whereEquals(String where) {
    limiters['where'] = where;
  }

  /// Orders the results ascedingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void orderByAscending(String order) {
    limiters["order"] = order;
  }

  /// Orders the results descendingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void orderByDescending(String order) {
    limiters["order"] = "-$order";
  }

  /// Define which keys in an object to return.
  ///
  /// [String] keys will only return the columns of a result you want the data for,
  /// this is useful for large objects
  void keysToReturn(List<String> keys) {
    limiters["keys"] = concatArray(keys);
  }

  /// Includes other ParseObjects stored as a Pointer
  void includeObject(List<String> objectTypes) {
    limiters["include"] = concatArray(objectTypes);
  }

  /// Returns an object where the [String] column starts with [value]
  void whereStartsWith(String column, String query,
      {bool caseSensitive: false}) {
    if (caseSensitive) {
      queries.add(
          MapEntry(_SINGLE_QUERY, '\"$column\":{\"\$regex\": \"^$query\"}'));
    } else {
      queries.add(MapEntry(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"^$query\", \"\$options\": \"i\"}'));
    }
  }

  /// Returns an object where the [String] column ends with [value]
  void whereEndsWith(String column, String query, {bool caseSensitive: false}) {
    if (caseSensitive) {
      queries.add(
          MapEntry(_SINGLE_QUERY, '\"$column\":{\"\$regex\": \"$query^\"}'));
    } else {
      queries.add(MapEntry(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"$query^\", \"\$options\": \"i\"}'));
    }
  }

  /// Returns an object where the [String] column equals [value]
  void whereEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), _NO_OPERATOR_NEEDED));
  }

  /// Returns an object where the [String] column contains a value less than
  /// value
  void whereLessThan(String column, dynamic value) {
    queries.add(
        _buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$lt"));
  }

  /// Returns an object where the [String] column contains a value less or equal
  /// to than value
  void whereLessThanOrEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$lte"));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than value
  void whereGreaterThan(String column, dynamic value) {
    queries.add(
        _buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$gt"));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than equal to value
  void whereGreaterThanOrEqualsTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$gte"));
  }

  /// Returns an object where the [String] column is not equal to value
  void whereNotEqualTo(String column, dynamic value) {
    queries.add(
        _buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$ne"));
  }

  /// Returns an object where the [String] column is containedIn
  void whereContainedIn(String column, List value) {
    queries.add(
        _buildQueryWithColumnValueAndOperator(MapEntry(column, value), "\$in"));
  }

  /// Returns an object where the [String] column is notContainedIn
  void whereNotContainedIn(String column, List value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$nin"));
  }

  /// Returns an object where the [String] column for the object has data correctley entered/saved
  void whereValueExists(String column, bool value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$exists"));
  }

  /// Returns an object where the [String] column contains select
  void selectKeys(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$select"));
  }

  /// Returns an object where the [String] column doesn't select
  void dontSelectKeys(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$dontSelect"));
  }

  /// Returns an object where the [String] column contains all
  void whereArrayContainsAll(String column, List value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value.toString()), "\$all"));
  }

  /// Returns an object where the [String] column has a regEx performed on,
  /// this can include ^StringsWith, or ^EndsWith. This can be manipulated to the users desire
  void regEx(String column, String value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry(column, value), "\$regex"));
  }

  /// Performs a search to see if [String] contains other string
  void whereContains(String column, String value, {bool caseSensitive: false}) {
    if (caseSensitive) {
      queries.add(
          MapEntry(_SINGLE_QUERY, '\"$column\":{\"\$regex\": \"$value\"}'));
    } else {
      queries.add(MapEntry(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"$value\", \"\$options\": \"i\"}'));
    }
  }

  /// Powerful search for containing whole words. This search is much quicker than regex and can search for whole words including wether they are case sensitive or not.
  /// This search can also order by the score of the search
  void whereContainsWholeWord(String column, String query,
      {bool caseSensitive: false, bool orderByScore: true}) {
    queries.add(MapEntry(_SINGLE_QUERY,
        '\"$column\":{\"\$text\":{\"\$search\":{\"\$term\": \"$query\", \"\$caseSensitive\": $caseSensitive }}}'));
    if (orderByScore) orderByDescending('score');
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

  String concatArray(List<String> queries) {
    String queryBuilder = "";

    for (var item in queries) {
      if (item == queries.first) {
        queryBuilder += item;
      } else {
        queryBuilder += ",$item";
      }
    }

    return queryBuilder;
  }

  /// Creates a query param using the column, the value and the queryOperator
  /// that the column and value are being queried against
  MapEntry _buildQueryWithColumnValueAndOperator(
      MapEntry columnAndValue, String queryOperator) {
    var key = columnAndValue.key;

    var value = convertValueToCorrectType(columnAndValue.value);

    if (queryOperator == _NO_OPERATOR_NEEDED) {
      return MapEntry(_NO_OPERATOR_NEEDED, "\"${columnAndValue.key}\": $value");
    } else {
      var queryString = "\"$key\":";

      var queryOperatorAndValueMap = Map();
      queryOperatorAndValueMap[queryOperator] = columnAndValue.value;

      var formattedQueryOperatorAndValue =
          JsonEncoder().convert(queryOperatorAndValueMap);
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
    for (var query in queries) {
      // Add queries that don't need sanitising
      if (query.key == _NO_OPERATOR_NEEDED || query.key == _SINGLE_QUERY) {
        sanitisedQueries.add(MapEntry(_NO_OPERATOR_NEEDED, query.value));
      }

      // Check if query with same column name has been sanitised
      if (!keysAlreadyCompacted.contains(query.key) &&
          query.key != _NO_OPERATOR_NEEDED &&
          query.key != _SINGLE_QUERY) {
        // If not, check that it now has
        keysAlreadyCompacted.add(query.key);

        // Build a list of all queries with the same column name
        var listOfQueriesCompact =
            queries.where((i) => query.key == i.key).toList();

        // Build first part of query
        var queryStart = "\"${query.key}\":";
        var queryEnd = "";

        // Compact all the queries in the correct format
        for (var queryToCompact in listOfQueriesCompact) {
          var queryToCompactValue = queryToCompact.value.toString();
          queryToCompactValue = queryToCompactValue.replaceFirst("{", "");
          queryToCompactValue = queryToCompactValue.replaceAll("}", "");

          if (listOfQueriesCompact.first == queryToCompact) {
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
}
