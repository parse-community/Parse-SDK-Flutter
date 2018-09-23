import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/src/base_request.dart';
import 'package:http/src/streamed_response.dart';
import 'package:parse/parse_data.dart';

class ParseHTTPClient extends http.BaseClient {
  final http.Client _client = new http.Client();
  final String _userAgent = "Dart Parse SDK 0.1";
  ParseData data;

  ParseHTTPClient();

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    request.headers['X-Parse-Application-Id'] = data.applicationId;
    request.headers['Content-Type'] = 'application/json';
    if (data.masterKey != null) request.headers['X-Parse-Master-Key'] = data.masterKey;
    return _client.send(request);
  }
}
