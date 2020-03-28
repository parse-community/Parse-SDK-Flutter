part of flutter_parse_sdk;

/// Class to create complex queries
class QueryBuilder<T extends ParseObject> {
  /// Class to create complex queries
  QueryBuilder(this.object) : super();

  QueryBuilder.or(this.object, List<QueryBuilder<T>> list) {
    if (list != null) {
      String query = '"\$or":[';
      for (int i = 0; i < list.length; ++i) {
        if (i > 0) {
          query += ',';
        }
        query += '{' + list[i].buildQueries(list[i].queries) + '}';
      }
      query += ']';
      queries.add(MapEntry<String, dynamic>(_NO_OPERATOR_NEEDED, query));
    }
  }

  QueryBuilder.copy(QueryBuilder<T> query) {
    object = query.object;
    queries = query.queries
        .map((MapEntry<String, dynamic> entry) =>
            MapEntry<String, dynamic>(entry.key, entry.value.toString()))
        .toList();
    query.limiters.forEach((String key, dynamic value) =>
        limiters.putIfAbsent(key, () => value.toString()));
  }

  static const String _NO_OPERATOR_NEEDED = 'NO_OP';
  static const String _SINGLE_QUERY = 'SINGLE_QUERY';

  T object;
  List<MapEntry<String, dynamic>> queries = <MapEntry<String, dynamic>>[];
  final Map<String, dynamic> limiters = Map<String, dynamic>();

  /// Adds a limit to amount of results return from Parse
  void setLimit(int limit) {
    limiters['limit'] = limit;
  }

  /// Useful for pagination, skips [int] amount of results
  void setAmountToSkip(int skip) {
    limiters['skip'] = skip;
  }

  /// Creates a query based on where
  void whereEquals(String where) {
    limiters['where'] = where;
  }

