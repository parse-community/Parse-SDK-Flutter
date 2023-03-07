import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  group('unset()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;
    const keyFat = 'fat';

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test('unset() should unset a value from ParseObject locally', () async {
      // arrange
      dietPlansObject.set(keyFat, 2);

      final putPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      // act
      final ParseResponse parseResponse =
          await dietPlansObject.unset(keyFat, offlineOnly: true);

      // assert
      expect(parseResponse.success, isTrue);

      expect(dietPlansObject.get(keyFat), isNull);

      verifyNever(client.put(
        putPath,
        options: anyNamed("options"),
        data: anyNamed('data'),
      ));

      verifyZeroInteractions(client);
    });

    test('unset() should unset a value from ParseObject locally on online',
        () async {
      // arrange

      dietPlansObject.set(keyFat, 2);
      dietPlansObject.objectId = "O6BHlwV48Z";

      final putPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      const String putData = '{"$keyFat":{"__op":"Delete"}}';
      const resultFromServer = {
        keyVarUpdatedAt: "2023-03-04T03:34:35.076Z",
      };

      when(client.put(
        putPath,
        options: anyNamed("options"),
        data: putData,
      )).thenAnswer(
        (realInvocation) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      // act
      final ParseResponse parseResponse =
          await dietPlansObject.unset(keyFat, offlineOnly: false);

      // assert
      expect(parseResponse.success, isTrue);

      expect(dietPlansObject.get(keyFat), isNull);

      verify(client.put(
        putPath,
        options: anyNamed("options"),
        data: putData,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'If objectId is null, unset() should unset a value from ParseObject '
        'locally and not make any call to the server and return unsuccessful Response',
        () async {
      // arrange
      dietPlansObject.set(keyFat, 2);

      // act
      final parseResponse =
          await dietPlansObject.unset(keyFat, offlineOnly: false);

      // assert
      expect(parseResponse.success, isFalse);

      expect(parseResponse.result, isNull);

      expect(parseResponse.count, isZero);

      expect(parseResponse.statusCode, ParseError.otherCause);

      expect(dietPlansObject.get(keyFat), isNull);

      verifyZeroInteractions(client);
    });
  });
}
