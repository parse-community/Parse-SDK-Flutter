import 'package:parse_server_sdk/parse_data.dart';
import 'package:parse_server_sdk/parse_http_client.dart';
import 'package:parse_server_sdk/parse_livequery.dart';
import 'package:parse_server_sdk/parse_object.dart';
import 'package:parse_server_sdk/parse_user.dart';

class Parse {
  ParseData data;
  final ParseHTTPClient client = new ParseHTTPClient();

  Parse();

  Parse initialize({appId, serverUrl, liveQueryUrl, masterKey, sessionId}) {
    ParseData.init(appId, serverUrl,
        liveQueryUrl: liveQueryUrl, masterKey: masterKey, sessionId: sessionId);

    return newInstance(ParseData());
  }

  Parse newInstance(ParseData data) {
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
