part of '../../parse_server_sdk.dart';

/// A standardized response object returned by all Parse Server operations.
///
/// This class wraps the response received from the Parse Server and normalizes
/// the structure so that your Dart application can easily determine:
/// - whether the request was successful
/// - the HTTP status code
/// - the result(s) returned by the server
/// - any error information
///
///
/// ## Example usage
/// ```dart
/// final response = await myParseQuery.find();
/// if (response.success) {
///   print('Fetched ${response.count} objects.');
///   for (final obj in response.results ?? []) {
///     print(obj);
///   }
/// } else {
///   print('Error: ${response.error?.message}');
/// }
/// ```
class ParseResponse {
  /// Creates a new [ParseResponse] instance.
  ///
  /// You typically don't instantiate this directly — it's created by
  /// internal SDK logic, e.g. through [fromParseNetworkResponse].
  ParseResponse({
    this.error,
  });

  /// Whether the request was successful.
  ///
  /// This is `true` if the HTTP status code was 200 or 201.
  bool success = false;

  /// The HTTP status code returned by the Parse Server.
  ///
  /// Defaults to -1 if not yet populated.
  int statusCode = -1;

  /// The direct result from the Parse Server.
  ///
  /// This might be a `Map`, a `List`, or any other decoded JSON.
  ///
  /// ---
  /// ⚠️ **Deprecated:**
  /// You should prefer using [results], which is guaranteed to be a list of results.
  dynamic result;

  /// The list of results returned by the Parse Server.
  ///
  /// Even if only one object is returned, it will still be inside a list.
  ///
  /// This is the recommended way to access your fetched data.
  List? results;

  /// The number of objects returned (i.e. `results.length`).
  ///
  /// Will be 0 if there were no results.
  int count = 0;

  /// If the request failed, this contains error information.
  ParseError? error;

  /// Builds a [ParseResponse] from a [ParseNetworkResponse],
  /// typically after making an HTTP request.
  ///
  /// - Decodes JSON data
  /// - Determines `success` based on HTTP status codes
  /// - Populates [results] and [count] if the response contains a list
  factory ParseResponse.fromParseNetworkResponse(ParseNetworkResponse response) {
    final ParseResponse result = ParseResponse();
    result.statusCode = response.statusCode;
    result.success = response.statusCode >= 200 && response.statusCode < 300;
    try {
      // Attempt to decode JSON data
      final data = jsonDecode(response.data);
      // Fallback if `result` was not already populated
      result.result ??= data;
      // Handle typical Parse Server response structures
      if (data is Map<String, dynamic>) {
        if (data.containsKey('results')) {
          final resultList = data['results'];
          if (resultList is List) {
            result.results = resultList;
            result.count = resultList.length;
          }
        }else if(data.containsKey('error')){
          result.error=ParseError(code:response.statusCode, message:data['error'].toString() );
        }
      } else if (data is List) {
        result.results = data;
        result.count = data.length;
      }
      result.results ??= [data];
    } catch (e,s) {
      result.error = ParseError(message: e.toString(),exception: Exception(s));
    }
    return result;
  }
  Map<String,dynamic> get toMap=>{
    'success': success,
    'statusCode': statusCode,
    // 'result': result,
    'results': results,
    'count': count,
    'error': error,
  };

  @override
  String toString() {
    return toMap.toString();
  }
}
