import 'package:http/http.dart' as http;
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseHTTPClient Tests', () {
    late ParseHTTPClient parseHTTPClient;

    setUp(() async {
      parseHTTPClient = ParseHTTPClient();
    });

    test('should return an instance of http.BaseClient from client getter', () {
      // arrange
      final httpClient = parseHTTPClient.client;

      // assert
      expect(httpClient, isNotNull);
      expect(httpClient, isA<http.BaseClient>());
    });
  });
}
