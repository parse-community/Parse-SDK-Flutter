part of flutter_parse_sdk;

/// Custom encoder for DateTime
dynamic dateTimeEncoder(dynamic item) {
  if (item is DateTime) {
    return _parseDateFormat.format(item);
  }
  return item;
}

/// Custom json encoder for types related to parse
dynamic parseEncode(dynamic value, {bool full = false}) {
  if (value is Uint8List) {
    return _encodeUint8List(value);
  }

  if (value is DateTime) {
    return _encodeDate(value);
  }

  if (value is Iterable) {
    return value.map<dynamic>((dynamic value) {
      return parseEncode(value, full: full);
    }).toList();
  }

  if (value is _ParseArray) {
    return value.toJson(full: full);
  }

  if (value is _ParseNumber) {
    return value.toJson(full: full);
  }

  if (value is _ParseOperation) {
    return value.toJson(full: full);
  }

  if (value is Map) {
    value.forEach((dynamic k, dynamic v) {
      value[k] = parseEncode(v, full: full);
    });
  }

  if (value is ParseGeoPoint) {
    return value.toJson(full: full);
  }

  if (value is ParseFileBase) {
    return value.toJson(full: full);
  }

  if (value is ParseRelation) {
    return value.toJson(full: full);
  }

  if (value is ParseObject) {
    if (full) {
      return value.toJson(full: full);
    } else {
      return value.toPointer();
    }
  }

  if (value is ParseACL) {
    return value.toJson();
  }

  return value;
}

Map<String, dynamic> _encodeUint8List(Uint8List value) {
  return <String, dynamic>{'__type': 'Bytes', 'base64': base64.encode(value)};
}

Map<String, dynamic> _encodeDate(DateTime date) {
  return <String, dynamic>{
    '__type': 'Date',
    'iso': _parseDateFormat.format(date)
  };
}

Map<String, String> encodeObject(String className, String objectId) {
  return <String, String>{
    '__type': 'Pointer',
    keyVarClassName: className,
    keyVarObjectId: objectId
  };
}
