part of flutter_parse_sdk;

class ParseGeoPoint extends ParseObject {

  /// Creates a Parse Object of type GeoPoint
  ParseGeoPoint(
      {double latitude = 0.0,
      double longitude = 0.0,
      bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyGeoPoint) {

    latitude = latitude;
    longitude = longitude;

    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  double latitude;
  double longitude;

  @override
  Map<String, dynamic> toJson({bool full = false, bool forApiRQ = false}) => <String, dynamic>{
        '__type': 'GeoPoint',
        'latitude': latitude,
        'longitude': longitude
      };
}
