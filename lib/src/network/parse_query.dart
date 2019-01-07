part of flutter_parse_sdk;

/// Class to create complex queries
class QueryBuilder<T extends ParseObject> {

  static const String _NO_OPERATOR_NEEDED = "NO_OP";

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
  int _limit = 0;
  int _skip = 0;
  dynamic _where;
  dynamic _order;
  dynamic _keys;
  dynamic _include;

  /// Class to create complex queries
  QueryBuilder(this.object) : super();

  /// Adds a limit to amount of results return from Parse
  void limit(int limit){
    _limit = limit;
  }

  /// Useful for pagination, skips [int] amount of results
  void skip(int skip){
    _skip = skip;
  }

  /// Creates a query based on where
  void where(String where){
    _where = where;
  }

  /// Orders the results ascedingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void ascending(String order){
    _order = order;
  }

  /// Orders the results descendingly.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void descending(String order){
    _order = "-$order";
  }

  /// Define which keys in an object to return.
  ///
  /// [String] keys will only return the columns of a result you want the data for,
  /// this is useful for large objects
  void keys(String keys){
    _keys = keys;
  }

  /// Includes other ParseObjects stored as a Pointer
  void include(String include){
    _include = include;
  }

  /// Returns an object where the [String] column starts with [value]
  void startsWith(String key, dynamic value) {
    _regExQueries.add(MapEntry(key, "^$value"));
  }

  /// Returns an object where the [String] column ends with [value]
  void endsWith(String key, dynamic value) {
    _regExQueries.add(MapEntry(key, "$value^"));
  }

  /// Returns an object where the [String] column equals [value]
  void equals(String column, dynamic value) {
    _equalsQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains a value less than
  /// value
  void lessThan(String column, dynamic value) {
    _lessThanQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains a value less or equal
  /// to than value
  void lessThanOrEqualTo(String column, dynamic value) {
    _lessThanOrEqualToQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than value
  void greaterThan(String column, dynamic value) {
    _greaterThanQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than equal to value
  void greaterThanOrEqualsTo(String column, dynamic value) {
    _greaterThanOrEqualToQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column is not equal to value
  void notEqualTo(String column, dynamic value) {
    _notEqualToQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains value
  void contains(String column, dynamic value) {
    _containsQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column is containedIn
  void containedIn(String column, dynamic value) {
    _containedInQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column is exists
  void exists(String column, dynamic value) {
    _existsQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains select
  void select(String column, dynamic value) {
    _selectQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column doesn't select
  void dontSelect(String column, dynamic value) {
    _dontSelectQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains all
  void all(String column, dynamic value) {
    _allQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column has a regEx performed on,
  /// this can include ^StringsWith, or ^EndsWith
  void regEx(String column, dynamic value) {
    _regExQueries.add(MapEntry(column, value));
  }

  /// Returns an object where the [String] column contains the text
  void text(String column, dynamic value) {
    _textQueries.add(MapEntry(column, value));
  }

  /// Finishes the query and calls the server
  ///
  /// Make sure to call this after defining your queries
  query() async {
    return object.query(_buildQuery());
  }

  /// Builds the query for Parse
  String _buildQuery() {
    var queries = List<MapEntry>();

    // START QUERY
    const String QUERY_START = "where={";
    const String QUERY_END = "}";

    var query = QUERY_START;

    // ADD PARAM TO MAP
    //Needs fixing
    if (_containsQueries.length != 0) queries.addAll(_getAllQueries(_containsQueries, "\$term"));

    // Works
    if (_equalsQueries.length != 0) queries.addAll(_getAllQueries(_equalsQueries, _NO_OPERATOR_NEEDED));
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

    query += QUERY_END;

    // ADD PARAMS
    Map limiters = Map();
    if (_where != null) limiters['where'] = _where;
    if (_order != null) limiters["order"] = _order;
    if (_limit != 0) limiters["limit"] = _limit;
    if (_skip != 0) limiters["skip"] = _skip;
    if (_keys != null) limiters["keys"] = _keys;
    if (_include != null) limiters["include"] = _include;
    query += getLimiters(limiters);

    // -- TEST
    print("QUERY: $query");

    return "$query";
  }

  /// Runs through all queries in each list
  _getAllQueries(List<MapEntry> queries, String queryOperator){
    List<MapEntry> queriesToReturn = List();
    for (var query in queries){
      queriesToReturn.add(_buildQueryWithColumnValueAndOperator(query, queryOperator));
    }
    return queriesToReturn;
  }

  /// Creates a query param using the column, the value and the queryOperator
  /// that the column and value are being queried against
  _buildQueryWithColumnValueAndOperator(MapEntry columnAndValue, String queryOperator) {

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
  _checkForMultipleColumnInstances(List<MapEntry> queries) {
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
  getLimiters(Map map) {
    String result;
    map.forEach((key, value) {
      result = (result != null) ? result + "&$key=$value" : "&$key=$value";
    });
    return result;
  }

  /// Converts the object to the correct value for JSON,
  ///
  /// Strings are wrapped with "" but ints and others are not
  convertValueToCorrectType(dynamic value) {
    if (value is num) return value;
    if (value is String) return "\"$value\"";
  }
}
