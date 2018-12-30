import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:parse_server_sdk/network/parse_http_client.dart';

abstract class ParseBaseObject {
  ParseHTTPClient _client;

  Map<String, dynamic> _objectData;
  String get objectId => _objectData['objectId'];
  DateTime get createdAt => _objectData['createdAt'];
  DateTime get updatedAt => _objectData['updatedAt'];

  ParseBaseObject([this._client]){
   _objectData = Map<String, dynamic>();
  }

  @protected
  setClient(ParseHTTPClient client) => _client = client;
  @protected
  getDebugStatus() => _client.data.debug;
  @protected
  getAppName() => _client.data.appName;
  @protected
  getObjectData() => _objectData;
  @protected
  fromJson(Map<String, dynamic> objectData) => objectData;

  toJson() => JsonEncoder().convert(getObjectData());

  copy() {
    var copy = fromJson(_objectData);
    return JsonDecoder().convert(copy);
  }

  _getBasePath(String path) => "${_client.data.serverUrl}$path";

  setValue(String key, dynamic value, {bool forceUpdate: true}) {
    if (value != null) {
      if (_objectData.containsKey(key)) {
        if (forceUpdate) _objectData[key] = value;
      } else {
        _objectData[key] = value;
      }
    }
  }

  getValue(String key, {dynamic defaultValue, bool fromServer}) {
    if (_objectData.containsKey(key)) {
      return _objectData[key];
    } else {
      return defaultValue;
    }
  }

  _get(String objectId, String path) async {
    var uri = _getBasePath(path);
    if (objectId != null) uri += "/$objectId";
    return _client.get(uri);
  }

  _getAll(String path) async {
    return _client.get(_getBasePath(path));
  }

  @protected
  parseGetAll(String path) => _getAll(path);
  @protected
  parseGetObjectById(String objectId, String path) => _get(objectId, path);

  _create(String path) async {
    var uri = _client.data.serverUrl + "$path";
    return _client.post(uri, body: JsonEncoder().convert(_objectData));
  }

  @protected
  parseCreate(String path, Map objectData) => _create(path);

  _save(String path) {
    if (_objectData == null) {
      return _create(path);
    } else {
      var uri = "${_getBasePath(path)}/$objectId";
      return _client.put(uri, body: JsonEncoder().convert(_objectData));
    }
  }

  @protected
  parseSave(String path) => _save(path);

  _query(String path, String query) async {
     var uri = "${_getBasePath(path)}?$query";
     return _client.get(uri);
  }

  @protected
  parseQuery(String path, String query) => _query(path, query);

  _delete(String path, String objectId){
    var uri = "${_getBasePath(path)}/$objectId";
    return _client.delete(uri);
  }

  @protected
  parseDelete(String path, String query) => _delete(path, objectId);
}
