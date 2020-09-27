part of flutter_parse_sdk;

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
    responseString += '\nStatus Code: ${parseResponse.error.code}';
    responseString += '\nType: ${parseResponse.error.type}';

    final String errorOrException =
        parseResponse.error.exception != null ? 'Exception' : 'Error';

    responseString += '\n$errorOrException: ${parseResponse.error.message}';
  }

  responseString += '\n╰-- \n';
  responseString += spacer;
  print(responseString);
}

void logCUrl(dio.Options options, dynamic data, String url) {
  String curlCmd = 'curl';
  curlCmd += ' -X ' + options.method;
  bool compressed = false;
  options.headers.forEach((String name, dynamic value) {
    if (name?.toLowerCase() == 'accept-encoding' &&
        value?.toString()?.toLowerCase() == 'gzip') {
      compressed = true;
    }
    curlCmd += ' -H \'$name: $value\'';
  });

  //TODO: log request
  // if (options.method == 'POST' || options.method == 'PUT') {
  //   if (request is Request) {
  //     final String body = latin1.decode(request.bodyBytes);
  //     curlCmd += ' -d \'$body\'';
  //   }
  // }

  curlCmd += (compressed ? ' --compressed ' : ' ') + url;
  curlCmd += '\n\n ${Uri.decodeFull(url)}';
  print('╭-- Parse Request');
  print(curlCmd);
  print('╰--');
}

void logRequest(
    String appName, String className, String type, String uri, String body) {
  String requestString = ' \n';
  String name = appName;
  if (name.isNotEmpty) {
    name = '$appName ';
  }
  requestString += '----\n${name}API Request ($className : $type) :';
  requestString += '\nUri: $uri';
  requestString += '\nBody: $body';

  requestString += '\n----\n';
  print(requestString);
}
