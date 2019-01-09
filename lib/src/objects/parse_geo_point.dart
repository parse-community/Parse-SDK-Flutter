part of flutter_parse_sdk;

class ParseGeoPoint extends ParseObject {

  double _latitude;
  double _longitude;

  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint({double latitude = 0.0, double longitude = 0.0, bool debug, ParseHTTPClient client}): super ('GeoPoint') {
    _latitude = latitude;
    _longitude = longitude;

    if (debug != null) setDebug(debug);
    if (client != null) setClient(client);
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
}