import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:parse_server_sdk/data/parse_data_server.dart';

class ParseHTTPClient extends http.BaseClient {
  final http.Client _client = new http.Client();
  final String _userAgent = "Dart Parse SDK 0.1";
  ParseDataServer data = ParseDataServer();

  ParseHTTPClient();

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    request.headers['X-Parse-Application-Id'] = data.applicationId;
    request.headers['Content-Type'] = 'application/json';
    if (data.masterKey != null)
      request.headers['X-Parse-Master-Key'] = data.masterKey;
    print("request: $request");
    return _client.send(request);
  }
}
