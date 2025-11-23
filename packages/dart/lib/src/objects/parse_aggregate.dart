
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

  Future<ParseResponse> execute(Map<String, dynamic> pipeline, {Map<String, String>? headers}) async {
    final String uri = '${ParseCoreData().serverUrl}$_path';

    Map<String, String> parameters = {};

    if (pipeline.isEmpty) {
      throw ArgumentError(
        'pipeline must not be empty. Please add pipeline operations to aggregate data. '
        'Example: {"\$group": {"_id": "\$userId", "totalScore": {"\$sum": "\$score"}}}',
      );
    } else {
      parameters.addAll({
        'pipeline': jsonEncode(pipeline.entries.map((e) => {e.key: e.value}).toList())
      });
      _setObjectData(pipeline);
    }

    try {
      print(Uri.parse(uri).replace(queryParameters: parameters).toString());
      final ParseNetworkResponse result = await _client.get(
      Uri.parse(uri).replace(queryParameters: parameters).toString(),
      options: ParseNetworkOptions(headers: headers)
    );
      return ParseResponse.fromParseNetworkResponse(result);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.execute, _debug, parseClassName);
    }
  }
}
