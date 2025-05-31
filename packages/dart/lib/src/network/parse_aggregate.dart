part of '../../parse_server_sdk.dart';

/// A class that allows aggregation queries on a Parse Server class using a pipeline.
///
/// Example usage:
/// ```dart
/// final aggregate = ParseAggregate('GameScore', pipeline: {
///   '\$group': {
///     '_id': '\$userId',
///     'totalScore': {'\$sum': '\$score'}
///   }
/// });
/// final response = await aggregate.execute();
/// ```
class ParseAggregate {
  /// The name of the Parse class to perform the aggregation on.
  final String className;

  /// The aggregation pipeline operations.
  ///
  /// Each operation should follow MongoDB-like syntax.
  /// Example:
  /// ```dart
  /// {
  ///   '\$group': {
  ///     '_id': '\$userId',
  ///     'totalScore': {'\$sum': '\$score'}
  ///   }
  /// }
  /// ```
  Map<String, dynamic> pipeline;

  /// Whether to enable debug mode for this request.
  final bool? debug;

  /// The custom ParseClient to use for the request (optional).
  final ParseClient? client;

  /// If true, includes the session ID automatically in the request (optional).
  final bool? autoSendSessionId;

  /// Optional override for the Parse class name used in response handling.
  final String? parseClassName;

  /// Creates a new [ParseAggregate] instance to perform aggregation queries.
  ///
  /// [className] is required and specifies the target Parse class.
  /// [pipeline] must contain at least one aggregation operation.
  ParseAggregate(
    this.className, {
    required this.pipeline,
    this.debug,
    this.client,
    this.autoSendSessionId,
    this.parseClassName,
  });

  /// Executes the aggregation query using the configured pipeline.
  ///
  /// Returns a [ParseResponse] containing the results of the aggregation.
  /// Throws [ArgumentError] if the pipeline is empty.
  Future<ParseResponse> execute() async {
    Map<String, String> _pipeline = {};

    if (pipeline.isEmpty) {
      throw ArgumentError(
        'pipeline must not be empty. Please add pipeline operations to aggregate data. '
        'Example: {"\$group": {"_id": "\$userId", "totalScore": {"\$sum": "\$score"}}}',
      );
    } else {
      _pipeline.addAll({
        'pipeline': jsonEncode(pipeline.entries.map((e) => {e.key: e.value}).toList())
      });
    }

    final debugBool = isDebugEnabled(objectLevelDebug: debug);
    final result = await ParseObject(className)._client.get(
          Uri.parse('${ParseCoreData().serverUrl}$keyEndPointAggregate$className').replace(
            queryParameters: {'pipeline': jsonEncode(pipeline.entries.map((e) => {e.key: e.value}).toList())}
          ).toString(),
        );


    return handleResponse<ParseObject>(
      ParseObject(className),
      result,
      ParseApiRQ.get,
      debugBool,
      parseClassName ?? 'ParseBase',
    );
  }
}
