part of flutter_parse_sdk;

class ParseGeoPoint extends ParseObject {
  double _latitude;
  double _longitude;

  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint(
      {double latitude = 0.0,
      double longitude = 0.0,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyGeoPoint) {
    _latitude = latitude;
    _longitude = longitude;

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  double get latitude => _latitude;

  double get longitude => _longitude;

  set latitude(double value) {
    assert(value >= -90.0 || value <= 90.0);
    _latitude = value;
  }

  set longitude(double value) {
    assert(value >= -180.0 || value <= 180.0);
    _longitude = value;
  }

  @override
  toJson({bool full: false, bool forApiRQ: false}) => <String, dynamic>{
        "__type": "GeoPoint",
        "latitude": _latitude,
        "longitude": _longitude
      };
}
