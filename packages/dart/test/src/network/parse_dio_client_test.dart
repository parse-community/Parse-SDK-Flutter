import 'package:dio/dio.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseDioClient Tests', () {
    late ParseDioClient parseDioClient;

    setUp(() async {
      parseDioClient = ParseDioClient();
    });

    test('should return an instance of Dio from dioClient', () {
      // arrange
      final dioClient = parseDioClient.client;

      // assert
      expect(dioClient, isNotNull);
      expect(dioClient, isA<Dio>());
    });

    test('additionalHeaders should be null by default', () {
      expect(parseDioClient.additionalHeaders, isNull);
    });

    test('should set and get additionalHeaders', () {
      // arrange
      final headers = {'X-Custom-Header': 'test-value', 'X-Another': 'value2'};

      // act
      parseDioClient.additionalHeaders = headers;

      // assert
      expect(parseDioClient.additionalHeaders, equals(headers));
      expect(
        parseDioClient.additionalHeaders!['X-Custom-Header'],
        'test-value',
      );
      expect(parseDioClient.additionalHeaders!['X-Another'], 'value2');
    });

    test('should allow clearing additionalHeaders by setting to null', () {
      // arrange
      parseDioClient.additionalHeaders = {'X-Header': 'value'};
      expect(parseDioClient.additionalHeaders, isNotNull);

      // act
      parseDioClient.additionalHeaders = null;

      // assert
      expect(parseDioClient.additionalHeaders, isNull);
    });
  });
}
