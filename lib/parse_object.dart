import 'dart:collection';
import 'dart:convert';
import 'dart:async';

import 'parse_base.dart';
import 'parse_http_client.dart';

class ParseObject implements ParseBaseObject {
  final String className;
  final ParseHTTPClient client;
  String path;
  Map<String, dynamic> objectData = {};

  String get objectId => objectData['objectId'];
  ParseObject(this.className, [this.client]) {
    path = "/parse/classes/$className";
  }

  Future<Map> create([Map<String, dynamic> objectInitialData]) async {
    objectData = {}..addAll(objectData)..addAll(objectInitialData);

    final response = this.client.post("${client.data.serverUrl}$path", body: JsonEncoder().convert(objectData));
    return response.then((value){
      objectData = JsonDecoder().convert(value.body);
      return objectData;
    });
  }

  Future<Map<String, Object>> get(attribute) async {
      final response = this.client.get(client.data.serverUrl + "$path/$attribute");
      return response.then((value){
        return JsonDecoder().convert(value.body);
      });
  }

  void set(String attribute, dynamic value){
    objectData[attribute] = value;
  }

  Future<Map> save([Map<String, dynamic> objectInitialData]){
    objectData = {}..addAll(objectData)..addAll(objectInitialData);
    if (objectId == null){
        return create(objectData);
    }
    else {
      final response = this.client.put(
          client.data.serverUrl + "$path/$objectId",  body: JsonEncoder().convert(objectData));
      return response.then((value) {
        objectData = JsonDecoder().convert(value.body);
        return objectData;
      });
    }
  }

  Future<String> destroy(){
    final response = this.client.delete(client.data.serverUrl + "$path/$objectId");
    return response.then((value){
      return JsonDecoder().convert(value.body);
    });
  }
}

