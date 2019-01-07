part of flutter_parse_sdk;

abstract class ParseBase {
  /// Stores all the values of a class
  Map _objectData;

  /// Returns [String] objectId
  get getObjectId => _objectData['objectId'] == null ? objectId : _objectData['objectId'];
  String objectId;

  /// Returns [DateTime] createdAt
  get getCreatedAt => _objectData['createdAt'] == null ? createdAt : _objectData['createdAt'];
  DateTime createdAt;

  /// Returns [DateTime] updatedAt
  get getUpdatedAt => _objectData['updatedAt'] == null ? updatedAt : _objectData['updatedAt'];
  DateTime updatedAt;

  @protected
  toJson() => JsonEncoder().convert(getObjectData());

  @protected
  copy() => JsonDecoder().convert(fromJson(getObjectData()));

  /// Sets all the objects variables
  @protected
  setObjectData(Map objectData) => _objectData = objectData;

  /// Returns the objects variables
  @protected
  getObjectData() => _objectData;

  @protected
  fromJson(Map objectData) {
    if (_objectData == null) _objectData = Map();
    _objectData.addAll(objectData);
  }

  /// Create a new variable for this object, [bool] forceUpdate is always true,
  /// if unsure as to wether an item is needed or not, set to false
  set(String key, dynamic value, {bool forceUpdate: true}) {
    if (value != null) {
      if (getObjectData().containsKey(key)) {
        if (forceUpdate) getObjectData()[key] = value;
      } else {
        getObjectData()[key] = value;
      }
    }
  }

  /// Returns a variable from the objectData
  get(String key, {dynamic defaultValue, bool fromServer}) {
    if (getObjectData().containsKey(key)) {
      return getObjectData()[key];
    } else {
      return defaultValue;
    }
  }
}
