import 'dart:convert';

import 'package:meta/meta.dart';

abstract class ParseBase {
  Map _objectData;

  get getObjectId => _objectData['objectId'] == null ? objectId : _objectData['objectId'];
  String objectId;

  get getCreatedAt => _objectData['createdAt'] == null ? createdAt : _objectData['createdAt'];
  DateTime createdAt;

  get getUpdatedAt => _objectData['updatedAt'] == null ? updatedAt : _objectData['updatedAt'];
  DateTime updatedAt;

  @protected
  toJson() => JsonEncoder().convert(getObjectData());

  @protected
  copy() => JsonDecoder().convert(fromJson(getObjectData()));

  @protected
  setObjectData(Map objectData) => _objectData = objectData;

  @protected
  getObjectData() => _objectData;

  @protected
  fromJson(Map objectData) {
    if (_objectData == null) _objectData = Map();
    _objectData.addAll(objectData);
  }

  set(String key, dynamic value, {bool forceUpdate: true}) {
    if (value != null) {
      if (getObjectData().containsKey(key)) {
        if (forceUpdate) getObjectData()[key] = value;
      } else {
        getObjectData()[key] = value;
      }
    }
  }

  getValue(String key, {dynamic defaultValue, bool fromServer}) {
    if (getObjectData().containsKey(key)) {
      return getObjectData()[key];
    } else {
      return defaultValue;
    }
  }
}
