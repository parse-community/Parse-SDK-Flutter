part of '../../parse_server_sdk.dart';

class ParseAggregate {
  final String className;
  Map<String, dynamic> pipeline;
  final bool? debug;
  final ParseClient? client;
  final bool? autoSendSessionId;
  final String? parseClassName;

  ParseAggregate(this.className,{required this.pipeline,this.debug, this.client, this.autoSendSessionId, this.parseClassName});

  Future<ParseResponse> execute() async {
    Map<String,String> _pipeline={};
    if(pipeline.isEmpty){
      throw ArgumentError('pipeline must not be empty. Please add pipeline operations to aggregate data.  Example: {"\$group": {"_id": "\$userId", "totalScore": {"\$sum": "\$score"}}}  ');
    }
    else{
      _pipeline.addAll({'pipeline':jsonEncode(pipeline.entries.map((e) => {e.key: e.value}).toList())});
    }
    final debugBool = isDebugEnabled(objectLevelDebug: debug);
    final result = await ParseObject(className)._client.get(
      Uri.parse('${ParseCoreData().serverUrl}$keyEndPointAggregate$className').replace(queryParameters: _pipeline).toString(),
    );
    print('result >>> ${result.data}');
    return handleResponse<ParseObject>(
      ParseObject(className),
      result,
      ParseApiRQ.get,
      debugBool,
      parseClassName ?? 'ParseBase',
    );
  }
}
