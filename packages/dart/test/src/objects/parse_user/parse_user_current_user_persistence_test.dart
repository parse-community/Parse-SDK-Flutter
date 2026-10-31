import 'dart:async';
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

  group('ParseUser — persist only the current user to local storage', () {
    late MockParseClient client;

    const String currentUserObjectId = 'userAAA';
    const String detachedUserObjectId = 'userBBB';

    final String mePath = Uri.parse(
      '$serverUrl$keyEndPointUserName',
    ).toString();
    final String detachedPutPath = Uri.parse(
      '$serverUrl$keyEndPointClasses$keyClassUser/$detachedUserObjectId',
    ).toString();
    final String currentPutPath = Uri.parse(
      '$serverUrl$keyEndPointClasses$keyClassUser/$currentUserObjectId',
    ).toString();

    setUp(() async {
      client = MockParseClient();
      await ParseCoreData().getStore().remove(keyParseStoreUser);
    });

    /// Seeds local storage with user A as the stored current user,
    /// the way a successful login would have left it.
    Future<void> seedCurrentUserInStorage() async {
      final ParseUser current = ParseUser(null, null, null, client: client);
      current.fromJson(<String, dynamic>{
        keyVarObjectId: currentUserObjectId,
        keyVarSessionToken: 'r:currentSession',
        keyVarUsername: 'alice@example.com',
      });
      await ParseCoreData().getStore().setString(
        keyParseStoreUser,
        json.encode(current.toJson(full: true)),
      );
    }

    Future<String?> storedUserObjectId() async {
      final String? userJson = await ParseCoreData().getStore().getString(
        keyParseStoreUser,
      );
      if (userJson == null) {
        return null;
      }
      return json.decode(userJson)[keyVarObjectId];
    }

    ParseUser detachedUser() {
      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: detachedUserObjectId,
        keyVarSessionToken: 'r:staleAnonSession',
        keyVarUsername: 'anonymous-uuid',
      });
      return user;
    }

    test('getUpdatedUser() on a detached instance must NOT replace the '
        'stored current user. a stale anonymous instance whose fetch '
        'resolves after a login would otherwise clobber the freshly '
        'logged-in user on disk — the daily forced re-login bug', () async {
      await seedCurrentUserInStorage();

      when(client.get(mePath, options: anyNamed('options'))).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: detachedUserObjectId,
            keyVarUsername: 'anonymous-uuid',
            keyVarSessionToken: 'r:staleAnonSession',
          }),
        ),
      );

      final ParseResponse response = await detachedUser().getUpdatedUser(
        client: client,
      );

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals(currentUserObjectId));
    });

    test('save() on a detached instance must NOT replace the stored current '
        'user. save responses previously persisted whichever instance '
        'handled them, with no current-user check', () async {
      await seedCurrentUserInStorage();

      when(
        client.put(
          detachedPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
          }),
        ),
      );

      final ParseUser user = detachedUser();
      user.set<String>('localeIdentifier', 'en-US');

      final ParseResponse response = await user.save();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals(currentUserObjectId));
    });

    test('update() on a detached instance must NOT replace the stored '
        'current user', () async {
      await seedCurrentUserInStorage();

      when(
        client.put(
          detachedPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
          }),
        ),
      );

      final ParseUser user = detachedUser();
      user.set<String>('localeIdentifier', 'en-US');

      final ParseResponse response = await user.update();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals(currentUserObjectId));
    });

    test('save() on the current user instance still persists to local '
        'storage. gating must not break the ordinary keep-disk-in-sync '
        'behavior for the user that is actually current', () async {
      await seedCurrentUserInStorage();

      when(
        client.put(
          currentPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
          }),
        ),
      );

      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: currentUserObjectId,
        keyVarSessionToken: 'r:currentSession',
        keyVarUsername: 'alice@example.com',
      });
      user.set<String>('localeIdentifier', 'en-US');

      final ParseResponse response = await user.save();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals(currentUserObjectId));

      final String? userJson = await ParseCoreData().getStore().getString(
        keyParseStoreUser,
      );
      expect(json.decode(userJson!)['localeIdentifier'], equals('en-US'));
    });

    test('getUpdatedUser() on the current user instance still persists the '
        'refreshed data to local storage', () async {
      await seedCurrentUserInStorage();

      when(client.get(mePath, options: anyNamed('options'))).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: currentUserObjectId,
            keyVarUsername: 'alice@example.com',
            keyVarEmail: 'alice+updated@example.com',
            keyVarSessionToken: 'r:currentSession',
          }),
        ),
      );

      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: currentUserObjectId,
        keyVarSessionToken: 'r:currentSession',
      });

      final ParseResponse response = await user.getUpdatedUser(client: client);

      expect(response.success, isTrue);
      final String? userJson = await ParseCoreData().getStore().getString(
        keyParseStoreUser,
      );
      expect(
        json.decode(userJson!)[keyVarEmail],
        equals('alice+updated@example.com'),
      );
    });

    test('login() always persists — it establishes the new current user and '
        'must replace whoever was stored before', () async {
      await seedCurrentUserInStorage();

      final String loginPath = Uri.parse(
        '$serverUrl$keyEndPointLogin',
      ).toString();
      when(
        client.post(
          loginPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: 'userCCC',
            keyVarUsername: 'bob@example.com',
            keyVarSessionToken: 'r:bobSession',
          }),
        ),
      );

      final ParseUser user = ParseUser(
        'bob@example.com',
        'hunter2',
        null,
        client: client,
      );

      final ParseResponse response = await user.login();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals('userCCC'));
    });

    test('loginAnonymous() always persists — first-ever auth with nothing in '
        'storage must still write the new current user', () async {
      final String usersPath = Uri.parse(
        '$serverUrl$keyEndPointUsers',
      ).toString();
      when(
        client.post(
          usersPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 201,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: 'anonDDD',
            keyVarSessionToken: 'r:anonSession',
          }),
        ),
      );

      final ParseUser user = ParseUser(null, null, null, client: client);

      final ParseResponse response = await user.loginAnonymous();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals('anonDDD'));
    });

    test('signUp() always persists — it establishes the new current user '
        'even when a different user is stored', () async {
      await seedCurrentUserInStorage();

      final String usersPath = Uri.parse(
        '$serverUrl$keyEndPointClasses$keyClassUser',
      ).toString();
      when(
        client.post(
          usersPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 201,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: 'userEEE',
            keyVarSessionToken: 'r:newSession',
          }),
        ),
      );

      final ParseUser user = ParseUser(
        'carol@example.com',
        'hunter2',
        'carol@example.com',
        client: client,
      );

      final ParseResponse response = await user.signUp();

      expect(response.success, isTrue);
      expect(await storedUserObjectId(), equals('userEEE'));
    });

    test('getCurrentUserFromServer() always persists — it starts from an '
        'empty instance whose objectId is only known from the response, and '
        'its whole purpose is to refresh the current user', () async {
      await seedCurrentUserInStorage();

      when(client.get(mePath, options: anyNamed('options'))).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: 'userFFF',
            keyVarUsername: 'dave@example.com',
            keyVarSessionToken: 'r:daveSession',
          }),
        ),
      );

      final ParseResponse? response = await ParseUser.getCurrentUserFromServer(
        'r:daveSession',
        client: client,
      );

      expect(response!.success, isTrue);
      expect(await storedUserObjectId(), equals('userFFF'));
    });

    test('save() on a detached instance still adopts a fresh sessionToken '
        'from the response (_adoptResponseSessionTokenIfChanged behavior is '
        'preserved) even though it no longer persists to storage', () async {
      await seedCurrentUserInStorage();
      ParseCoreData().setSessionId('r:currentSession');

      when(
        client.put(
          detachedPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
            keyVarSessionToken: 'r:mintedSession',
          }),
        ),
      );

      final ParseUser user = detachedUser();
      user.password = 'newPassword';

      final ParseResponse response = await user.save();

      // The detached instance must adopt NEITHER the storage slot NOR the
      // global session — otherwise storage and session would belong to two
      // different accounts.
      expect(response.success, isTrue);
      expect(ParseCoreData().sessionId, equals('r:currentSession'));
      expect(await storedUserObjectId(), equals(currentUserObjectId));
    });

    test('save() on the current user that mints a fresh sessionToken still '
        'adopts it — the anonymous-to-password upgrade flow depends on '
        'this (the current instance IS the stored user)', () async {
      await seedCurrentUserInStorage();
      ParseCoreData().setSessionId('r:currentSession');

      when(
        client.put(
          currentPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
            keyVarSessionToken: 'r:mintedSession',
          }),
        ),
      );

      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarObjectId: currentUserObjectId,
        keyVarSessionToken: 'r:currentSession',
        keyVarUsername: 'alice@example.com',
      });
      user.password = 'newPassword';

      final ParseResponse response = await user.save();

      expect(response.success, isTrue);
      expect(ParseCoreData().sessionId, equals('r:mintedSession'));
      expect(await storedUserObjectId(), equals(currentUserObjectId));
    });

    test('a corrupt stored current-user blob is treated as no current user — '
        'the responding instance must not persist over it (FormatException '
        'branch of the current-user gate)', () async {
      const String corruptBlob = 'not-valid-json{{{';
      await ParseCoreData().getStore().setString(
        keyParseStoreUser,
        corruptBlob,
      );

      when(client.get(mePath, options: anyNamed('options'))).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: detachedUserObjectId,
            keyVarUsername: 'anonymous-uuid',
            keyVarSessionToken: 'r:staleAnonSession',
          }),
        ),
      );

      final ParseResponse response = await detachedUser().getUpdatedUser(
        client: client,
      );

      expect(response.success, isTrue);
      expect(
        await ParseCoreData().getStore().getString(keyParseStoreUser),
        equals(corruptBlob),
      );
    });

    for (final String nonObjectRoot in <String>['null', '[]', '"user"']) {
      test(
        'a stored blob of valid JSON with a non-object root ($nonObjectRoot) '
        'is treated as no current user — the type check must catch what '
        'the FormatException handler cannot',
        () async {
          await ParseCoreData().getStore().setString(
            keyParseStoreUser,
            nonObjectRoot,
          );

          when(client.get(mePath, options: anyNamed('options'))).thenAnswer(
            (_) async => ParseNetworkResponse(
              statusCode: 200,
              data: jsonEncode(<String, dynamic>{
                keyVarObjectId: detachedUserObjectId,
                keyVarUsername: 'anonymous-uuid',
                keyVarSessionToken: 'r:staleAnonSession',
              }),
            ),
          );

          final ParseResponse response = await detachedUser().getUpdatedUser(
            client: client,
          );

          expect(response.success, isTrue);
          expect(
            await ParseCoreData().getStore().getString(keyParseStoreUser),
            equals(nonObjectRoot),
          );
        },
      );
    }

    test('a login landing while a gated save is mid-check cannot be '
        'overwritten by the stale write — the current-user check and its '
        'persist are one serialized operation', () async {
      final CoreStore realStore = ParseCoreData().getStore();
      final _HoldingCoreStore holdingStore = _HoldingCoreStore(realStore);
      ParseCoreData().storage = holdingStore;
      addTearDown(() => ParseCoreData().storage = realStore);

      await seedCurrentUserInStorage();

      when(
        client.put(
          currentPutPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarUpdatedAt: '2026-08-19T12:00:01.000Z',
          }),
        ),
      );

      final String loginPath = Uri.parse(
        '$serverUrl$keyEndPointLogin',
      ).toString();
      when(
        client.post(
          loginPath,
          options: anyNamed('options'),
          data: anyNamed('data'),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(<String, dynamic>{
            keyVarObjectId: 'userCCC',
            keyVarUsername: 'bob@example.com',
            keyVarSessionToken: 'r:bobSession',
          }),
        ),
      );

      // The current user's save reaches its gate check first and is held
      // open mid-read.
      final ParseUser userA = ParseUser(null, null, null, client: client);
      userA.fromJson(<String, dynamic>{
        keyVarObjectId: currentUserObjectId,
        keyVarSessionToken: 'r:currentSession',
        keyVarUsername: 'alice@example.com',
      });
      userA.set<String>('localeIdentifier', 'en-US');

      holdingStore.arm();
      final Future<ParseResponse> saveFuture = userA.save();
      int pumps = 0;
      while (!holdingStore.isHolding) {
        if (++pumps > 1000) {
          fail(
            'save() never reached the current-user read; the persistence '
            'gate did not call getString(keyParseStoreUser).',
          );
        }
        await Future<void>.delayed(Duration.zero);
      }

      // A login completes while the save's check is suspended. Serialized,
      // it must queue behind the whole check+write pair — not write in the
      // middle of it and then be clobbered by the stale gated write.
      final ParseUser userB = ParseUser(
        'bob@example.com',
        'hunter2',
        null,
        client: client,
      );
      final Future<ParseResponse> loginFuture = userB.login();

      // Deterministic enqueue signal: _handleResponse installs the response
      // sessionToken via setSessionId and calls _serializedPersistence in the
      // same synchronous stretch (no await between them). Once the global
      // session reads the login's token, the login persistence action is
      // provably queued behind the held save — releasing now exercises the
      // stale-write interleaving on every scheduler.
      pumps = 0;
      while (ParseCoreData().sessionId != 'r:bobSession') {
        if (++pumps > 1000) {
          fail(
            'login() never installed its session token; its persistence '
            'action was not enqueued behind the held save.',
          );
        }
        await Future<void>.delayed(Duration.zero);
      }

      holdingStore.release();
      await Future.wait(<Future<ParseResponse>>[saveFuture, loginFuture]);

      expect(await storedUserObjectId(), equals('userCCC'));
    });
  });
}

