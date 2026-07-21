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

  group('ParseUser anonymous → email/password conversion', () {
    late MockParseClient client;

    const String userObjectId = 'abc123XYZ';
    const String anonymousId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
    final String putPath = Uri.parse(
      '$serverUrl$keyEndPointClasses$keyClassUser/$userObjectId',
    ).toString();

    setUp(() {
      client = MockParseClient();
    });

    ParseUser anonymousUserWithObjectId({Map<String, dynamic>? extraAuthData}) {
      final ParseUser user = ParseUser(null, null, null, client: client);
      final Map<String, dynamic> authData = <String, dynamic>{
        'anonymous': <String, dynamic>{'id': anonymousId},
      };
      if (extraAuthData != null) {
        authData.addAll(extraAuthData);
      }
      user.fromJson(<String, dynamic>{
        keyVarObjectId: userObjectId,
        keyVarSessionToken: 'r:abcdef0123456789',
        keyVarAuthData: authData,
        keyVarCreatedAt: '2026-04-28T12:00:00.000Z',
        keyVarUpdatedAt: '2026-04-28T12:00:00.000Z',
      });
      return user;
    }

    test(
      'setting username on a persisted anonymous user marks the anonymous '
      'authData entry for unlinking by setting its value to null. the null '
      'value is the unlink signal Parse Server interprets on the next save',
      () {
        final ParseUser user = anonymousUserWithObjectId();

        user.username = 'alice@example.com';

        expect(user.authData, isNotNull);
        expect(user.authData!.containsKey('anonymous'), isTrue);
        expect(user.authData!['anonymous'], isNull);
      },
    );

    test('after a successful save(), the local authData no longer contains '
        'the anonymous entry. the PUT response carries only the fields the '
        'client wrote, so the post-save cleanup is what reconciles local '
        'state with the server-side unlink', () async {
      final ParseUser user = anonymousUserWithObjectId();

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
            keyVarUsername: 'alice@example.com',
            keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            keyVarSessionToken: 'r:newtoken',
          }),
        ),
      );

      user.username = 'alice@example.com';
      user.password = 'hunter2';

      final ParseResponse response = await user.save();

      expect(response.success, isTrue);
      final Map<String, dynamic>? cleaned = user.authData;
      expect(
        cleaned == null || !cleaned.containsKey('anonymous'),
        isTrue,
        reason:
            'authData.anonymous should be removed locally after a '
            'successful conversion save',
      );
    });

    test('after a successful update(), the local authData no longer contains '
        'the anonymous entry. update() and save() both run the post-save '
        'cleanup, so each path needs independent coverage', () async {
      final ParseUser user = anonymousUserWithObjectId();

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
            keyVarUsername: 'alice@example.com',
            keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            keyVarSessionToken: 'r:newtoken',
          }),
        ),
      );

      user.username = 'alice@example.com';
      user.password = 'hunter2';

      final ParseResponse response = await user.update();

      expect(response.success, isTrue);
      final Map<String, dynamic>? cleaned = user.authData;
      expect(
        cleaned == null || !cleaned.containsKey('anonymous'),
        isTrue,
        reason:
            'authData.anonymous should be removed locally after a '
            'successful conversion update',
      );
    });

    test(
      'the PUT body for an anonymous-conversion save carries '
      'authData.anonymous = null. this is the wire-level unlink signal that '
      'lets Parse Server clean the server-side record on the same round-trip',
      () async {
        final ParseUser user = anonymousUserWithObjectId();

        String? capturedBody;
        when(
          client.put(
            putPath,
            options: anyNamed('options'),
            data: anyNamed('data'),
          ),
        ).thenAnswer((Invocation invocation) async {
          capturedBody =
              invocation.namedArguments[const Symbol('data')] as String?;
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(<String, dynamic>{
              keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            }),
          );
        });

        user.username = 'alice@example.com';
        user.password = 'hunter2';

        await user.save();

        expect(capturedBody, isNotNull);
        final Map<String, dynamic> decoded =
            jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(decoded[keyVarAuthData], isA<Map>());
        final Map<String, dynamic> sentAuthData =
            (decoded[keyVarAuthData] as Map).cast<String, dynamic>();
        expect(sentAuthData.containsKey('anonymous'), isTrue);
        expect(sentAuthData['anonymous'], isNull);
      },
    );

    test(
      'non-anonymous authData entries (e.g. facebook, google) survive the '
      'conversion. only the anonymous null marker is dropped on cleanup',
      () async {
        final ParseUser user = anonymousUserWithObjectId(
          extraAuthData: <String, dynamic>{
            'facebook': <String, dynamic>{
              'id': 'fb-12345',
              'access_token': 'tok',
            },
          },
        );

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

        user.username = 'alice@example.com';

        await user.save();

        expect(user.authData, isNotNull);
        expect(user.authData!.containsKey('anonymous'), isFalse);
        expect(user.authData!.containsKey('facebook'), isTrue);
        expect(user.authData!['facebook'], isNotNull);
      },
    );

    test('on a lazy (no objectId) anonymous user, setting username drops the '
        'anonymous entry locally without leaving a null marker. unpersisted '
        'users have nothing to unlink server-side, so no marker is needed', () {
      final ParseUser user = ParseUser(null, null, null, client: client);
      user.fromJson(<String, dynamic>{
        keyVarAuthData: <String, dynamic>{
          'anonymous': <String, dynamic>{'id': anonymousId},
        },
      });

      user.username = 'alice@example.com';

      final Map<String, dynamic>? cleaned = user.authData;
      expect(
        cleaned == null || !cleaned.containsKey('anonymous'),
        isTrue,
        reason:
            'unpersisted anonymous user should drop the entry without '
            'leaving a null marker',
      );
    });
  });

  group('ParseUser save() regression — non-anonymous users', () {
    late MockParseClient client;

    const String userObjectId = 'reg123';
    final String putPath = Uri.parse(
      '$serverUrl$keyEndPointClasses$keyClassUser/$userObjectId',
    ).toString();

    setUp(() {
      client = MockParseClient();
    });

    test(
      'setting username on a non-anonymous user does not synthesize authData '
      'into the request body. only the anonymous-conversion case should '
      'inject the null marker',
      () async {
        final ParseUser user = ParseUser(null, null, null, client: client);
        user.fromJson(<String, dynamic>{
          keyVarObjectId: userObjectId,
          keyVarSessionToken: 'r:xyz',
          keyVarUsername: 'old@example.com',
        });

        String? capturedBody;
        when(
          client.put(
            putPath,
            options: anyNamed('options'),
            data: anyNamed('data'),
          ),
        ).thenAnswer((Invocation invocation) async {
          capturedBody =
              invocation.namedArguments[const Symbol('data')] as String?;
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(<String, dynamic>{
              keyVarUpdatedAt: '2026-04-28T12:00:01.000Z',
            }),
          );
        });

        user.username = 'new@example.com';

        final ParseResponse response = await user.save();

        expect(response.success, isTrue);
        expect(capturedBody, isNotNull);
        final Map<String, dynamic> decoded =
            jsonDecode(capturedBody!) as Map<String, dynamic>;
        expect(
          decoded.containsKey(keyVarAuthData),
          isFalse,
          reason:
              'a regular username update on a non-anonymous user should not '
              'synthesize authData in the request body',
        );
      },
    );
  });
}
