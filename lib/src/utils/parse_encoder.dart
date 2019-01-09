part of flutter_parse_sdk;

class ParseEncoder {

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
  dynamic encode(dynamic value) {
    if (value is DateTime) return _encodeDate(value);

    if (value is List) {
      return value.map((v){
        return encode(v);
      }).toList();
    }

    if (value is ParseObject) {
      return value.toJson;
    }

    if (value is ParseUser) {
      return value.toJson;
    }

    if (value is ParseGeoPoint) {
      return value.toJson;
    }

    return value;
  }

  Map<String, dynamic> _encodeDate(DateTime date) {
    return <String, dynamic>{
      "__type": "Date",
      "iso": dateTimeToString(date)
    };
  }
}