import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

/// Minimal concrete subclass for exercising methods on the abstract
/// [ParseClient]. All HTTP methods throw — the test suite only targets the
/// inherited helpers (`buildHeaders`) and never dispatches a real request.
class _StubParseClient extends ParseClient {
  @override
  Future<ParseNetworkResponse> get(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
  }) => throw UnimplementedError();

  @override
  Future<ParseNetworkResponse> put(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  }) => throw UnimplementedError();

  @override
  Future<ParseNetworkResponse> post(
    String path, {
    String? data,
    ParseNetworkOptions? options,
  }) => throw UnimplementedError();

  @override
  Future<ParseNetworkResponse> postBytes(
    String path, {
    Stream<List<int>>? data,
    ParseNetworkOptions? options,
    ProgressCallback? onSendProgress,
    dynamic cancelToken,
  }) => throw UnimplementedError();

  @override
  Future<ParseNetworkResponse> delete(
    String path, {
    ParseNetworkOptions? options,
  }) => throw UnimplementedError();

  @override
  Future<ParseNetworkByteResponse> getBytes(
    String path, {
    ParseNetworkOptions? options,
    ProgressCallback? onReceiveProgress,
    dynamic cancelToken,
  }) => throw UnimplementedError();

  // Exposes the protected helper so tests can call it without subclass tricks.
  Future<Map<String, String>?> exposedBuildHeaders(
    ParseNetworkOptions? options,
  ) => buildHeaders(options);
}

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseClient.buildHeaders — X-Parse-Installation-Id handling', () {
    late _StubParseClient client;

    setUp(() {
      client = _StubParseClient();
    });

    test(
      'attaches X-Parse-Installation-Id by default. Matches iOS '
      'PFURLSessionCommandRunner behaviour — every request carries the '
      'install ID so parse-server can bind created _Session rows to the '
      'right installation and so destroyDuplicatedSessions can clean up '
      'prior sessions on the same install during login',
      () async {
        final Map<String, String>? headers = await client.exposedBuildHeaders(
          null,
        );

        expect(headers, isNotNull);
        expect(headers![keyHeaderInstallationId], isNotEmpty);
      },
    );

    test(
      'omits X-Parse-Installation-Id when caller passes '
      'sendInstallationId: false. The opt-out is forwarded by methods such '
      'as ParseUser.signUp(doNotSendInstallationID: true) for callers that '
      'cannot allow-list the header on their parse-server',
      () async {
        final Map<String, String>? headers = await client.exposedBuildHeaders(
          ParseNetworkOptions(sendInstallationId: false),
        );

        expect(
          headers?[keyHeaderInstallationId],
          isNull,
          reason:
              'sendInstallationId=false must suppress the header even when '
              'an install ID is available',
        );
      },
    );

    test(
      'preserves a caller-supplied X-Parse-Installation-Id rather than '
      'overwriting it. Lets advanced callers (tests, multi-tenant proxies) '
      'inject a specific install ID without the client clobbering it',
      () async {
        final Map<String, String>? headers = await client.exposedBuildHeaders(
          ParseNetworkOptions(
            headers: <String, String>{keyHeaderInstallationId: 'caller-id'},
          ),
        );

        expect(headers![keyHeaderInstallationId], equals('caller-id'));
      },
    );

    test(
      'merges caller-supplied headers with the install ID. Custom headers '
      'and the auto-attached install ID must coexist — neither side '
      'overrides the other',
      () async {
        final Map<String, String>? headers = await client.exposedBuildHeaders(
          ParseNetworkOptions(
            headers: <String, String>{'X-Custom': 'value'},
          ),
        );

        expect(headers!['X-Custom'], equals('value'));
        expect(headers[keyHeaderInstallationId], isNotEmpty);
      },
    );
  });
}
