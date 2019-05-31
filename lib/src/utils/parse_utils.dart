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

/// Removes unncessary /
String removeTrailingSlash(String serverUrl) {
  if (serverUrl.substring(serverUrl.length - 1) == '/') {
    return serverUrl.substring(0, serverUrl.length - 1);
  } else {
    return serverUrl;
  }
}
