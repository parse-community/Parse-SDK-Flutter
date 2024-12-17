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
      final dioClient = parseDioClient.dioClient;

      // assert
      expect(dioClient, isNotNull);
      expect(dioClient, isA<Dio>());
    });
  });
}
