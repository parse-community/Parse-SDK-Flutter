import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseGeoPoint', () {
    group('constructor validation', () {
      test('should create a valid GeoPoint with default values', () {
        final geoPoint = ParseGeoPoint();
        expect(geoPoint.latitude, equals(0.0));
        expect(geoPoint.longitude, equals(0.0));
      });

      test('should create a valid GeoPoint with valid coordinates', () {
        final geoPoint = ParseGeoPoint(latitude: 40.0, longitude: -74.0);
        expect(geoPoint.latitude, equals(40.0));
        expect(geoPoint.longitude, equals(-74.0));
      });

      test('should create a valid GeoPoint with edge case values', () {
        // Test boundary values that should be valid (exclusive bounds)
        final geoPoint1 = ParseGeoPoint(latitude: 89.999, longitude: 179.999);
        expect(geoPoint1.latitude, equals(89.999));
        expect(geoPoint1.longitude, equals(179.999));

        final geoPoint2 = ParseGeoPoint(latitude: -89.999, longitude: -179.999);
        expect(geoPoint2.latitude, equals(-89.999));
        expect(geoPoint2.longitude, equals(-179.999));
      });

      test('should throw assertion error for latitude >= 90', () {
        expect(
          () => ParseGeoPoint(latitude: 90.0, longitude: 0.0),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => ParseGeoPoint(latitude: 100.0, longitude: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw assertion error for latitude <= -90', () {
        expect(
          () => ParseGeoPoint(latitude: -90.0, longitude: 0.0),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => ParseGeoPoint(latitude: -100.0, longitude: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw assertion error for longitude >= 180', () {
        expect(
          () => ParseGeoPoint(latitude: 0.0, longitude: 180.0),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => ParseGeoPoint(latitude: 0.0, longitude: 200.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw assertion error for longitude <= -180', () {
        expect(
          () => ParseGeoPoint(latitude: 0.0, longitude: -180.0),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => ParseGeoPoint(latitude: 0.0, longitude: -200.0),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('toJson', () {
      test('should return correct JSON representation', () {
        final geoPoint = ParseGeoPoint(latitude: 40.0, longitude: -74.0);
        final json = geoPoint.toJson();

        expect(json['__type'], equals('GeoPoint'));
        expect(json['latitude'], equals(40.0));
        expect(json['longitude'], equals(-74.0));
      });
    });

    group('toString', () {
      test('should return correct string representation', () {
        final geoPoint = ParseGeoPoint(latitude: 40.0, longitude: -74.0);
        expect(geoPoint.toString(), equals('latitude: 40.0, longitude: -74.0'));
      });
    });
  });
}
