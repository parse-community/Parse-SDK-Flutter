part of flutter_parse_sdk;

abstract class ParseBase {

  String className;

  setClassName(String className) => this.className = className;
  String getClassName() => className;

  /// Stores all the values of a class
  Map _objectData = Map<String, dynamic>();

  /// Returns [String] objectId
  String get objectId => get<String>(OBJECT_ID);
  set objectId(String objectId) => set<String>(OBJECT_ID, objectId);

  /// Returns [DateTime] createdAt
  DateTime get createdAt => stringToDateTime(get<String>(CREATED_AT));
  set createdAt(DateTime createdAt) => set<String>(CREATED_AT, dateTimeToString(createdAt));

  /// Returns [DateTime] updatedAt
  DateTime get updatedAt => stringToDateTime(get<String>(UPDATED_AT));
  set updatedAt(DateTime updatedAt) => set<String>(UPDATED_AT, dateTimeToString(updatedAt));

  /// Converts object to [String] in JSON format
  @protected String toJson() {
    return JsonEncoder().convert(getObjectData());
  }

  /// Creates a copy of this class
  @protected copy() => fromJson(JsonDecoder().convert(toJson()));

  /// Sets all the objects variables
  @protected setObjectData(Map objectData) {
    _objectData = objectData;
  }

  /// Returns the objects variables
  @protected getObjectData() {
    return _objectData;
  }

  /// Saves in storage
  @protected saveInStorage(String key) async {
    await ParseCoreData().getStore().setString(key, toJson());
  }

  @protected fromJson(Map objectData) {
    if (getObjectData() == null) setObjectData(Map());
    getObjectData().addAll(objectData);
    return this;
  }

  /// Sets type [T] from objectData
  ///
  /// To set an int, call setType<int> and an int will be saved
  /// [bool] forceUpdate is always true, if unsure as to whether an item is
  /// needed or not, set to false
  set<T>(String key, T value, {bool forceUpdate: true}) {
    if (value != null) {
      if (getObjectData().containsKey(key)) {
        if (forceUpdate) getObjectData()[key] = value;
      } else {
        getObjectData()[key] = value;
      }
    }
  }

  /// Gets type [T] from objectData
  ///
  /// Returns null or [defaultValue] if provided. To get an int, call
  /// getType<int> and an int will be returned, null, or a defaultValue if
  /// provided
  get<T>(String key, {T defaultValue}) {
    if (getObjectData().containsKey(key)) {
      if (T != null && getObjectData()[key] is T) {
        return getObjectData()[key] as T;
      } else {
        return getObjectData()[key];
      }
    } else {
      return defaultValue;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  pin() async {
    if (objectId != null) {
      var itemToSave = toJson();
      await ParseCoreData().getStore().setString(objectId, itemToSave);
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
      var itemToSave = await ParseCoreData().getStore().setString(
          objectId, null);
      if (itemToSave) return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  fromPin(String objectId) {
    if (objectId != null) {
      var itemFromStore = ParseCoreData().getStore().getString(objectId);

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
