part of flutter_parse_sdk;

abstract class ParseBase {
  /// Stores all the values of a class
  Map _objectData = Map<String, dynamic>();

  /// Returns [String] objectId
  String get objectId => _objectData['objectId'];
  set objectId(String objectId) => _objectData[objectId];

  /// Returns [DateTime] createdAt
  DateTime get createdAt => stringToDateTime(_objectData['createdAt']);
  set createdAt(DateTime createdAt) =>
      _objectData['createdAt'] = dateTimeToString(createdAt);

  /// Returns [DateTime] updatedAt
  DateTime get updatedAt => stringToDateTime(_objectData['updatedAt']);
  set updatedAt(DateTime updatedAt) =>
      _objectData['updatedAt'] = dateTimeToString(updatedAt);

  /// Converts object to [String] in JSON format
  @protected
  toJson() => JsonEncoder().convert(getObjectData());

  /// Creates a copy of this class
  @protected
  copy() => JsonDecoder().convert(fromJson(getObjectData()));

  /// Sets all the objects variables
  @protected
  setObjectData(Map objectData) => _objectData = objectData;

  /// Returns the objects variables
  @protected
  getObjectData() => _objectData;

  /// Saves in storage
  @protected
  saveInStorage(String key) async {
    await ParseCoreData().getStore().setString(key, toJson());
  }

  @protected
  fromJson(Map objectData) {
    if (_objectData == null) _objectData = Map();
    _objectData.addAll(objectData);
  }

  /// Create a new variable for this object, [bool] forceUpdate is always true,
  /// if unsure as to whether an item is needed or not, set to false
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

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  pin() async {
    if (objectId != null) {
      await ParseCoreData().getStore().setString(objectId, toJson());
      return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  unpin() async {
    if (objectId != null) {
      var itemToSave = await ParseCoreData().getStore().setString(objectId, null);
      return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  fromPin() async {
    if (objectId != null) {
      var itemFromStore = await ParseCoreData().getStore().getString(objectId);

      if (itemFromStore != null) {
        Map<String, dynamic> itemFromStoreMap = JsonDecoder().convert(
            itemFromStore);
        fromJson(itemFromStoreMap);
        return this;
      }
    }
    return null;
  }
}
