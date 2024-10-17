part of '../../parse_server_sdk.dart';

/// Class to create complex queries
class QueryBuilder<T extends ParseObject> {
  /// Class to create complex queries
  QueryBuilder(this.object) : super();

  factory QueryBuilder.name(String classname) {
    return QueryBuilder(ParseCoreData.instance.createObject(classname) as T);
  }

  QueryBuilder.or(this.object, List<QueryBuilder<T>> list) {
    _constructorInitializer(query: '"\$or":[', list: list);
  }

  QueryBuilder.and(this.object, List<QueryBuilder<T>> list) {
    _constructorInitializer(query: '"\$and":[', list: list);
  }

  QueryBuilder.nor(this.object, List<QueryBuilder<T>> list) {
    _constructorInitializer(query: '"\$nor":[', list: list);
  }

  void _constructorInitializer(
      {required String query, required List<QueryBuilder<T>> list}) {
    for (int i = 0; i < list.length; ++i) {
      if (i > 0) {
        query += ',';
      }
      query += '{${list[i].buildQueries(list[i].queries)}}';
    }
    query += ']';
    queries.add(MapEntry<String, dynamic>(_noOperatorNeeded, query));
  }

  factory QueryBuilder.copy(QueryBuilder<T> query) {
    QueryBuilder<T> copy = QueryBuilder(query.object);
    copy.queries = query.queries
        .map((MapEntry<String, dynamic> entry) =>
            MapEntry<String, dynamic>(entry.key, entry.value.toString()))
        .toList();
    query.limiters.forEach((String key, dynamic value) =>
        copy.limiters.putIfAbsent(key, () => value.toString()));
    return copy;
  }

  static const String _noOperatorNeeded = 'NO_OP';
  static const String _singleQuery = 'SINGLE_QUERY';

  T object;
  List<MapEntry<String, dynamic>> queries = <MapEntry<String, dynamic>>[];
  final Map<String, dynamic> limiters = <String, dynamic>{};
  final Map<String, dynamic> extraOptions = <String, dynamic>{};

  /// Used by ParseRelation getQuery()
  void setRedirectClassNameForKey(String key) {
    extraOptions['redirectClassNameForKey'] = key;
  }

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
      limiters['order'] = '${limiters['order']},$order';
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

  ///Exclude specific fields from the returned query
  ///
  /// [String] keys not will return the columns of a result you want the data for
  void excludeKeys(List<String> keys) {
    limiters['excludeKeys'] = concatenateArray(keys);
  }

  /// Includes other ParseObjects stored as a Pointer
  void includeObject(List<String> objectTypes) {
    limiters['include'] = concatenateArray(objectTypes);
  }

