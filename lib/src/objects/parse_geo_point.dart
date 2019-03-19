part of flutter_parse_sdk;

class ParseGeoPoint extends ParseObject {
  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint(
      {this.latitude = 0.0,
      this.longitude = 0.0,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyGeoPoint) {

    _debug = isDebugEnabled(providedDebugStatus: debug);
    _client = getDefaultHttpClient(client, autoSendSessionId);
  }

  double latitude;
  double longitude;

  @override

  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) =>
      <String, dynamic>{
        '__type': 'GeoPoint',
        'latitude': latitude,
        'longitude': longitude
      };
}
