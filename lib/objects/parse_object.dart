import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';

class ParseObject implements ParseBaseObject {
  final ParseHTTPClient _client = ParseHTTPClient();
  Map<String, dynamic> objectData = {};
  final String className;
  String path;

  String objectId;
  DateTime createdAt;
  DateTime updatedAt;

  ParseObject(this.className) {
    path = "/classes/$className";
  }

  createObjectData(Map<String, dynamic> objectData) {
    // ParseDataUser.init(username, password, emailAddress);
    this.objectData = objectData;
    // return this;
  }

  Future<ParseResponse> create([Map<String, dynamic> objectInitialData]) async {
    if (objectInitialData != null) {
      objectData = {}..addAll(objectData)..addAll(objectInitialData);
    }

    final response = this._client.post("${_client.data.serverUrl}$path",
        body: JsonEncoder().convert(objectData));
    return response.then((value) {
      return ParseResponse.handleResponse(this, value);
    });
  }

  Future<ParseResponse> save([Map<String, dynamic> objectInitialData]) {
    if (objectInitialData != null) {
      objectData = {}..addAll(objectData)..addAll(objectInitialData);
    }
    if (objectId == null) {
      return create(objectData);
    } else {
      // Map<String, dynamic> bodyData = {};
      // bodyData["email"] = objectData.name;
      // bodyData["password"] = objectData.password;

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          port: tempUri.port,
          path: "${tempUri.path}$path/$objectId");

      print("put url: $url");
      print("objectData: $objectData");
      final response =
          this._client.put(url, body: JsonEncoder().convert(objectData));
      return response.then((value) {
        print("value: ${value.body}");
        return ParseResponse.handleResponse(this, value);
      });
    }
  }

  Future<ParseResponse> getAll({String query}) async {
    String uri = _client.data.serverUrl + "$path";

    return this._client.get(uri).then((value) {
      return ParseResponse.handleResponse(this, value);
    });
  }

  Future<ParseResponse> get(String objectId) async {
    String uri = _client.data.serverUrl + "$path";

    if (objectId != null) uri += "/$objectId";
    print("uri: $uri");
    return this._client.get(uri).then((value) {
      print("value: $value");
      return ParseResponse.handleResponse(this, value);
    });
  }

  Future<ParseResponse> getQuery(String bodyBytes) async {
    String uri = _client.data.serverUrl + "$path" + "?" + bodyBytes;

    return this._client.get(uri).then((value) {
      return ParseResponse.handleResponse(this, value);
    });
  }

  Future<String> destroy() {
    final response =
        this._client.delete(_client.data.serverUrl + "$path/$objectId");
    return response.then((value) {
      return JsonDecoder().convert(value.body);
    });
  }

  dynamic fromJson(Map<String, dynamic> objectData) {
    return objectData;
  }

  void set(String attribute, dynamic value) {
    objectData[attribute] = value;
  }

  dynamic copy() {
    return ParseObject(className);
  }
}
