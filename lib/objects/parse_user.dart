import 'dart:convert';
import 'dart:async';

import 'package:parse_server_sdk/data/parse_data_user.dart';

import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';

class User implements ParseBaseObject {
  final String className = '_User';
  final ParseHTTPClient client = ParseHTTPClient();
  String path = "/classes/_User";
  Map<String, dynamic> objectData = {};

  static ParseDataUser userData;

  String get objectId => objectData['objectId'];
  String get sessionId => objectData['sessionToken'];
  String get userId => objectData['objectId'];

  User();

  User createNewUser(String username, String password, String emailAddress) {
    ParseDataUser.init(username, password, emailAddress);
    userData = ParseDataUser();
    return _newInstance(ParseDataUser());
  }

  User _newInstance(ParseDataUser data) {
    return User();
  }

  void set(String attribute, dynamic value) {
    objectData[attribute] = value;
  }

  Future<dynamic> get(attribute) async {
    final response = this.client.get(client.data.serverUrl + "$path/$objectId");
    return response.then((value) {
      objectData = JsonDecoder().convert(value.body);
      return objectData[attribute];
    });
  }

  Future<dynamic> me(attribute) async {
    final response = this.client.get(client.data.serverUrl + "$path/me",
        headers: {"X-Parse-Session-Token": sessionId});
    return response.then((value) {
      objectData = JsonDecoder().convert(value.body);
      return objectData[attribute];
    });
  }

  Map<String, dynamic> _handleResponse(String response) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response);
    if (responseData.containsKey('objectId')) {
      objectData = responseData;
      this.client.data.sessionId = sessionId;
    }
    return responseData;
  }

  void _resetObjectId() {
    if (objectId != null) objectData.remove('objectId');
    if (sessionId != null) objectData.remove('sessionToken');
  }

  Future<Map<String, dynamic>> signUp([Map<String, dynamic> objectInitialData]) async {
    if (objectInitialData != null) {
      objectData = {}..addAll(objectData)..addAll(objectInitialData);
    }
    _resetObjectId();

    Map<String, dynamic> bodyData = {};
    bodyData["email"] = userData.username;
    bodyData["password"] = userData.password;
    bodyData["username"] = userData.username;

    Uri tempUri = Uri.parse(client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}$path"
    );

    final response = this.client.post(url,
        headers: {
          'X-Parse-Revocable-Session': "1",
        },
        body: JsonEncoder().convert(bodyData));

    return response.then((value) {
      _handleResponse(value.body);
      return objectData;
    });
  }

  Future<Map<String, dynamic>> login() async {
    Uri tempUri = Uri.parse(client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}/login",
        queryParameters: {
          "username": userData.username,
          "password": userData.password
        }
    );

    final response = this.client.post(url, headers: {
      'X-Parse-Revocable-Session': "1",
    });
    return response.then((value) {
      _handleResponse(value.body);
      return objectData;
    });
  }

  Future<Map<String, dynamic>> verificationEmailRequest() async {
    final response = this.client.post(
        "${client.data.serverUrl}/verificationEmailRequest",
        body: JsonEncoder().convert({"email": userData.emailAddress}));
    return response.then((value) {
      return _handleResponse(value.body);
    });
  }

  Future<Map<String, dynamic>> requestPasswordReset() async {
    final response = this.client.post(
        "${client.data.serverUrl}/requestPasswordReset",
        body: JsonEncoder().convert({"email": userData.emailAddress}));
    return response.then((value) {
      return _handleResponse(value.body);
    });
  }

  Future<Map<String, dynamic>> save([Map<String, dynamic> objectInitialData]) {
    objectData = {}..addAll(objectData)..addAll(objectInitialData);
    if (objectId == null) {
      return signUp(objectData);
    } else {
      final response = this.client.put(
          client.data.serverUrl + "$path/$objectId",
          body: JsonEncoder().convert(objectData));
      return response.then((value) {
        return _handleResponse(value.body);
      });
    }
  }

  Future<String> destroy() {
    final response = this.client.delete(
        client.data.serverUrl + "$path/$objectId",
        headers: {"X-Parse-Session-Token": sessionId});
    return response.then((value) {
      _handleResponse(value.body);
      return objectId;
    });
  }

  Future<Map<String, dynamic>> all() {
    final response = this.client.get(client.data.serverUrl + "$path");
    return response.then((value) {
      return _handleResponse(value.body);
    });
  }
}
