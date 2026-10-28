import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../parse_query_test.mocks.dart';
import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseConfig', () {
    late MockParseClient client;

    const configPath = '$serverUrl/config';

    setUp(() {
      client = MockParseClient();
    });

    test(
      'getConfigs() should use the client and debug flag passed to the constructor',
      () async {
        // arrange
        final config = ParseConfig(
          debug: false,
          client: client,
          autoSendSessionId: false,
        );

        when(
          client.get(
            configPath,
            options: anyNamed("options"),
            onReceiveProgress: anyNamed("onReceiveProgress"),
          ),
        ).thenAnswer(
          (_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode({
              "params": {"welcomeMessage": "Hello"},
            }),
          ),
        );

        // act
        late ParseResponse response;
        // initializeParse() enables debug globally, so no log output shows
        // that the debug flag passed to the constructor is used.
        await expectLater(
          () async => response = await config.getConfigs(),
          prints(isEmpty),
        );

        // assert
        expect(response.success, isTrue);

        expect(response.result, equals({"welcomeMessage": "Hello"}));

        verify(client.get(configPath)).called(1);

        verifyNoMoreInteractions(client);
      },
    );

    test('autoSendSessionId should be passed to the client creator', () {
      // arrange
      final defaultClientCreator = ParseCoreData().clientCreator;
      addTearDown(() => ParseCoreData().clientCreator = defaultClientCreator);

      bool? sendSessionIdPassed;
      ParseCoreData().clientCreator =
          ({required sendSessionId, securityContext}) {
            sendSessionIdPassed = sendSessionId;
            return client;
          };

      // act
      ParseConfig(autoSendSessionId: false);

      // assert
      expect(sendSessionIdPassed, isFalse);
    });
  });
}
