part of '../../parse_server_sdk.dart';

const String keyLatitude = 'latitude';
const String keyLongitude = 'longitude';

class ParseGeoPoint {
  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint({this.latitude = 0.0, this.longitude = 0.0})
      : assert(
            latitude < 90, 'Latitude must be within the range (-90.0, 90.0).'),
        assert(
            latitude > -90, 'Latitude must be within the range (-90.0, 90.0).'),
        assert(latitude < 180,
            'Longitude must be within the range (-180.0, 180.0).'),
        assert(latitude > -180,
            'Longitude must be within the range (-180.0, 180.0).');

  double latitude, longitude;

  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) =>
      <String, dynamic>{
        '__type': 'GeoPoint',
        'latitude': latitude,
        'longitude': longitude
      };

  @override
  String toString() {
    return 'latitude: $latitude, longitude: $longitude';
  }
}