  /// Add a constraint for finding objects where the String value in [column]
  /// starts with [prefix]
  void whereStartsWith(
    String column,
    String prefix, {
    bool caseSensitive = false,
  }) {
    prefix = Uri.encodeComponent(prefix);

    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _singleQuery, '"$column":{"\$regex": "^$prefix"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(
          _singleQuery, '"$column":{"\$regex": "^$prefix", "\$options": "i"}'));
    }
  }

  /// Add a constraint for finding objects where the String value in [column]
  /// ends with [prefix]
  void whereEndsWith(
    String column,
    String prefix, {
    bool caseSensitive = false,
  }) {
    prefix = Uri.encodeComponent(prefix);

    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _singleQuery, '"$column":{"\$regex": "$prefix\$"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(_singleQuery,
          '"$column":{"\$regex": "$prefix\$", "\$options": "i"}'));
    }
  }

  /// Add a constraint to the query that requires a particular [column]'s value
  /// to be equal to the provided [value]
  void whereEqualTo(String column, dynamic value) {
    if (value is String) {
      value = Uri.encodeComponent(value);
    }

    queries.add(_buildQueryWithColumnValueAndOperator(
        MapEntry<String, dynamic>(column, value), _noOperatorNeeded));
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

  /// Add a constraint to the query that requires a particular [column]'s value
  /// to be not equal to the provided [value]
  void whereNotEqualTo(String column, dynamic value) {
    if (value is String) {
      value = Uri.encodeComponent(value);
    }

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
    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"\$relatedTo":{"object":{"__type":"Pointer","className":"$className","objectId":"$objectId"},"key":"$column"}'));
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

  /// Add a constraint for finding String values that contain the provided
  /// [substring]
  void whereContains(
    String column,
    String substring, {
    bool caseSensitive = false,
  }) {
    substring = Uri.encodeComponent(substring);

    if (caseSensitive) {
      queries.add(MapEntry<String, dynamic>(
          _singleQuery, '"$column":{"\$regex": "$substring"}'));
    } else {
      queries.add(MapEntry<String, dynamic>(_singleQuery,
          '"$column":{"\$regex": "$substring", "\$options": "i"}'));
    }
  }

  /// Powerful search for containing whole words. This search is much quicker
  /// than regex and can search for whole words including whether they are case
  /// sensitive or not. This search can also order by the score of the search
  void whereContainsWholeWord(
    String column,
    String searchTerm, {
    bool caseSensitive = false,
    bool orderByScore = true,
    bool diacriticSensitive = false,
  }) {
    searchTerm = Uri.encodeComponent(searchTerm);

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$text":{"\$search":{"\$term": "$searchTerm", "\$caseSensitive": $caseSensitive , "\$diacriticSensitive": $diacriticSensitive }}}'));
    if (orderByScore) {
      orderByAscending('\$score');
      keysToReturn(['\$score']);
    }
  }

  /// Returns an objects with key point values near the point given
  void whereNear(String column, ParseGeoPoint point) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;
    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$nearSphere":{"__type":"GeoPoint","latitude":$latitude,"longitude":$longitude}}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinMiles(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$nearSphere":{"__type":"GeoPoint","latitude":$latitude,"longitude":$longitude},"\$maxDistanceInMiles":$maxDistance}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinKilometers(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$nearSphere":{"__type":"GeoPoint","latitude":$latitude,"longitude":$longitude},"\$maxDistanceInKilometers":$maxDistance}'));
  }

  /// Returns an object with key point values near the point given and within the maximum distance given.
  void whereWithinRadians(
      String column, ParseGeoPoint point, double maxDistance) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$nearSphere":{"__type":"GeoPoint","latitude":$latitude,"longitude":$longitude},"\$maxDistanceInRadians":$maxDistance}'));
  }

  /// Returns an object with key point values contained within a given rectangular geographic bounding box.
  void whereWithinGeoBox(
      String column, ParseGeoPoint southwest, ParseGeoPoint northeast) {
    final double latitudeS = southwest.latitude;
    final double longitudeS = southwest.longitude;

    final double latitudeN = northeast.latitude;
    final double longitudeN = northeast.longitude;

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$within":{"\$box": [{"__type": "GeoPoint","latitude":$latitudeS,"longitude":$longitudeS},{"__type": "GeoPoint","latitude":$latitudeN,"longitude":$longitudeN}]}}'));
  }

  /// Return an object with key coordinates be contained within and on the bounds of a given polygon.
  /// Supports closed and open (last point is connected to first) paths
  /// Polygon must have at least 3 points
  void whereWithinPolygon(String column, List<ParseGeoPoint> points) {
    if (points.length < 3) {
      throw ArgumentError('Polygon must have at least 3 points');
    }
    Map<String, dynamic> dictionary = <String, dynamic>{};
    dictionary['\$polygon'] = points.map((e) => e.toJson()).toList();

    queries.add(MapEntry<String, dynamic>(
        _singleQuery, '"$column":{"\$geoWithin":${jsonEncode(dictionary)}}'));
  }

  /// Add a constraint to the query that requires a particular key's coordinates that contains a point
  void wherePolygonContains(String column, ParseGeoPoint point) {
    final double latitude = point.latitude;
    final double longitude = point.longitude;

    queries.add(MapEntry<String, dynamic>(_singleQuery,
        '"$column":{"\$geoIntersects":{"\$point":{"__type":"GeoPoint","latitude":$latitude,"longitude":$longitude}}}'));
  }

  /// Add a constraint to the query that requires a particular key's value match another QueryBuilder
  void whereMatchesQuery<E extends ParseObject>(
      String column, QueryBuilder<E> query) {
    final String inQuery =
        query._buildQueryRelational(query.object.parseClassName);

    queries.add(MapEntry<String, dynamic>(
        _singleQuery, '"$column":{"\$inQuery":$inQuery}'));
  }

  ///Add a constraint to the query that requires a particular key's value does not match another QueryBuilder
  void whereDoesNotMatchQuery<E extends ParseObject>(
      String column, QueryBuilder<E> query) {
    final String inQuery =
        query._buildQueryRelational(query.object.parseClassName);

    queries.add(MapEntry<String, dynamic>(
        _singleQuery, '"$column":{"\$notInQuery":$inQuery}'));
  }

  /// Add a constraint to the query that requires a particular key's value matches a value for a key in the results of another ParseQuery.
  void whereMatchesKeyInQuery<E extends ParseObject>(
      String column, String keyInQuery, QueryBuilder<E> query) {
    if (query.queries.isEmpty) {
      throw ArgumentError('query conditions is required');
    }
    if (limiters.containsKey('order')) {
      throw ArgumentError('order is not allowed');
    }
    if (limiters.containsKey('include')) {
      throw ArgumentError('include is not allowed');
    }

    final String inQuery =
        query._buildQueryRelationalKey(query.object.parseClassName, keyInQuery);

    queries.add(MapEntry<String, dynamic>(
        _singleQuery, '"$column":{"\$select":$inQuery}'));
  }

  /// Add a constraint to the query that requires a particular key's value does not match any value for a key in the results of another ParseQuery
  void whereDoesNotMatchKeyInQuery<E extends ParseObject>(
      String column, String keyInQuery, QueryBuilder<E> query) {
    if (query.queries.isEmpty) {
      throw ArgumentError('query conditions is required');
    }
    if (limiters.containsKey('order')) {
      throw ArgumentError('order is not allowed');
    }
    if (limiters.containsKey('include')) {
      throw ArgumentError('include is not allowed');
    }

    final String inQuery =
        query._buildQueryRelationalKey(query.object.parseClassName, keyInQuery);

    queries.add(MapEntry<String, dynamic>(
        _singleQuery, '"$column":{"\$dontSelect":$inQuery}'));
  }

  /// Finishes the query and calls the server
  ///
  /// Make sure to call this after defining your queries
  Future<ParseResponse> query<U extends ParseObject>(
      {ProgressCallback? progressCallback}) async {
    return object.query<U>(
      buildQuery(),
      progressCallback: progressCallback,
    );
  }

  Future<ParseResponse> distinct<U extends ParseObject>(
      String className) async {
    final String queryString = 'distinct=$className';
    return object.distinct<U>(queryString);
  }

  ///Counts the number of objects that match this query
  Future<ParseResponse> count() async {
    return object.query(_buildQueryCount());
  }

  /// Builds the query for Parse
  String buildQuery() {
    queries = _checkForMultipleColumnInstances(queries);
    return 'where={${buildQueries(queries)}}${getLimiters(limiters)}${getExtraOptions(extraOptions)}';
  }

  /// Builds the query relational for Parse
  String _buildQueryRelational(String className) {
    queries = _checkForMultipleColumnInstances(queries);
    String lim = getLimitersRelational(limiters);
    return '{"where":{${buildQueries(queries)}},"className":"$className"${limiters.isNotEmpty ? ',"$lim"' : ''}}';
  }

  /// Builds the query relational with Key for Parse
  String _buildQueryRelationalKey(String className, String keyInQuery) {
    queries = _checkForMultipleColumnInstances(queries);
    return '{"query":{"className":"$className","where":{${buildQueries(queries)}}},"key":"$keyInQuery"}';
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

  /// Creates a query param using the column, the value and the queryOperator
  /// that the column and value are being queried against
  MapEntry<String, dynamic> _buildQueryWithColumnValueAndOperator(
      MapEntry<String, dynamic> columnAndValue, String queryOperator) {
    final String key = columnAndValue.key;
    final dynamic value =
        convertValueToCorrectType(parseEncode(columnAndValue.value));

    if (queryOperator == _noOperatorNeeded) {
      return MapEntry<String, dynamic>(
          _noOperatorNeeded, '"$key": ${jsonEncode(value)}');
    } else {
      String queryString = '"$key":';
      final Map<String, dynamic> queryOperatorAndValueMap = <String, dynamic>{};
      queryOperatorAndValueMap[queryOperator] = parseEncode(value);
      final String formattedQueryOperatorAndValue =
          jsonEncode(queryOperatorAndValueMap);
      queryString += formattedQueryOperatorAndValue;
      return MapEntry<String, dynamic>(key, queryString);
    }
  }

  /// This joins queries that should be joined together... e.g. age > 10 &&
  /// age < 20, this would be similar to age > 10 < 20
  List<MapEntry<String, dynamic>> _checkForMultipleColumnInstances(
      List<MapEntry<String, dynamic>> queries) {
    final List<MapEntry<String, dynamic>> sanitizedQueries =
        <MapEntry<String, dynamic>>[];
    final List<String> keysAlreadyCompacted = <String>[];

    // Run through each query
    for (final MapEntry<String, dynamic> query in queries) {
      // Add queries that don't need sanitizing
      if (query.key == _noOperatorNeeded || query.key == _singleQuery) {
        sanitizedQueries
            .add(MapEntry<String, dynamic>(_noOperatorNeeded, query.value));
      }

      // Check if query with same column name has been sanitized
      if (!keysAlreadyCompacted.contains(query.key) &&
          query.key != _noOperatorNeeded &&
          query.key != _singleQuery) {
        // If not, check that it now has
        keysAlreadyCompacted.add(query.key);

        // Build a list of all queries with the same column name
        final List<MapEntry<String, dynamic>> listOfQueriesCompact = queries
            .where((MapEntry<String, dynamic> entry) => query.key == entry.key)
            .toList();

        // Build first part of query
        String queryStart = '"${query.key}":';
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
      result = '$result&$key=$value';
    });
    return result;
  }

  /// Adds extra options to the query
  String getExtraOptions(Map<String, dynamic> map) {
    String result = '';
    map.forEach((String key, dynamic value) {
      result = '$result&$key=$value';
    });
    return result;
  }

  /// Adds the limiters to the query relational, i.e. skip=10, limit=10
  String getLimitersRelational(Map<String, dynamic> map) {
    String result = '';
    map.forEach((String key, dynamic value) {
      if (result.isNotEmpty) {
        result = '$result,"$key":$value';
      } else {
        result = '"$key":$value';
      }
    });
    return result;
  }

  /// Find the first object that satisfies the query.
  /// Returns null, if no object is found.
  Future<T?> first() async {
    ParseResponse parseResponse =
        await (QueryBuilder.copy(this)..setLimit(1)).query();
    if (parseResponse.success) {
      return parseResponse.results?.first;
    }
    throw parseResponse.error ?? ParseError();
  }

  /// Find the objects that satisfy the query.
  /// Returns an empty list if no objects are found.
  Future<List<T>> find() async {
    ParseResponse parseResponse = await query();
    if (parseResponse.success) {
      return parseResponse.results?.map((e) => e as T).toList() ?? <T>[];
    }
    throw parseResponse.error ?? ParseError();
  }
}
