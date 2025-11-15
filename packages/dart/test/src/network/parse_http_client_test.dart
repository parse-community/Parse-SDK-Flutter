import 'package:http/http.dart' as http;
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseDioClient Tests', () {
    late ParseHTTPClient parseHTTPClient;

    setUp(() async {
      parseHTTPClient = ParseHTTPClient();
    });

    test('should return an instance of Dio from dioClient', () {
      // arrange
      final dioClient = parseHTTPClient.client;

      // assert
      expect(dioClient, isNotNull);
      expect(dioClient, isA<http.BaseClient>());
    });
  });
}
