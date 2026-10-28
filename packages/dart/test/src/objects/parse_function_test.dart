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

  group('ParseCloudFunction', () {
    late MockParseClient client;

    const functionName = 'hello';
    const functionPath = '$serverUrl/functions/$functionName';

    setUp(() {
      client = MockParseClient();
    });

    test(
      'execute() should use the client and debug flag passed to the constructor',
      () async {
        // arrange
        final cloudFunction = ParseCloudFunction(
          functionName,
          debug: false,
          client: client,
          autoSendSessionId: false,
        );

        final parameters = <String, dynamic>{"name": "Parse"};

        when(
          client.post(
            functionPath,
            options: anyNamed("options"),
            data: jsonEncode(parameters),
          ),
        ).thenAnswer(
          (_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode({"result": "Hello Parse"}),
          ),
        );

        // act
        late ParseResponse response;
        // initializeParse() enables debug globally, so no log output shows
        // that the debug flag passed to the constructor is used.
        await expectLater(
          () async =>
              response = await cloudFunction.execute(parameters: parameters),
          prints(isEmpty),
        );

        // assert
        expect(response.success, isTrue);

        expect(response.result, equals("Hello Parse"));

        verify(
          client.post(
            functionPath,
            options: anyNamed("options"),
            data: jsonEncode(parameters),
          ),
        ).called(1);

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
      ParseCloudFunction(functionName, autoSendSessionId: false);

      // assert
      expect(sendSessionIdPassed, isFalse);
    });
  });
}
