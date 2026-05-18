import 'dart:async';
import 'dart:io';

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

  /// Verifies headers returned by `buildHeaders` reach the wire through each
  /// HTTP verb. ParseHTTPClient has no in-process injection seam for its
  /// underlying http.Client, so the test spins up a localhost HttpServer that
  /// captures the request headers and replies with a minimal 200 response.
  group('ParseHTTPClient request pipeline integration', () {
    late ParseHTTPClient parseHTTPClient;
    late HttpServer server;
    late List<HttpRequest> captured;
    late String baseUrl;

    setUp(() async {
      parseHTTPClient = ParseHTTPClient();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'http://${server.address.host}:${server.port}';
      captured = <HttpRequest>[];
      server.listen((HttpRequest request) async {
        captured.add(request);
        // Drain any body so the client receives a complete response.
        await request.drain<void>();
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    String headerOf(HttpRequest request, String name) =>
        request.headers.value(name) ?? '';

    test('get() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.get('$baseUrl/classes/Item/abc');

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('getBytes() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.getBytes('$baseUrl/files/abc.bin');

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('put() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.put('$baseUrl/classes/Item/abc', data: '{}');

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('post() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.post('$baseUrl/classes/Item', data: '{"k":"v"}');

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('postBytes() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.postBytes(
        '$baseUrl/files/abc.bin',
        data: Stream<List<int>>.fromIterable(<List<int>>[
          <int>[1, 2, 3],
        ]),
      );

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('delete() attaches X-Parse-Installation-Id', () async {
      await parseHTTPClient.delete('$baseUrl/classes/Item/abc');

      expect(captured, hasLength(1));
      expect(headerOf(captured.first, keyHeaderInstallationId), isNotEmpty);
    });

    test('caller can suppress X-Parse-Installation-Id per request. '
        'sendInstallationId: false matches ParseUser.signUp(doNotSendInstallationID: true) '
        'and must propagate through every verb', () async {
      await parseHTTPClient.post(
        '$baseUrl/classes/Item',
        data: '{"k":"v"}',
        options: ParseNetworkOptions(sendInstallationId: false),
      );

      expect(captured, hasLength(1));
      expect(
        captured.first.headers.value(keyHeaderInstallationId),
        isNull,
        reason:
            'sendInstallationId: false must suppress the header on the wire',
      );
    });
  });
}
