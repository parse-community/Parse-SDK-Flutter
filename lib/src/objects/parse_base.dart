part of flutter_parse_sdk;

abstract class ParseBase {
  String className;
  Type type;

  setClassName(String className) => this.className = className;

  String getClassName() => className;

  /// Stores all the values of a class
  Map _objectData = Map<String, dynamic>();

  /// Returns [String] objectId
  String get objectId => get<String>(keyVarObjectId);

  set objectId(String objectId) => set<String>(keyVarObjectId, objectId);

  /// Returns [DateTime] createdAt
  DateTime get createdAt => get<DateTime>(keyVarCreatedAt);

  /// Returns [DateTime] updatedAt
  DateTime get updatedAt => get<DateTime>(keyVarUpdatedAt);

  /// Converts object to [String] in JSON format
  @protected
  toJson({bool forApiRQ: false}) {
    final map = <String, dynamic>{
      keyVarClassName: className,
    };

    if (objectId != null) {
      map[keyVarObjectId] = objectId;
    }

    if (createdAt != null) {
      map[keyVarCreatedAt] = createdAt.toIso8601String();
    }

    if (updatedAt != null) {
      map[keyVarUpdatedAt] = updatedAt.toIso8601String();
    }

    getObjectData().forEach((key, value) {
      if (!map.containsKey(key)) map[key] = parseEncode(value);
    });

    if (forApiRQ) {
      map.remove(keyVarCreatedAt);
      map.remove(keyVarUpdatedAt);
      map.remove(keyVarClassName);
      map.remove(keyVarAcl);
      map.remove(keyParamSessionToken);
    }

    return map;
  }

  @override
  String toString() => json.encode(toJson());

  @protected
  fromJson(Map objectData) {
    objectData.forEach((key, value) {
      if (key == className || key == '__type') {
        // NO OP
      } else if (key == keyVarObjectId) {
        objectId = value;
      } else if (key == keyVarCreatedAt) {
        set<DateTime>(keyVarCreatedAt, DateTime.parse(value));
      } else if (key == keyVarUpdatedAt) {
        set<DateTime>(keyVarUpdatedAt, DateTime.parse(value));
      } else {
        getObjectData()[key] = parseDecode(value);
      }
    });

    return this;
  }

  /// Creates a copy of this class
  @protected
  copy() => fromJson(json.decode(toJson()));

  /// Sets all the objects variables
  @protected
  void setObjectData(Map objectData) => _objectData = objectData;

  /// Returns the objects variables
  @protected
  Map getObjectData() => _objectData != null ? _objectData : Map();

  /// Saves in storage
  @protected
  void saveInStorage(String key) async {
    await ParseCoreData().getStore()
      ..setString(key, toString());
  }

  /// Sets type [T] from objectData
  ///
  /// To set an int, call setType<int> and an int will be saved
  /// [bool] forceUpdate is always true, if unsure as to whether an item is
  /// needed or not, set to false
  void set<T>(String key, T value, {bool forceUpdate: true}) {
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
  Future<bool> pin() async {
    if (objectId != null) {
      await unpin();
      var objectToSave = json.encode(toJson());
      await ParseCoreData().getStore()
        ..setString(objectId, objectToSave);
      return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  Future<bool> unpin() async {
    if (objectId != null) {
      await SharedPreferences.getInstance()
        ..remove(objectId);
      return true;
    }

    return false;
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  fromPin(String objectId) async {
    if (objectId != null) {
      var itemFromStore =
          (await ParseCoreData().getStore()).getString(objectId);

      if (itemFromStore != null) {
        var map = json.decode(itemFromStore);

        if (map != null) {
          return fromJson(map);
        }
      }
    }
    return null;
  }
}
