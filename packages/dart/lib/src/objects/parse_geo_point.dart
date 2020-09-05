part of flutter_parse_sdk;

const String keyLatitude = 'latitude';
const String keyLongitude = 'longitude';

class ParseGeoPoint {
  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint({this.latitude = 0.0, this.longitude = 0.0});

  double latitude, longitude;

  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) =>
      <String, dynamic>{
        '__type': 'GeoPoint',
        'latitude': latitude,
        'longitude': longitude
      };
}
