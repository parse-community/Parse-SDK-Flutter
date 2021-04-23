part of flutter_parse_sdk;

abstract class ParseBase {
  String parseClassName = 'ParseBase';
  final bool _dirty = false; // reserved property
  final Map<String, dynamic> _unsavedChanges = Map<String, dynamic>();
  final Map<String, dynamic> _savingChanges = Map<String, dynamic>();

  /// Stores all the values of a class
  Map<String, dynamic> _objectData = Map<String, dynamic>();

  /// Returns [String] objectId
  String? get objectId => get<String>(keyVarObjectId);

  set objectId(String? objectId) => set<String?>(keyVarObjectId, objectId);

  bool isDirty({String? key}) {
    if (key != null) {
      return _unsavedChanges[key] != null;
    }
    return _isDirty(true);
  }

  bool _isDirty(bool considerChildren) {
    if (_dirty || _unsavedChanges.isNotEmpty || objectId == null) {
      return true;
    }

    if (considerChildren) {
      return _areChildrenDirty(Set<dynamic>());
    }
    return false;
  }

  bool _areChildrenDirty(Set<dynamic> seenObjects) {
    if (seenObjects.contains(this)) {
      return false;
    }
    seenObjects.add(this);
    if (_dirty || _unsavedChanges.isNotEmpty) {
      return true;
    }
    bool match = false;
    _getObjectData().forEach((String key, dynamic value) {
      if (value is ParseObject && value._areChildrenDirty(seenObjects)) {
        match = true;
      }
    });
    return match;
  }

  /// Returns [DateTime] createdAt
  DateTime? get createdAt {
    if (get<dynamic>(keyVarCreatedAt) is String) {
      final String? dateAsString = get<String>(keyVarCreatedAt);
      return dateAsString != null ? _parseDateFormat.parse(dateAsString) : null;
    } else {
      return get<DateTime>(keyVarCreatedAt);
    }
  }

  /// Returns [DateTime] updatedAt
  DateTime? get updatedAt {
    if (get<dynamic>(keyVarUpdatedAt) is String) {
      final String? dateAsString = get<String>(keyVarUpdatedAt);
      return dateAsString != null ? _parseDateFormat.parse(dateAsString) : null;
    } else {
      return get<DateTime>(keyVarUpdatedAt);
    }
  }

  /// Converts object to [String] in JSON format
  @protected
  Map<String, dynamic> toJson({
    bool full = false,
    bool forApiRQ = false,
    bool allowCustomObjectId = false,
  }) {
    final Map<String, dynamic> map = <String, dynamic>{
      keyVarClassName: parseClassName,
    };

    if (objectId != null) {
      map[keyVarObjectId] = objectId;
    }

    if (createdAt != null) {
      map[keyVarCreatedAt] = _parseDateFormat.format(createdAt!);
    }

    if (updatedAt != null) {
      map[keyVarUpdatedAt] = _parseDateFormat.format(updatedAt!);
    }

    final Map<String, dynamic> target =
        forApiRQ ? _unsavedChanges : _getObjectData();
    target.forEach((String key, dynamic value) {
      if (!map.containsKey(key)) {
        map[key] = parseEncode(value, full: full);
      }
    });

    if (forApiRQ) {
      map.remove(keyVarCreatedAt);
      map.remove(keyVarUpdatedAt);
      map.remove(keyVarClassName);
      //map.remove(keyVarAcl);

      if (!allowCustomObjectId) {
        map.remove(keyVarObjectId);
      }
      map.remove(keyParamSessionToken);
    }

    return map;
  }

  @override
  String toString() => json.encode(toJson());

