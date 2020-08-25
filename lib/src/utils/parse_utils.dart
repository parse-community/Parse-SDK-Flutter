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

/// Removes unnecessary slashes
String removeTrailingSlash(String serverUrl) {
  if (serverUrl.isNotEmpty &&
      serverUrl.substring(serverUrl.length - 1) == '/') {
    return serverUrl.substring(0, serverUrl.length - 1);
  } else {
    return serverUrl;
  }
}

/// Should not be public facing. Do not use
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
    final Response result = await client.post(url, body: body);

    return handleResponse<ParseObject>(
        objects, result, ParseApiRQ.batch, debug, 'parse_utils');
  } on Exception catch (e) {
    return handleException(e, ParseApiRQ.batch, debug, 'parse_utils');
  }
}

/// For handling batch requests
Future<ParseResponse> doBatchRequest(List<ParseObject> batch) async {
  final ParseResponse totalResponse = ParseResponse()
    ..success = true
    ..results = List<dynamic>()
    ..statusCode = 200;

  final List<List<ParseObject>> chunks = <List<ParseObject>>[];
  for (int i = 0; i < batch.length; i += 50) {
    chunks.add(batch.sublist(i, min(batch.length, i + 50)));
  }

  for (List<ParseObject> chunk in chunks) {
    final List<dynamic> requests = chunk.map<dynamic>((ParseObject obj) {
      return obj._getRequestJson(obj.objectId == null ? 'POST' : 'PUT');
    }).toList();
    for (ParseObject obj in chunk) {
      obj._saveChanges();
    }
    final ParseResponse response = await batchRequest(requests, chunk);
    totalResponse.success &= response.success;

    if (response.success) {
      totalResponse.results.addAll(response.results);
      totalResponse.count += response.count;
      for (int i = 0; i < response.count; i++) {
        if (response.results[i] is ParseError) {
          // Batch request succeed, but part of batch failed.
          chunk[i]._revertSavingChanges();
        } else {
          chunk[i]._savingChanges.clear();
        }
      }
    }
  }

  return totalResponse;
}
