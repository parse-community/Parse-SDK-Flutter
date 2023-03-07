import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  group('update()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    const keyName = 'Name';
    const keyFat = 'Fat';

    final newNameValue = 'new Name';
    final newFatValue = 56;

    late String putPath;

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
      dietPlansObject
        ..objectId = "DLde4rYA8C"
        ..set(keyName, newNameValue)
        ..set(keyFat, newFatValue);

      putPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();
    });
    test(
        'update() should update an object on the server, return the updated '
        'object in ParseResponse results and update the calling object '
        'with the new data (updatedAt).'
        'i.e: mutate the object state to reflect the new update', () async {
      // arrange

      const resultFromServer = {
        keyVarUpdatedAt: "2023-02-26T13:25:27.865Z",
      };

      final putData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));

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
      ParseResponse response = await dietPlansObject.update();

      // assert
      final resultList = response.results;

      expect(resultList, isNotNull);
      expect(resultList!.first, isNotNull);
      expect(resultList.first, isA<ParseObject>());

      final parseObjectFromRes = (resultList.first as ParseObject);

      expect(
        parseObjectFromRes.updatedAt!.toIso8601String(),
        equals(resultFromServer[keyVarUpdatedAt]),
      );
      expect(
        dietPlansObject.updatedAt!.toIso8601String(),
        equals(resultFromServer[keyVarUpdatedAt]),
      );

      expect(
        parseObjectFromRes.get(keyName),
        equals(newNameValue),
      );
      expect(
        parseObjectFromRes.get(keyFat),
        equals(newFatValue),
      );

      // the calling object (dietPlansObject) will be identical to the object
      // in the ParseResponse results
      expect(
        identical(dietPlansObject, parseObjectFromRes),
        isTrue,
      );

      verify(client.put(
        putPath,
        options: anyNamed("options"),
        data: putData,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'update() should return error and the updated values should remain the same',
        () async {
      // arrange

      final putData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));
      final error = Exception('error');

      when(client.put(
        putPath,
        options: anyNamed("options"),
        data: putData,
      )).thenThrow(error);

      // act
      ParseResponse response = await dietPlansObject.update();

      // assert
      expect(response.success, isFalse);

      expect(response.result, isNull);

      expect(response.count, isZero);

      expect(response.results, isNull);

      expect(response.error, isNotNull);

      expect(response.error!.exception, equals(error));

      expect(response.error!.code, equals(ParseError.otherCause));

      // even if the update failed, the updated values should remain the same
      expect(dietPlansObject.get(keyName), equals(newNameValue));
      expect(dietPlansObject.get(keyFat), equals(newFatValue));

      verify(client.put(
        putPath,
        options: anyNamed("options"),
        data: putData,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('should throw AssertionError if objectId is null', () {
      dietPlansObject.objectId = null;

      expect(
        () async => await dietPlansObject.update(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError if objectId is empty', () {
      dietPlansObject.objectId = '';

      expect(
        () async => await dietPlansObject.update(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