/// One-shot blocking decorator over a [CoreStore]: after [arm], the next
/// `getString(keyParseStoreUser)` snapshots the stored value immediately,
/// then suspends until [release] — letting a test force another persistence
/// operation to run while a check+write critical section is mid-flight.
class _HoldingCoreStore implements CoreStore {
  _HoldingCoreStore(this._inner);

  final CoreStore _inner;
  Completer<void>? _hold;
  bool _armed = false;
  bool _holding = false;

  bool get isHolding => _holding;

  void arm() {
    _armed = true;
    _hold = Completer<void>();
  }

  void release() {
    _holding = false;
    _hold!.complete();
  }

  @override
  Future<String?> getString(String key) async {
    if (_armed && key == keyParseStoreUser) {
      _armed = false;
      final String? snapshot = await _inner.getString(key);
      _holding = true;
      await _hold!.future;
      return snapshot;
    }
    return _inner.getString(key);
  }

  @override
  Future<bool> containsKey(String key) => _inner.containsKey(key);

  @override
  Future<dynamic> get(String key) => _inner.get(key);

  @override
  Future<bool?> getBool(String key) => _inner.getBool(key);

  @override
  Future<int?> getInt(String key) => _inner.getInt(key);

  @override
  Future<double?> getDouble(String key) => _inner.getDouble(key);

  @override
  Future<List<String>?> getStringList(String key) => _inner.getStringList(key);

  @override
  Future<dynamic> setBool(String key, bool value) => _inner.setBool(key, value);

  @override
  Future<dynamic> setInt(String key, int value) => _inner.setInt(key, value);

  @override
  Future<dynamic> setDouble(String key, double value) =>
      _inner.setDouble(key, value);

  @override
  Future<dynamic> setString(String key, String value) =>
      _inner.setString(key, value);

  @override
  Future<dynamic> setStringList(String key, List<String> values) =>
      _inner.setStringList(key, values);

  @override
  Future<dynamic> remove(String key) => _inner.remove(key);

  @override
  Future<dynamic> clear() => _inner.clear();
}
