import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseUser save()/update() — sessionToken adoption from response', () {
    late MockParseClient client;

    const String userObjectId = 'sess123';
    final String putPath = Uri.parse(
      '$serverUrl$keyEndPointClasses$keyClassUser/$userObjectId',
    ).toString();

    setUp(() async {
      client = MockParseClient();
      await ParseCoreData().getStore().remove(keyParseStoreUser);
    });

    /// Token adoption is gated on the saving instance being the stored
    /// current user (persist-only-current-user). These scenarios model the
    /// current user changing their own password, so storage must hold them.
    Future<void> seedAsStoredCurrentUser(ParseUser user) async {
      await ParseCoreData().getStore().setString(
        keyParseStoreUser,
        json.encode(user.toJson(full: true)),
      );
    }

    test('when a save() response carries a sessionToken different from the '
        'one sent, the SDK installs it as the global session token. Parse '
        'Server mints a fresh session when password is set on an existing '
        '_User; the prior session is destroyed server-side, so the global '
        'session must be updated or subsequent requests fail with '
        'invalidSessionToken', () async {
      ParseCoreData().setSessionId('r:priorSession');

      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: userObjectId,
        keyVarSessionToken: 'r:priorSession',
        keyVarUsername: 'alice@example.com',
      });

      when(
        client.put(
          putPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            keyVarSessionToken: 'r:freshSession',
          }),
        ),
      );

      await seedAsStoredCurrentUser(user);
      user.password = 'hunter2';

      final ParseResponse response = await user.save();

      expect(response.success, isTrue);
      expect(ParseCoreData().sessionId, equals('r:freshSession'));
    });

    test('when a save() response does NOT carry a sessionToken, the global '
        'session is left untouched. the previously-cached local sessionToken '
        'on the user object must not be re-promoted to global state', () async {
      ParseCoreData().setSessionId('r:stableSession');

      // The cached local token deliberately differs from the global one so
      // an incorrect re-promotion would be observable, and the user is
      // seeded as the stored current user so the save actually reaches the
      // adoption code path inside the current-user gate.
      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: userObjectId,
        keyVarSessionToken: 'r:cachedSession',
        keyVarUsername: 'alice@example.com',
      });
      await seedAsStoredCurrentUser(user);

      when(
        client.put(
          putPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
          }),
        ),
      );

      user.set<String>('localeIdentifier', 'en-US');

      await user.save();

      expect(ParseCoreData().sessionId, equals('r:stableSession'));
    });

    test('update() adopts a new sessionToken from the response. save() and '
        'update() are independent entry points, both need to install the '
        'token to keep the active session in sync with the server', () async {
      ParseCoreData().setSessionId('r:priorSession');

      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: userObjectId,
        keyVarSessionToken: 'r:priorSession',
        keyVarUsername: 'alice@example.com',
      });

      when(
        client.put(
          putPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            keyVarSessionToken: 'r:freshSession',
          }),
        ),
      );

      await seedAsStoredCurrentUser(user);
      user.password = 'hunter2';

      final ParseResponse response = await user.update();

      expect(response.success, isTrue);
      expect(ParseCoreData().sessionId, equals('r:freshSession'));
    });
  });
}
