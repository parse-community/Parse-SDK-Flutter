part of '../../parse_server_sdk.dart';

abstract class ParseBase {
  /// refers to the Table Name in your Parse Server
  String parseClassName = 'ParseBase';
  final bool _dirty = false; // reserved property
  final Map<String, dynamic> _unsavedChanges = <String, dynamic>{};
  final Map<String, dynamic> _savingChanges = <String, dynamic>{};

  /// Stores all the values of a class
  Map<String, dynamic> _objectData = <String, dynamic>{};

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
      return _areChildrenDirty(<dynamic>{});
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

    final target = forApiRQ ? _unsavedChanges : _getObjectData();
    target.forEach((String key, dynamic value) {
      if (!map.containsKey(key)) {
        map[key] = parseEncode(value, full: full);
      }

      if (forApiRQ &&
          value is _ParseRelation &&
          !value.shouldIncludeInRequest()) {
        map.remove(key);
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
  String toString() => json.encode(toJson(full: true));

  dynamic fromJsonForManualObject(Map<String, dynamic> objectData) {
    return _fromJson(objectData, true);
  }

  dynamic fromJson(Map<String, dynamic> objectData) {
    return _fromJson(objectData, false);
  }

  dynamic _fromJson(Map<String, dynamic> objectData, bool addInUnSave) {
    objectData.forEach((String key, dynamic value) {
      if (key == parseClassName || key == '__type') {
        // NO OP
      } else if (key == keyVarObjectId) {
        _getObjectData()[keyVarObjectId] = value;
      } else if (key == keyVarCreatedAt) {
        if (value is String) {
          _getObjectData()[keyVarCreatedAt] = _parseDateFormat.parse(value);
        } else {
          _getObjectData()[keyVarCreatedAt] = value;
        }
      } else if (key == keyVarUpdatedAt) {
        if (value is String) {
          _getObjectData()[keyVarUpdatedAt] = _parseDateFormat.parse(value);
        } else {
          _getObjectData()[keyVarUpdatedAt] = value;
        }
      } else if (key == keyVarAcl) {
        _getObjectData()[keyVarAcl] = ParseACL().fromJson(value);
      } else {
        var decodedValue = parseDecode(value);

        if (decodedValue is List) {
          if (addInUnSave) {
            decodedValue = _ParseArray()..estimatedArray = decodedValue;
          } else {
            decodedValue = _ParseArray()..savedArray = decodedValue;
          }
        }

        if (decodedValue is num) {
          if (addInUnSave) {
            decodedValue = _ParseNumber(decodedValue);
          } else {
            decodedValue = _ParseNumber(decodedValue)
              ..savedNumber = decodedValue;
          }
        }

        _getObjectData()[key] = decodedValue;

        if (addInUnSave) {
          _unsavedChanges[key] = decodedValue;
        }
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
    for (final val in _getObjectData().values) {
      if (val == value || (val is _Valuable && val.getValue() == value)) {
        return true;
      }
    }

    return false;
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
    _notifyChildrenAboutClearUnsaved();
  }

  void _notifyChildrenAboutClearUnsaved() {
    for (final child in _getObjectData().values) {
      if (child is _ParseSaveStateAwareChild) {
        child.onClearUnsaved();
      }
    }
  }

  /// Add a key-value pair to this object.
  ///
  /// It is recommended to name keys in `camelCaseLikeThis`
  ///
  /// [bool] forceUpdate is always true, if unsure as to whether an item is
  /// needed or not, set to false
  void set<T>(String key, T value, {bool forceUpdate = true}) {
    if (_getObjectData()[key] == value && !forceUpdate) {
      return;
    }

    _getObjectData()[key] = _ParseOperation.maybeMergeWithPrevious<T>(
      newValue: value,
      previousValue: _getObjectData()[key],
      parent: this as ParseObject,
      key: key,
    );

    _unsavedChanges[key] = _getObjectData()[key];
  }

  /// Get a value of type [T] associated with a given [key]
  ///
  /// Returns null or [defaultValue] if provided.
  T? get<T>(String key, {T? defaultValue}) {
    if (_getObjectData().containsKey(key)) {
      final result = _getObjectData()[key];

      if (result is _Valuable) {
        return result.getValue() as T?;
      }

      if (result is _ParseRelation) {
        return (result
          ..parent = (this as ParseObject)
          ..key = key) as T?;
      }

      return result as T?;
    } else {
      return defaultValue;
    }
  }

  /// Saves item to value storage
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

  /// Remove item from value storage
  Future<bool> unpin({String? key}) async {
    if (objectId != null || key != null) {
      await ParseCoreData().getStore().remove(key ?? objectId!);
      return true;
    }

    return false;
  }

  /// Get item from value storage
  Future<dynamic> fromPin(String objectId) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String? itemFromStore = await coreStore.getString(objectId);

    if (itemFromStore != null) {
      return fromJson(json.decode(itemFromStore));
    }
    return null;
  }

  Map<String, dynamic> toPointer() => encodeObject(parseClassName, objectId!);

  /// Set the [ParseACL] governing this object.
  void setACL<ParseACL>(ParseACL acl) {
    set(keyVarAcl, acl);
  }

  /// Access the [ParseACL] governing this object.
  ParseACL getACL() {
    if (_getObjectData().containsKey(keyVarAcl)) {
      return _getObjectData()[keyVarAcl];
    } else {
      return ParseACL();
    }
  }
}
