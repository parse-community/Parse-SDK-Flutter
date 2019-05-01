part of flutter_parse_sdk;

abstract class ParseBase {
  String className;
  Type type;

  String setClassName(String className) => this.className = className;

  String getClassName() => className;

  /// Stores all the values of a class
  Map<String, dynamic> _objectData = Map<String, dynamic>();

  /// Returns [String] objectId
  String get objectId => get<String>(keyVarObjectId);

  set objectId(String objectId) => set<String>(keyVarObjectId, objectId);

  /// Returns [DateTime] createdAt
  DateTime get createdAt {
    if (get<dynamic>(keyVarCreatedAt) is String) {
      final String dateAsString = get<String>(keyVarCreatedAt);
      return _parseDateFormat.parse(dateAsString);
    } else {
      return get<DateTime>(keyVarCreatedAt);
    }
  }

  /// Returns [DateTime] updatedAt
  DateTime get updatedAt {
    if (get<dynamic>(keyVarUpdatedAt) is String) {
      final String dateAsString = get<String>(keyVarUpdatedAt);
      return _parseDateFormat.parse(dateAsString);
    } else {
      return get<DateTime>(keyVarUpdatedAt);
    }
  }

  /// Converts object to [String] in JSON format
  @protected
  Map<String, dynamic> toJson({bool full, bool forApiRQ = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyVarClassName: className,
    };

    if (objectId != null) {
      map[keyVarObjectId] = objectId;
    }

    if (createdAt != null) {
      map[keyVarCreatedAt] = _parseDateFormat.format(createdAt);
    }

    if (updatedAt != null) {
      map[keyVarUpdatedAt] = _parseDateFormat.format(updatedAt);
    }

    getObjectData().forEach((String key, dynamic value) {
      if (!map.containsKey(key)) {
        map[key] = parseEncode(value, full: full);
      }
    });

    if (forApiRQ) {
      map.remove(keyVarCreatedAt);
      map.remove(keyVarUpdatedAt);
      map.remove(keyVarClassName);
      //map.remove(keyVarAcl);
      map.remove(keyParamSessionToken);
    }

    return map;
  }

  @override
  String toString() => json.encode(toJson());

  dynamic fromJson(Map<String, dynamic> objectData) {
    if (objectData == null) {
      return this;
    }

    objectData.forEach((String key, dynamic value) {
      if (key == className || key == '__type') {
        // NO OP
      } else if (key == keyVarObjectId) {
        objectId = value;
      } else if (key == keyVarCreatedAt) {
        if (keyVarCreatedAt is String) {
          set<DateTime>(keyVarCreatedAt, _parseDateFormat.parse(value));
        } else {
          set<DateTime>(keyVarCreatedAt, value);
        }
      } else if (key == keyVarUpdatedAt) {
        if (keyVarUpdatedAt is String) {
          set<DateTime>(keyVarUpdatedAt, _parseDateFormat.parse(value));
        } else {
          set<DateTime>(keyVarUpdatedAt, value);
        }
      } else if (key == keyVarAcl) {
        getObjectData()[keyVarAcl] = ParseACL().fromJson(value);
      } else {
        getObjectData()[key] = parseDecode(value);
      }
    });

    return this;
  }

  /// Creates a copy of this class
  @protected
  dynamic copy() => fromJson(toJson());

  /// Sets all the objects variables
  @protected
  void setObjectData(Map<String, dynamic> objectData) =>
      _objectData = objectData;

  /// Returns the objects variables
  @protected
  Map<String, dynamic> getObjectData() => _objectData ?? Map<String, dynamic>();

  /// Saves in storage
  Future<void> saveInStorage(String key) async {
    final String objectJson = json.encode(toJson(full: true));
    await ParseCoreData().getStore()
      ..setString(key, objectJson);
  }

  /// Sets type [T] from objectData
  ///
  /// To set an int, call setType<int> and an int will be saved
  /// [bool] forceUpdate is always true, if unsure as to whether an item is
  /// needed or not, set to false
  void set<T>(String key, T value, {bool forceUpdate = true}) {
    if (value != null) {
      if (getObjectData().containsKey(key)) {
        if (forceUpdate) {
          getObjectData()[key] = value;
        }
      } else {
        getObjectData()[key] = value;
      }
    }
  }

  ///Set the [ParseACL] governing this object.
  void setACL<ParseACL>(ParseACL acl) {
    getObjectData()[keyVarAcl] = acl;
  }

  ///Access the [ParseACL] governing this object.
  ParseACL getACL() {
    if (getObjectData().containsKey(keyVarAcl)) {
      return getObjectData()[keyVarAcl];
    } else {
      return ParseACL();
    }
  }

  /// Gets type [T] from objectData
  ///
  /// Returns null or [defaultValue] if provided. To get an int, call
  /// getType<int> and an int will be returned, null, or a defaultValue if
  /// provided
  dynamic get<T>(String key, {T defaultValue}) {
    if (getObjectData().containsKey(key)) {
      if (T != null && getObjectData()[key] is T) {
        final T data = getObjectData()[key];
        return data;
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
      final Map<String, dynamic> objectMap = parseEncode(this, full: true);
      final String json = jsonEncode(objectMap);
      await ParseCoreData().getStore()
        ..setString(objectId, json);
      return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  Future<bool> unpin({String key}) async {
    if (objectId != null) {
      await ParseCoreData().getStore()
        ..remove(key ?? objectId);
      return true;
    }

    return false;
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  dynamic fromPin(String objectId) async {
    if (objectId != null) {
      final CoreStore coreStore = await ParseCoreData().getStore();
      final String itemFromStore = await coreStore.getString(objectId);

      if (itemFromStore != null) {
        return fromJson(json.decode(itemFromStore));
      }
    }
    return null;
  }

  Map<String, dynamic> toPointer() => encodeObject(className, objectId);
}
