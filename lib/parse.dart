import 'package:parse_server_sdk/data/parse_data_server.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';

class Parse {
  ParseDataServer data;
  final ParseHTTPClient client = new ParseHTTPClient();

  Parse initialize(appId, serverUrl, {debug, appName, liveQueryUrl, masterKey, sessionId}) {
    ParseDataServer.init(appId,
        serverUrl,
        debug: debug,
        appName: appName,
        liveQueryUrl: liveQueryUrl,
        masterKey: masterKey,
        sessionId: sessionId);

    return newInstance(ParseDataServer());
  }

  Parse newInstance(ParseDataServer data) {
    var parse = Parse();
    parse.data = data;
    parse.client.data = data;
    return parse;
  }
}
