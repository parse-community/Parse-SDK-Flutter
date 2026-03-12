
part of '../../parse_server_sdk.dart';

class ParseAggregate extends ParseObject {

  ParseAggregate(
    this.functionName, {
    bool? debug,
    ParseClient? client,
    bool? autoSendSessionId,
  }) : super(
          functionName,
          client: client,
          autoSendSessionId: autoSendSessionId,
          debug: debug,
        ) {
    _path = '$keyEndPointAggregate$functionName';
  }

  final String functionName;

  @override
  late String _path;

  Future<ParseResponse> execute(
    Map<String, dynamic> pipeline, {
    Map<String, String>? headers,
  }) async {
    final String uri = '${ParseCoreData().serverUrl}$_path';

    if (pipeline.isEmpty) {
      throw ArgumentError(
        'pipeline must not be empty. Please add pipeline operations to aggregate data. '
        'Example: {"\$group": {"_id": "\$userId", "totalScore": {"\$sum": "\$score"}}}',
      );
    }

    // Each pipeline stage is sent as an individual query parameter
    // with its JSON-encoded value, matching Parse Server's getPipeline() format
    final Map<String, String> parameters = {
      for (final entry in pipeline.entries)
        entry.key: jsonEncode(entry.value),
    };

    try {
      final ParseNetworkResponse result = await _client.get(
        Uri.parse(uri).replace(queryParameters: parameters).toString(),
        options: ParseNetworkOptions(headers: headers),
      );
      return handleResponse<ParseAggregate>(
          this, result, ParseApiRQ.execute, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.execute, _debug, parseClassName);
    }
  }
}
