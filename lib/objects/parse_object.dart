import 'dart:async';
import 'dart:convert';

import 'package:parse_server_sdk/objects/parse_base.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';
import 'package:parse_server_sdk/objects/parse_exception.dart';
import 'package:parse_server_sdk/objects/parse_response.dart';
import 'package:parse_server_sdk/utils/parse_utils_objects.dart';
import 'package:http/http.dart';

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

  Future<ParseResponse> create([Map<String, dynamic> objectInitialData]) async {
    objectData = {}..addAll(objectData)..addAll(objectInitialData);

    final response = this._client.post("${_client.data.serverUrl}$path",
        body: JsonEncoder().convert(objectData));
    return response.then((value) {
      return ParseResponse.handleResponse(this, value);
    });
  }

  Future<ParseResponse> save([Map<String, dynamic> objectInitialData]) {
    objectData = {}..addAll(objectData)..addAll(objectInitialData);
    if (objectId == null) {
      return create(objectData);
    } else {
      final response = this._client.put(
          _client.data.serverUrl + "$path/$objectId",
          body: JsonEncoder().convert(objectData));
      return response.then((value) {
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

    return this._client.get(uri).then((value) {
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
