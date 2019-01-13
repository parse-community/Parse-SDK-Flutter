part of flutter_parse_sdk;

/// Custom encoder for DateTime
dynamic dateTimeEncoder(dynamic item) {
  if(item is DateTime) {
    return item.toIso8601String();
  }
  return item;
}

bool isValidType(dynamic value) {
  return value == null ||
      value is String ||
      value is num ||
      value is bool ||
      value is DateTime ||
      value is List ||
      value is Map ||
      value is ParseObject ||
      value is ParseGeoPoint ||
      value is ParseUser;
}

/// Custom json encoder for types related to parse
dynamic parseEncode(dynamic value) {
  if (value is DateTime) return _encodeDate(value);

  if (value is List) {
    return value.map((v) {
      return parseEncode(v);
    }).toList();
  }

  if (value is ParseObject) {
    return _encodeObject(value);
  }

  if (value is ParseUser) {
    return value.toJson();
  }

  if (value is ParseGeoPoint) {
    return value.toJson;
  }

  return value;
}

String _encodeObject(ParseObject object){
  return "{'__type': 'Pointer', $keyVarClassName: ${object.className}, $keyVarObjectId: ${object.objectId}}";
}

Map<String, dynamic> _encodeDate(DateTime date) {
  return <String, dynamic>{"__type": "Date", "iso": date.toIso8601String()};
}
