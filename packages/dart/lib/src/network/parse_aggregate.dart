part of '../../parse_server_sdk.dart';

class ParseAggregate {
  final String className;
  final Map<String, dynamic> pipeline;
  final bool? debug;
  final ParseClient? client;
  final bool? autoSendSessionId;
  final String? parseClassName;

  ParseAggregate(this.className,{required this.pipeline,this.debug, this.client, this.autoSendSessionId, this.parseClassName});

  Future<ParseResponse> execute() async {
    if(pipeline.isEmpty){
      throw ArgumentError('pipeline must not be empty. Please add pipeline operations to aggregate data.  Example: {"\$group": {"_id": "\$userId", "totalScore": {"\$sum": "\$score"}}}  ');
    }
    final debugBool = isDebugEnabled(objectLevelDebug: debug);
    final result = await ParseHTTPClient().get(
      '${ParseCoreData().serverUrl}$keyEndPointAggregate/$className',
      replace: UrlReplace(queryParameters: pipeline)
    );
    return handleResponse<ParseObject>(
      this,
      result,
      ParseApiRQ.get,
      debugBool,
      parseClassName ?? 'ParseBase',
    );
  }
}
