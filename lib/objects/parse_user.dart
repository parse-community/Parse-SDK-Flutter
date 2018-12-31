import 'dart:convert';

import 'package:http/http.dart';
import 'package:parse_server_sdk/base/parse_constants.dart';
import 'package:parse_server_sdk/data/parse_data_user.dart';
import 'package:parse_server_sdk/enums/parse_enum_user_call.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';

class ParseUser {
  ParseHTTPClient _client;
  static final String className = '_User';
  String path = "/classes/$className";
  bool debug;

  ParseUser({this.debug: false, ParseHTTPClient client}) {
    client != null ? _client = client : _client = ParseHTTPClient();
  }

  create(String username, String password, String emailAddress) {
    User.init(username, password, emailAddress.toLowerCase());
    return User();
  }

  _getBasePath(String path) => "${_client.data.serverUrl}$path";

  currentUser({bool fromServer: false}) async {
    if (User() == null) {
      return null;
    } else if (fromServer == false) {
      return User();
    } else {
      var uri = "${_getBasePath(path)}/me";
      var result = await _client.get(uri, headers: {
        ParseConstants.HEADER_SESSION_TOKEN: _client.data.sessionId
      });
      return _handleResult(result, ParseApiUserCallType.currentUser);
    }
  }

  signUp() async {
    Map<String, dynamic> bodyData = {};
    bodyData["email"] = User().emailAddress;
    bodyData["password"] = User().password;
    bodyData["username"] = User().username;

    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}$path");

    final response = await _client.post(url,
        headers: {
          ParseConstants.HEADER_REVOCABLE_SESSION: "1",
        },
        body: JsonEncoder().convert(bodyData));

    _handleResult(response, ParseApiUserCallType.signUp);
    return User();
  }

  login() async {
    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}/login",
        queryParameters: {
          "username": User().username,
          "password": User().password
        });

    final response = await _client.post(url, headers: {
      ParseConstants.HEADER_REVOCABLE_SESSION: "1",
    });

    _handleResult(response, ParseApiUserCallType.login);
    return User();
  }

  verificationEmailRequest() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/verificationEmailRequest",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResult(
        response, ParseApiUserCallType.verificationEmailRequest);
  }

  requestPasswordReset() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/requestPasswordReset",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResult(response, ParseApiUserCallType.requestPasswordReset);
  }

  save() async {
    if (User().objectId == null) {
      return signUp();
    } else {
      final response = await _client.put(
          _client.data.serverUrl + "$path/${User().objectId}",
          body: JsonEncoder().convert(User().getObjectData()));
      return _handleResult(response, ParseApiUserCallType.save);
    }
  }

  destroy() async {
    final response = await _client.delete(
        _client.data.serverUrl + "$path/${User().objectId}",
        headers: {"X-Parse-Session-Token": _client.data.sessionId});
    _handleResult(response, ParseApiUserCallType.destroy);
    return User().objectId;
  }

  all() async {
    final response = await _client.get(_client.data.serverUrl + "$path");
    return _handleResult(response, ParseApiUserCallType.all);
  }

  _handleResult(Response response, ParseApiUserCallType type) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    var responseString = ' \n';

    responseString += "----"
        "\n${_client.data.appName} API Response ($className : ${getEnumValue(type)}) :";

    if (response.statusCode == 200) {
      responseString += "\nStatus Code: ${response.statusCode}";
      responseString += "\nPayload: ${responseData.toString()}";

      if (responseData.containsKey('objectId')) {
        User().fromJson(JsonDecoder().convert(response.body) as Map);
        _client.data.sessionId = responseData['sessionId'];
      }
    } else {
      responseString += "\nStatus Code: ${responseData['code']}";
      responseString += "\nException: ${responseData['error']}";
    }

    if (_client.data.debug || debug) {
      responseString += "\n----\n";
      print(responseString);
    }

    return User();
  }
}
