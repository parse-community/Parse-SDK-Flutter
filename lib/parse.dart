import 'package:parse_server_sdk/data/parse_data_server.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/network/parse_livequery.dart';
import 'package:parse_server_sdk/objects/parse_object.dart';
import 'package:parse_server_sdk/objects/parse_user.dart';

class Parse {
  ParseDataServer data;
  final ParseHTTPClient client = new ParseHTTPClient();

  Parse();

  Parse initialize(appId, serverUrl, {liveQueryUrl, masterKey, sessionId}) {
    ParseDataServer.init(appId, serverUrl,
        liveQueryUrl: liveQueryUrl, masterKey: masterKey, sessionId: sessionId);

    return newInstance(ParseDataServer());
  }

  Parse newInstance(ParseDataServer data) {
    var parse = Parse();
    parse.data = data;
    parse.client.data = data;
    return parse;
  }

  // ignore: unused_field
  ParseObject _parseObject;

  // ignore: unused_field
  User _user;

  // ignore: unused_field
  LiveQuery _liveQuery;

  ParseObject object(objectName) {
    return _parseObject = new ParseObject(objectName);
  }

  User user() {
    return _user = new User();
  }

  LiveQuery liveQuery() {
    return _liveQuery = new LiveQuery(client);
  }
}
