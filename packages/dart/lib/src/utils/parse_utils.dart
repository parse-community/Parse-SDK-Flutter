part of flutter_parse_sdk;

/// Checks whether debug is enabled
///
/// Debug can be set in 2 places, one global param in the Parse.initialize, and
/// then can be overwritten class by class
bool isDebugEnabled({bool objectLevelDebug}) {
  return objectLevelDebug ??= ParseCoreData().debug;
}

/// Converts the object to the correct value for JSON,
///
/// Strings are wrapped with "" but integers and others are not
dynamic convertValueToCorrectType(dynamic value) {
  /*if (value is String && !value.contains('__type')) {
    return '\"$value\"';
  }*/

  if (value is DateTime || value is ParseObject) {
    return parseEncode(value);
  } else {
    return value;
  }
}

/// Sanitises a url
Uri getSanitisedUri(ParseHTTPClient client, String pathToAppend,
    {Map<String, dynamic> queryParams, String query}) {
  final Uri tempUri = Uri.parse(client.data.serverUrl);

  final Uri url = Uri(
      scheme: tempUri.scheme,
      host: tempUri.host,
      port: tempUri.port,
      path: '${tempUri.path}$pathToAppend',
      queryParameters: queryParams,
      query: query);

  return url;
}

/// Sanitises a url
Uri getCustomUri(ParseHTTPClient client, String path,
    {Map<String, dynamic> queryParams, String query}) {
  final Uri tempUri = Uri.parse(client.data.serverUrl);

  final Uri url = Uri(
      scheme: tempUri.scheme,
      host: tempUri.host,
      port: tempUri.port,
      path: path,
      queryParameters: queryParams,
      query: query);

  return url;
}

/// Removes unncessary /
String removeTrailingSlash(String serverUrl) {
  if (serverUrl.isNotEmpty &&
      serverUrl.substring(serverUrl.length - 1) == '/') {
    return serverUrl.substring(0, serverUrl.length - 1);
  } else {
    return serverUrl;
  }
}

Future<ParseResponse> batchRequest(
    List<dynamic> requests, List<ParseObject> objects,
    {ParseHTTPClient client, bool debug}) async {
  debug = isDebugEnabled(objectLevelDebug: debug);
  client = client ??
      ParseHTTPClient(
          sendSessionId: ParseCoreData().autoSendSessionId,
          securityContext: ParseCoreData().securityContext);
  try {
    final Uri url = getSanitisedUri(client, '/batch');
    final String body = json.encode(<String, dynamic>{'requests': requests});
    final Response<String> result =
      await client.post<String>(url.toString(), data: body);

    return handleResponse<ParseObject>(
        objects, result, ParseApiRQ.batch, debug, 'parse_utils');
  } on Exception catch (e) {
    return handleException(e, ParseApiRQ.batch, debug, 'parse_utils');
  }
}

Stream<T> _createStreamError<T>(Object error) async* {
  throw error;
}