  dynamic fromJson(Map<String, dynamic> objectData) {
    objectData.forEach((String key, dynamic value) {
      if (key == parseClassName || key == '__type') {
        // NO OP
      } else if (key == keyVarObjectId) {
        _getObjectData()[keyVarObjectId] = value;
      } else if (key == keyVarCreatedAt) {
        if (keyVarCreatedAt is String) {
          _getObjectData()[keyVarCreatedAt] = _parseDateFormat.parse(value);
        } else {
          _getObjectData()[keyVarCreatedAt] = value;
        }
      } else if (key == keyVarUpdatedAt) {
        if (keyVarUpdatedAt is String) {
          _getObjectData()[keyVarUpdatedAt] = _parseDateFormat.parse(value);
        } else {
          _getObjectData()[keyVarUpdatedAt] = _parseDateFormat.parse(value);
        }
      } else if (key == keyVarAcl) {
        _getObjectData()[keyVarAcl] = ParseACL().fromJson(value);
      } else {
        _getObjectData()[key] = parseDecode(value);
      }
    });

    return this;
  }

  /// Creates a copy of this class
  @protected
  dynamic copy() => fromJson(toJson());

  /// Sets all the objects variables
  @protected
  void _setObjectData(Map<String, dynamic> objectData) =>
      _objectData = objectData;

  /// Returns the objects variables
  @protected
  Map<String, dynamic> _getObjectData() => _objectData;

  bool containsValue(Object value) {
    return _getObjectData().containsValue(value);
  }

  bool containsKey(String key) {
    return _getObjectData().containsKey(key);
  }

  dynamic operator [](String key) {
    return get<dynamic>(key);
  }

  void operator []=(String key, dynamic value) {
    set<dynamic>(key, value);
  }

  /// Saves in storage
  Future<void> saveInStorage(String key) async {
    final String objectJson = json.encode(toJson(full: true));
    await ParseCoreData().getStore().setString(key, objectJson);
  }

  void clearUnsavedChanges() {
    _unsavedChanges.clear();
  }

  /// Sets type [T] from objectData
  ///
  /// To set an int, call setType<int> and an int will be saved
  /// [bool] forceUpdate is always true, if unsure as to whether an item is
  /// needed or not, set to false
  void set<T>(String key, T value, {bool forceUpdate = true}) {
    if (_getObjectData().containsKey(key)) {
      if (_getObjectData()[key] == value && !forceUpdate) {
        return;
      }
      _getObjectData()[key] =
          ParseMergeTool().mergeWithPrevious(_unsavedChanges[key], value);
    } else {
      _getObjectData()[key] = value;
    }
    _unsavedChanges[key] = _getObjectData()[key];
  }

  /// Gets type [T] from objectData
  ///
  /// Returns null or [defaultValue] if provided. To get an int, call
  /// getType<int> and an int will be returned, null, or a defaultValue if
  /// provided
  T? get<T>(String key, {T? defaultValue}) {
    if (_getObjectData().containsKey(key)) {
      return _getObjectData()[key] as T?;
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
      final Map<String, dynamic>? objectMap = parseEncode(this, full: true);
      final String json = jsonEncode(objectMap);
      await ParseCoreData().getStore().setString(objectId!, json);
      return true;
    } else {
      return false;
    }
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  Future<bool> unpin({String? key}) async {
    if (objectId != null || key != null) {
      await ParseCoreData().getStore().remove(key ?? objectId!);
      return true;
    }

    return false;
  }

  /// Saves item to simple key pair value storage
  ///
  /// Replicates Android SDK pin process and saves object to storage
  dynamic fromPin(String objectId) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String? itemFromStore = await coreStore.getString(objectId);

    if (itemFromStore != null) {
      return fromJson(json.decode(itemFromStore));
    }
    return null;
  }

  Map<String, dynamic> toPointer() => encodeObject(parseClassName, objectId!);

  ///Set the [ParseACL] governing this object.
  void setACL<ParseACL>(ParseACL acl) {
    set(keyVarAcl, acl);
  }

  ///Access the [ParseACL] governing this object.
  ParseACL getACL() {
    if (_getObjectData().containsKey(keyVarAcl)) {
      return _getObjectData()[keyVarAcl];
    } else {
      return ParseACL();
    }
  }
}
