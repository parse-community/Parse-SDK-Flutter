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

  group('deleteEventually()', () {
    late MockParseClient client1;
    late MockParseClient client2;

    late ParseObject dietPlansObject;

    setUp(() {
      client1 = MockParseClient();
      client2 = MockParseClient();

      dietPlansObject = ParseObject("Diet_Plans", client: client1);

      dietPlansObject.objectId = "fakeObjectId";
    });

    test(
      'should exist parse object in ParseCoreData next saveEventually',
      () async {
        // arrange
        when(client1.delete(
          any,
          options: anyNamed("options"),
        )).thenThrow(Exception('NetworkError'));

        when(client2.delete(
          "$serverUrl/classes/Diet_Plans/fakeObjectId",
          options: anyNamed("options"),
        )).thenAnswer(
          (_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode([
              {
                "success": {
                  "delete": "ok",
                }
              }
            ]),
          ),
        );

        // act
        await dietPlansObject.deleteEventually();

        final CoreStore coreStore = ParseCoreData().getStore();
        List<String> list =
            await coreStore.getStringList(keyParseStoreDeletes) ?? [];

        // assert
        expect(list.length, 1);

        // act
        await ParseObject.submitEventually(client: client2);

        List<String> list2 =
            await coreStore.getStringList(keyParseStoreDeletes) ?? [];

        // assert
        expect(list2.length, 0);
      },
    );
  });
}
