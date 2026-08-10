import 'package:universal_io/io.dart';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../parse_query_test.mocks.dart';

/// Sync needs Parse initialised with a client we control, so it lives in its
/// own file — `dart test` runs each file in a separate isolate, and Parse is a
/// singleton that only initialises once.
void main() {
  const className = 'SyncTestClass';
  late MockParseClient client;

  setUpAll(() async {
    client = MockParseClient();
    await Parse().initialize(
      'appId',
      'https://example.com',
      debug: false,
      fileDirectory: 'someDirectory',
      appName: 'appName',
      appPackageName: 'somePackageName',
      appVersion: 'someAppVersion',
      clientCreator:
          ({required bool sendSessionId, SecurityContext? securityContext}) =>
              client,
    );
  });

  setUp(() async {
    reset(client);
    await ParseObjectOffline.clearLocalCacheForClass(className);
  });

  tearDown(() async {
    await ParseObjectOffline.clearLocalCacheForClass(className);
  });

  group('syncLocalCacheWithServer', () {
    test('actually issues an update for each cached object', () async {
      // A cache-loaded object is rebuilt from JSON. If it is rebuilt with
      // `fromJson`, nothing is registered as an unsaved change, so `save()`
      // sees `_isDirty(false) == false`, never calls `update()`, and still
      // returns success from `_saveChildren`. Sync would then report every
      // object as synced while sending nothing at all.
      await (ParseObject(className)
            ..objectId = 'sync1'
            ..set('name', 'edited offline'))
          .saveToLocalCache();

      when(
        client.put(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: '{"updatedAt":"2026-08-10T12:00:00.000Z"}',
        ),
      );

      final result = await ParseObjectOffline.syncLocalCacheWithServer(
        className,
      );

      // The request must have gone out...
      final verification = verify(
        client.put(
          captureAny,
          data: captureAnyNamed('data'),
          options: anyNamed('options'),
        ),
      );
      verification.called(1);
      final String path = verification.captured[0] as String;
      final String body = verification.captured[1] as String;
      expect(path, contains('sync1'));
      expect(body, contains('edited offline'));

      // ...and only then is it reported as synced.
      expect(result.synced, equals(1));
      expect(result.hasFailures, isFalse);
    });

    test('reports a failed save instead of counting it as synced', () async {
      await (ParseObject(className)
            ..objectId = 'sync2'
            ..set('name', 'will fail'))
          .saveToLocalCache();

      when(
        client.put(any, data: anyNamed('data'), options: anyNamed('options')),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 400,
          data: '{"code":101,"error":"Object not found"}',
        ),
      );

      final result = await ParseObjectOffline.syncLocalCacheWithServer(
        className,
      );

      expect(result.synced, equals(0));
      expect(result.hasFailures, isTrue);
      expect(result.failures, hasLength(1));
      expect(result.failures.first.object.objectId, equals('sync2'));
    });

    test('shouldSync skips without sending', () async {
      await (ParseObject(className)..objectId = 'sync3').saveToLocalCache();

      final result = await ParseObjectOffline.syncLocalCacheWithServer(
        className,
        shouldSync: (_) => false,
      );

      verifyNever(
        client.put(any, data: anyNamed('data'), options: anyNamed('options')),
      );
      expect(result.skipped, equals(1));
      expect(result.synced, equals(0));
    });
  });
}
