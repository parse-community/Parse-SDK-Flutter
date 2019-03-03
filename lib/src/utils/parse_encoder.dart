part of flutter_parse_sdk;

/// Custom encoder for DateTime
dynamic dateTimeEncoder(dynamic item) {
  if (item is DateTime) {
    return item.toIso8601String();
  }
  return item;
}

/// Custom json encoder for types related to parse
dynamic parseEncode(dynamic value, {bool full = false}) {
  if (value is DateTime) return _encodeDate(value);

  if (value is List) {
    return value.map((v) {
      return parseEncode(v);
    }).toList();
  }

  if (value is ParseObject) {
    if (full) {
      return value.toJson(full: full);
    } else {
      return _encodeObject(value);
    }
  }

  if (value is ParseUser) {
    return value.toJson();
  }

  if (value is ParseGeoPoint) {
    return value.toJson;
  }

  if (value is ParseFile) {
    return value.toJson;
  }

  if (value is Uint8List) {
    return _encodeUint8List(value);
  }

  return value;
}

String _encodeUint8List(Uint8List value) {
  return "{\"__type\": \"Bytes\", \"base64\": \"${base64.encode(value)}\"}";
}

String _encodeObject(ParseObject object) {
  return "{\"__type\": \"Pointer\", \"$keyVarClassName\": \"${object.className}\", \"$keyVarObjectId\": \"${object.objectId}\"}";
}

String _encodeDate(DateTime date) {
  return "{\"__type\": \"Date\", \"iso\": \"${date.toIso8601String()}\"}";
}
