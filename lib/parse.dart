import 'package:parse/parse_data.dart';
import 'package:parse/parse_http_client.dart';
import 'package:parse/parse_livequery.dart';
import 'package:parse/parse_object.dart';
import 'package:parse/parse_user.dart';

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

  ParseObject _parseObject;
  User _user;
  LiveQuery _liveQuery;

  ParseObject object(objectName) {
    return _parseObject = new ParseObject(objectName, client);
  }

  User user() {
    return _user = new User(client);
  }

  LiveQuery liveQuery() {
    return _liveQuery = new LiveQuery(client);
  }
}
