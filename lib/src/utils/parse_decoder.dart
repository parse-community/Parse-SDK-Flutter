part of flutter_parse_sdk;

List<dynamic> _convertJSONArrayToList(List<dynamic> array) {
  final List<dynamic> list = <dynamic>[];
  for (final dynamic item in array) {
    list.add(parseDecode(item));
  }
  return list;
}

Map<String, dynamic> _convertJSONObjectToMap(Map<String, dynamic> object) {
  final Map<String, dynamic> map = Map<String, dynamic>();
  object.forEach((String key, dynamic value) {
    map.putIfAbsent(key, () => parseDecode(value));
  });
  return map;
}

/// Decode any type value
dynamic parseDecode(dynamic value) {
  if (value is List) {
    return _convertJSONArrayToList(value);
  }

  if (value is bool) {
    return value;
  }

  if (value is int) {
    return value.toInt();
  }

  if (value is double) {
    return value.toDouble();
  }

  if (value is num) {
    return value;
  }

  if (!(value is Map)) {
    return value;
  }

  final Map<String, dynamic> map = value;

  if (!map.containsKey('__type') && !map.containsKey('className')) {
    return _convertJSONObjectToMap(map);
  }

  /// Decoding from Api Response
  if (map.containsKey('__type')) {
    switch (map['__type']) {
      case 'Date':
        final String iso = map['iso'];
        return _parseDateFormat.parse(iso);
      case 'Bytes':
        final String val = map['base64'];
        return base64.decode(val);
      case 'Pointer':
      case 'Object':
        final String className = map['className'];
        return ParseCoreData.instance.createObject(className).fromJson(map);
      case 'File':
        return ParseCoreData.instance
            .createFile(url: map['url'], name: map['name'])
            .fromJson(map);
      case 'GeoPoint':
        final num latitude = map['latitude'] ?? 0.0;
        final num longitude = map['longitude'] ?? 0.0;
        return ParseGeoPoint(
            latitude: latitude.toDouble(), longitude: longitude.toDouble());
      case 'Relation':
        // ignore: always_specify_types
        return ParseRelation().fromJson(map);
    }
  }

  /// Decoding from locally cached JSON
  if (map.containsKey('className')) {
    switch (map['className']) {
      case 'GeoPoint':
        final num latitude = map['latitude'] ?? 0.0;
        final num longitude = map['longitude'] ?? 0.0;
        return ParseGeoPoint(
            latitude: latitude.toDouble(), longitude: longitude.toDouble());
      default:
        return ParseCoreData.instance
            .createObject(map['className'])
            .fromJson(map);
    }
  }

  return null;
}
