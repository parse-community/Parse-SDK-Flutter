import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../network/parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('saveEventually()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() {
      client = MockParseClient();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
      'should exist parse object in ParseCoreData next saveEventually',
      () async {
        // arrange
        when(client.post(
          any,
          options: anyNamed("options"),
          data: anyNamed("data"),
        )).thenThrow(Exception('NetworkError'));

        when(client.post(
          "$serverUrl/batch",
          options: anyNamed("options"),
          data: anyNamed("data"),
        )).thenAnswer(
          (_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode([
              {
                "success": {
                  "add": "ok",
                }
              }
            ]),
          ),
        );

        // act
        await dietPlansObject.saveEventually();

        final CoreStore coreStore = ParseCoreData().getStore();
        List<String> list =
            await coreStore.getStringList(keyParseStoreObjects) ?? [];

        // assert
        expect(list.length, 1);

        // act
        await ParseObject.submitEventually(client: client);

        List<String> list2 =
            await coreStore.getStringList(keyParseStoreObjects) ?? [];

        // assert
        expect(list2.length, 0);
      },
    );
  });
}
