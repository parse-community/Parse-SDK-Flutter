import 'dart:convert';

import 'package:meta/meta.dart';

abstract class ParseBase {
  Map<String, dynamic> _objectData;

  String get objectId => _objectData['objectId'];

  DateTime get createdAt => _objectData['createdAt'];

  DateTime get updatedAt => _objectData['updatedAt'];

  @protected
  toJson() => JsonEncoder().convert(getObjectData());

  @protected
  copy() => JsonDecoder().convert(fromJson(getObjectData()));

  @protected
  setObjectData(Map<String, dynamic> objectData) => _objectData = objectData;

  @protected
  getObjectData() => _objectData;

  @protected
  fromJson(Map<String, dynamic> objectData) => objectData;

  setValue(String key, dynamic value, {bool forceUpdate: true}) {
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
