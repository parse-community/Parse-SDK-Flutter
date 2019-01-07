part of flutter_parse_sdk;

class ParseGeoPoint extends ParseBase {
  final String className = 'GeoPoint';

  double _latitude;
  double _longitude;

  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint({double latitude = 0.0, double longitude = 0.0}):
        assert(latitude >= -90.0 || latitude <= 90.0),
        assert(longitude >= -180.0 || longitude <= 180.0) {
    _latitude = latitude;
    _longitude = longitude;
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