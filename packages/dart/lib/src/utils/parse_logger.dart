part of '../../parse_server_sdk.dart';

void logAPIResponse(
    String className, String type, ParseResponse parseResponse) {
  const String spacer = ' \n';
  String responseString = '';

  responseString += '╭-- Parse Response';
  responseString += '\nClass: $className';
  responseString += '\nFunction: $type';

  if (parseResponse.success) {
    responseString += '\nStatus Code: ${parseResponse.statusCode}';
    if (parseResponse.result != null) {
      responseString += '\nPayload: ${parseResponse.result.toString()}';
    } else {
      responseString += '\nReponse: OK';
    }
  } else if (!parseResponse.success) {
    responseString += '\nStatus Code: ${parseResponse.error!.code}';
    responseString += '\nType: ${parseResponse.error!.type}';

    final String errorOrException =
        parseResponse.error!.exception != null ? 'Exception' : 'Error';

    responseString += '\n$errorOrException: ${parseResponse.error!.message}';
  }

  responseString += '\n╰-- \n';
  responseString += spacer;
  print(responseString);
}

void logRequest(
    String? appName, String className, String type, String uri, String body) {
  String requestString = ' \n';
  final String name = appName != null ? '$appName ' : '';
  requestString += '----\n${name}API Request ($className : $type) :';
  requestString += '\nUri: $uri';
  requestString += '\nBody: $body';

  requestString += '\n----\n';
  print(requestString);
}
