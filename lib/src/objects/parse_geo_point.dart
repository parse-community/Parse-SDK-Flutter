part of flutter_parse_sdk;

const String keyLatitude = 'latitude';
const String keyLongitude = 'longitude';

class ParseGeoPoint extends ParseObject {
  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint(
      {double latitude = 0.0,
      double longitude = 0.0,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyGeoPoint) {
    this.latitude = latitude;
    this.longitude = longitude;

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  double get latitude => super.get<double>(keyLatitude);
  set latitude(double latitude) => set<double>(keyLatitude, latitude);

  double get longitude => super.get<double>(keyLongitude);
  set longitude(double longitude) => set<double>(keyLongitude, longitude);

  @override
  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) =>
      <String, dynamic>{
        '__type': 'GeoPoint',
        'latitude': latitude,
        'longitude': longitude
      };
}