  /// Sorts the results in ascending order.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void orderByAscending(String order) {
    if (!limiters.containsKey('order')) {
      limiters['order'] = order;
    } else {
      limiters['order'] = limiters['order'] + ',' + order;
    }
  }

  /// Sorts the results descending order.
  ///
  /// [String] order will be the column of the table that the results are
  /// ordered by
  void orderByDescending(String order) {
    if (!limiters.containsKey('order')) {
      limiters['order'] = '-$order';
    } else {
      limiters['order'] = limiters['order'] + ',' + '-$order';
    }
  }

  /// Define which keys in an object to return.
  ///
  /// [String] keys will only return the columns of a result you want the data for,
  /// this is useful for large objects
  void keysToReturn(List<String> keys) {
    limiters['keys'] = concatenateArray(keys);
  }

  /// Includes other ParseObjects stored as a Pointer
  void includeObject(List<String> objectTypes) {
    limiters['include'] = concatenateArray(objectTypes);
  }

  /// Returns an object where the [String] column starts with [value]
  void whereStartsWith(String column, String query,
      {bool caseSensitive = false}) {
    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _SINGLE_QUERY, '\"$column\":{\"\$regex\": \"^$query\"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"^$query\", \"\$options\": \"i\"}'));
    }
  }

  /// Returns an object where the [String] column ends with [value]
  void whereEndsWith(String column, String query,
      {bool caseSensitive = false}) {
    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _SINGLE_QUERY, '\"$column\":{\"\$regex\": \"$query^\"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"$query^\", \"\$options\": \"i\"}'));
    }
  }

  /// Returns an object where the [String] column equals [value]
  void whereEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), _NO_OPERATOR_NEEDED));
  }

  /// Returns an object where the [String] column contains a value less than
  /// value
  void whereLessThan(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$lt'));
  }

  /// Returns an object where the [String] column contains a value less or equal
  /// to than value
  void whereLessThanOrEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$lte'));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than value
  void whereGreaterThan(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$gt'));
  }

  /// Returns an object where the [String] column contains a value greater
  /// than equal to value
  void whereGreaterThanOrEqualsTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$gte'));
  }

  /// Returns an object where the [String] column is not equal to value
  void whereNotEqualTo(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$ne'));
  }

  /// Returns an object where the [String] column is containedIn
  void whereContainedIn(String column, List<dynamic> value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$in'));
  }

  /// Returns an object where the [String] column is notContainedIn
  void whereNotContainedIn(String column, List<dynamic> value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$nin'));
  }

  /// Returns an object where the [String] column for the object has data correctly entered/saved
  void whereValueExists(String column, bool value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$exists'));
  }

  /// Retrieves related objets where [String] column is a relation field to the class [String] className
  void whereRelatedTo(String column, String className, String objectId) {
    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"\$relatedTo\":{\"object\":{\"__type\":\"Pointer\",\"className\":\"$className\",\"objectId\":\"$objectId\"},\"key\":\"$column\"}'));
  }

  /// Returns an object where the [String] column contains select
  void selectKeys(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$select'));
  }

  /// Returns an object where the [String] column doesn't select
  void dontSelectKeys(String column, dynamic value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$dontSelect'));
  }

  /// Returns an object where the [String] column contains all
  void whereArrayContainsAll(String column, List<dynamic> value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$all'));
  }

  /// Returns an object where the [String] column has a regEx performed on,
  /// this can include ^StringsWith, or ^EndsWith. This can be manipulated to the users desire
  void regEx(String column, String value) {
    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), '\$regex'));
  }

  /// Performs a search to see if [String] contains other string
  void whereContains(String column, String value,
      {bool caseSensitive = false}) {
    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _SINGLE_QUERY, '\"$column\":{\"\$regex\": \"$value\"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
          '\"$column\":{\"\$regex\": \"$value\", \"\$options\": \"i\"}'));
    }
  }

  /// Powerful search for containing whole words. This search is much quicker than regex and can search for whole words including wether they are case sensitive or not.
  /// This search can also order by the score of the search
  void whereContainsWholeWord(String column, String query,
      {bool caseSensitive = false, bool orderByScore = true}) {
    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$text\":{\"\$search\":{\"\$term\": \"$query\", \"\$caseSensitive\": $caseSensitive }}}'));
    if (orderByScore) {
      orderByDescending('score');
    }
  }

  /// Returns an objects with key point values near the point given
  void whereNear(String column, ParseGeoPoint point) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;
    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$nearSphere\":{\"__type\":\"GeoPoint\",\"latitude\":$latitude,\"longitude\":$longitude}}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinMiles(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$nearSphere\":{\"__type\":\"GeoPoint\",\"latitude\":$latitude,\"longitude\":$longitude},\"\$maxDistanceInMiles\":$maxDistance}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinKilometers(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$nearSphere\":{\"__type\":\"GeoPoint\",\"latitude\":$latitude,\"longitude\":$longitude},\"\$maxDistanceInKilometers\":$maxDistance}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinRadians(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$nearSphere\":{\"__type\":\"GeoPoint\",\"latitude\":$latitude,\"longitude\":$longitude},\"\$maxDistanceInRadians\":$maxDistance}'));
  }

  /// Returns an object with key point values contained within a given rectangular geographic bounding box.
  void whereWithinGeoBox(
      String column, ParseGeoPoint southwest, ParseGeoPoint northeast) {
    final double latitudeS = southwest.latitude;
    final double longitudeS = southwest.longitude;

    final double latitudeN = northeast.latitude;
    final double longitudeN = northeast.longitude;

    queries.add(MapEntry<String, dynamic>(_SINGLE_QUERY,
        '\"$column\":{\"\$within\":{\"\$box\": [{\"__type\": \"GeoPoint\",\"latitude\":$latitudeS,\"longitude\":$longitudeS},{\"__type\": \"GeoPoint\",\"latitude\":$latitudeN,\"longitude\":$longitudeN}]}}'));
  }

  // Add a constraint to the query that requires a particular key's value match another QueryBuilder
  // ignore: always_specify_types
  void whereMatchesQuery(String column, QueryBuilder query) {
    final String inQuery =
        query._buildQueryRelational(query.object.parseClassName);

    queries.add(MapEntry<String, dynamic>(
        _SINGLE_QUERY, '\"$column\":{\"\$inQuery\":$inQuery}'));
  }

  //Add a constraint to the query that requires a particular key's value does not match another QueryBuilder
  // ignore: always_specify_types
  void whereDoesNotMatchQuery(String column, QueryBuilder query) {
    final String inQuery =
        query._buildQueryRelational(query.object.parseClassName);

    queries.add(MapEntry<String, dynamic>(
        _SINGLE_QUERY, '\"$column\":{\"\$notInQuery\":$inQuery}'));
  }

  /// Finishes the query and calls the server
  ///
  /// Make sure to call this after defining your queries
  Future<ParseResponse> query<T extends ParseObject>() async {
    return object.query<T>(buildQuery());
  }

  Future<ParseResponse> distinct<T extends ParseObject>(
      String className) async {
    final String queryString = 'distinct=$className';
    return object.distinct<T>(queryString);
  }

  ///Counts the number of objects that match this query
  Future<ParseResponse> count() async {
    return object.query(_buildQueryCount());
  }

  /// Builds the query for Parse
  String buildQuery() {
    queries = _checkForMultipleColumnInstances(queries);
    return 'where={${buildQueries(queries)}}${getLimiters(limiters)}';
  }

  /// Builds the query relational for Parse
  String _buildQueryRelational(String className) {
    queries = _checkForMultipleColumnInstances(queries);
    return '{\"where\":{${buildQueries(queries)}},\"className\":\"$className\"${getLimitersRelational(limiters)}}';
  }

  /// Builds the query for Parse
  String _buildQueryCount() {
    queries = _checkForMultipleColumnInstances(queries);
    return 'where={${buildQueries(queries)}}&count=1';
  }

  /// Runs through all queries and adds them to a query string
  String buildQueries(List<MapEntry<String, dynamic>> queries) {
    String queryBuilder = '';

    for (final MapEntry<String, dynamic> item in queries) {
      if (item == queries.first) {
        queryBuilder += item.value;
      } else {
        queryBuilder += ',${item.value}';
      }
    }

    return queryBuilder;
  }

  String concatenateArray(List<String> queries) {
    String queryBuilder = '';

    for (final String item in queries) {
      if (item == queries.first) {
        queryBuilder += item;
      } else {
        queryBuilder += ',$item';
      }
    }

    return queryBuilder;
  }

  /// Creates a query param using the column, the value and the queryOperator
  /// that the column and value are being queried against
  MapEntry<String, dynamic> _buildQueryWithColumnValueAndOperator(
      MapEntry<String, dynamic> columnAndValue, String queryOperator) {
    final String key = columnAndValue.key;
    final dynamic value =
        convertValueToCorrectType(parseEncode(columnAndValue.value));

    if (queryOperator == _NO_OPERATOR_NEEDED) {
      return MapEntry<String, dynamic>(
          _NO_OPERATOR_NEEDED, '\"$key\": ${jsonEncode(value)}');
    } else {
      String queryString = '\"$key\":';
      final Map<String, dynamic> queryOperatorAndValueMap =
          Map<String, dynamic>();
      queryOperatorAndValueMap[queryOperator] = parseEncode(value);
      final String formattedQueryOperatorAndValue =
          jsonEncode(queryOperatorAndValueMap);
      queryString += '$formattedQueryOperatorAndValue';
      return MapEntry<String, dynamic>(key, queryString);
    }
  }

  /// This joins queries that should be joined together... e.g. age > 10 &&
  /// age < 20, this would be similar to age > 10 < 20
  List<MapEntry<String, dynamic>> _checkForMultipleColumnInstances(
      List<MapEntry<String, dynamic>> queries) {
    final List<MapEntry<String, dynamic>> sanitizedQueries =
        List<MapEntry<String, dynamic>>();
    final List<String> keysAlreadyCompacted = List<String>();

    // Run through each query
    for (final MapEntry<String, dynamic> query in queries) {
      // Add queries that don't need sanitizing
      if (query.key == _NO_OPERATOR_NEEDED || query.key == _SINGLE_QUERY) {
        sanitizedQueries
            .add(MapEntry<String, dynamic>(_NO_OPERATOR_NEEDED, query.value));
      }

      // Check if query with same column name has been sanitized
      if (!keysAlreadyCompacted.contains(query.key) &&
          query.key != _NO_OPERATOR_NEEDED &&
          query.key != _SINGLE_QUERY) {
        // If not, check that it now has
        keysAlreadyCompacted.add(query.key);

        // Build a list of all queries with the same column name
        final List<MapEntry<String, dynamic>> listOfQueriesCompact = queries
            .where((MapEntry<String, dynamic> entry) => query.key == entry.key)
            .toList();

        // Build first part of query
        String queryStart = '\"${query.key}\":';
        String queryEnd = '';

        // Compact all the queries in the correct format
        for (MapEntry<String, dynamic> queryToCompact in listOfQueriesCompact) {
          String queryToCompactValue = queryToCompact.value.toString();
          queryToCompactValue = queryToCompactValue.replaceFirst('{', '');
          queryToCompactValue = queryToCompactValue.replaceRange(
              queryToCompactValue.length - 1, queryToCompactValue.length, '');
          if (listOfQueriesCompact.first == queryToCompact) {
            queryEnd += queryToCompactValue.replaceAll(queryStart, ' ');
          } else {
            queryEnd += queryToCompactValue.replaceAll(queryStart, ', ');
          }
        }

        sanitizedQueries.add(
            MapEntry<String, dynamic>(query.key, queryStart += '{$queryEnd}'));
      }
    }

    return sanitizedQueries;
  }

  /// Adds the limiters to the query, i.e. skip=10, limit=10
  String getLimiters(Map<String, dynamic> map) {
    String result = '';
    map.forEach((String key, dynamic value) {
      if (result != null) {
        result = result + '&$key=$value';
      } else {
        result = '&$key=$value';
      }
    });
    return result;
  }

  /// Adds the limiters to the query relational, i.e. skip=10, limit=10
  String getLimitersRelational(Map<String, dynamic> map) {
    String result = '';
    map.forEach((String key, dynamic value) {
      if (result != null) {
        result = result + ',\"$key":$value';
      } else {
        result = '\"$key\":$value';
      }
    });
    return result;
  }
}
