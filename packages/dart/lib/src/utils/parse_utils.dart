part of flutter_parse_sdk;

/// Checks whether debug is enabled
///
/// Debug can be set in 2 places, one global param in the Parse.initialize, and
/// then can be overwritten class by class
bool isDebugEnabled({bool? objectLevelDebug}) {
  return objectLevelDebug ?? ParseCoreData().debug;
}

/// Convert list of strings to a string with commas
String concatenateArray(List<String> list) {
  String output = '';

  for (final String item in list) {
    if (item == list.first) {
      output += item;
    } else {
      output += ',$item';
    }
  }

  return output;
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
Uri getSanitisedUri(ParseClient client, String pathToAppend,
    {Map<String, dynamic>? queryParams, String? query}) {
  final Uri tempUri = Uri.parse(ParseCoreData().serverUrl);

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
Uri getCustomUri(ParseClient client, String path,
    {Map<String, dynamic>? queryParams, String? query}) {
  final Uri tempUri = Uri.parse(ParseCoreData().serverUrl);

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
    {ParseClient? client, bool? debug}) async {
  debug = isDebugEnabled(objectLevelDebug: debug);
  client = client ??
      ParseCoreData().clientCreator(
          sendSessionId: ParseCoreData().autoSendSessionId,
          securityContext: ParseCoreData().securityContext);
  try {
    final Uri url = getSanitisedUri(client, '/batch');
    final String body = json.encode(<String, dynamic>{'requests': requests});
    final ParseNetworkResponse result =
        await client.post(url.toString(), data: body);

    return handleResponse<ParseObject>(
        objects, result, ParseApiRQ.batch, debug, 'parse_utils');
  } on Exception catch (e) {
    return handleException(e, ParseApiRQ.batch, debug, 'parse_utils');
  }
}

Stream<T> _createStreamError<T>(Object error) async* {
  throw error;
}

List removeDuplicateParseObjectByObjectId(Iterable iterable) {
  final list = iterable.toList();

  final foldedGroupedByObjectId = list
      .whereType<ParseObject>()
      .where((e) => e.objectId != null)
      .groupFoldBy(
        (e) => e.objectId!,
        (previous, element) => element,
      );

  list.removeWhere(
    (e) {
      return e is ParseObject &&
          foldedGroupedByObjectId.keys.contains(e.objectId);
    },
  );

  list.addAll(foldedGroupedByObjectId.values);

  return list;
}

// check the coreStore for existing objects to delete or save eventually
Future<bool> checkObjectsExistForEventually() async {
  // preparation ParseCoreData
  final CoreStore coreStore = ParseCoreData().getStore();

  List<String>? listSaves = await coreStore.getStringList(keyParseStoreObjects);

  if (listSaves != null) {
    if (listSaves.isNotEmpty) {
      return true;
    }
  }

  List<String>? listDeletes =
      await coreStore.getStringList(keyParseStoreDeletes);

  if (listDeletes != null) {
    if (listDeletes.isNotEmpty) {
      return true;
    }
  }

  return false;
}

// To get out of the cycle
bool _inSubmitEventually = false;

Future<void> checkForSubmitEventually() async {
  if (_inSubmitEventually) return;

  if (Parse.objectsExistForEventually) {
    _inSubmitEventually = true;
    await ParseObject.submitEventually();
    _inSubmitEventually = false;
  }
}
