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
  bool _debug;

  ParseUser({debug, ParseHTTPClient client}) {
    client != null ? _client = client : _client = ParseHTTPClient();

    if (_debug == null) {
      _debug = client.data.debug;
    } else {
      _debug = _debug;
    }
  }

  create(String username, String password, String emailAddress) {
    User.init(username, password, emailAddress);
    return User.instance;
  }

  currentUser({bool fromServer: false}) async {
    if (_client.data.sessionId == null) {
      return null;
    } else if (fromServer == false) {
      return User.instance;
    } else {

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri uri= Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$path/me");

      final response = await _client.get(uri, headers: {
        ParseConstants.HEADER_SESSION_TOKEN: _client.data.sessionId
      });
      return _handleResponse(response, ParseApiUserCallType.currentUser);
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

    _handleResponse(response, ParseApiUserCallType.signUp);
    return User.instance;
  }

  login() async {
    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}/login",
        queryParameters: {
          "username": User.instance.username,
          "password": User.instance.password
        });

    final response = await _client.post(url, headers: {
      ParseConstants.HEADER_REVOCABLE_SESSION: "1",
    });

    _handleResponse(response, ParseApiUserCallType.login);
    return User.instance;
  }

  verificationEmailRequest() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/verificationEmailRequest",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResponse(
        response, ParseApiUserCallType.verificationEmailRequest);
  }

  requestPasswordReset() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/requestPasswordReset",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResponse(response, ParseApiUserCallType.requestPasswordReset);
  }

  save() async {
    if (User.instance.objectId == null) {
      return signUp();
    } else {
      final response = await _client.put(
          _client.data.serverUrl + "$path/${User().objectId}",
          body: JsonEncoder().convert(User().getObjectData()));
      return _handleResponse(response, ParseApiUserCallType.save);
    }
  }

  destroy() async {
    final response = await _client.delete(
        _client.data.serverUrl + "$path/${User().objectId}",
        headers: {"X-Parse-Session-Token": _client.data.sessionId});

    _handleResponse(response, ParseApiUserCallType.destroy);

    return User.instance.objectId;
  }

  all() async {
    final response = await _client.get(_client.data.serverUrl + "$path");
    return _handleResponse(response, ParseApiUserCallType.all);
  }

  _handleResponse(Response response, ParseApiUserCallType type) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    var responseString = ' \n';

    responseString += "----"
        "\n${_client.data.appName} API Response ($className : ${getEnumValue(type)}) :";

    if (response.statusCode == 200 || response.statusCode == 201) {
      responseString += "\nStatus Code: ${response.statusCode}";
      responseString += "\nPayload: ${responseData.toString()}";

      if (responseData.containsKey('objectId')) {
        User.instance.fromJson(JsonDecoder().convert(response.body) as Map);
        _client.data.sessionId = responseData['sessionToken'];
      }
    } else {
      responseString += "\nStatus Code: ${responseData['code']}";
      responseString += "\nException: ${responseData['error']}";
    }

    if (_client.data.debug || _debug) {
      responseString += "\n----\n";
      print(responseString);
    }

    return User.instance;
  }
}
