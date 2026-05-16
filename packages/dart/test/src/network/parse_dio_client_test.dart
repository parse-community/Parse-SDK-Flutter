import 'package:dio/dio.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

/// Records the headers of every request made through it without performing
/// the actual HTTP call. Returns an empty 200 OK so callers can `await`.
class _HeaderCapturingAdapter implements HttpClientAdapter {
  final List<Map<String, dynamic>> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(Map<String, dynamic>.from(options.headers));
    return ResponseBody.fromString('{}', 200, headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

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

  group('ParseDioClient request pipeline integration', () {
    late ParseDioClient parseDioClient;
    late _HeaderCapturingAdapter adapter;

    setUp(() async {
      parseDioClient = ParseDioClient();
      adapter = _HeaderCapturingAdapter();
      parseDioClient.client.httpClientAdapter = adapter;
    });

    test(
      'headers returned by buildHeaders reach the outgoing request. This is '
      'the wiring check between the inherited helper (covered in detail by '
      'parse_client_test.dart) and dio\'s request pipeline — without it, a '
      'refactor that bypassed buildHeaders would silently drop install IDs '
      'on every request',
      () async {
        await parseDioClient.put('$serverUrl/classes/_User/abc', data: '{}');

        expect(adapter.requests, hasLength(1));
        expect(
          adapter.requests.first[keyHeaderInstallationId],
          isNotEmpty,
          reason: 'install ID added by buildHeaders must reach the wire',
        );
      },
    );
  });
}
