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

  group('create()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    late String postPath;

    setUp(() {
      client = MockParseClient();

      final user = ParseObject(keyClassUser)..objectId = "ELR124r8C";
      dietPlansObject = ParseObject("Diet_Plans", client: client);
      dietPlansObject
        ..set('Name', 'value')
        ..set('Fat', 15)
        ..set('user', user)
        ..set("location", ParseGeoPoint(latitude: 10, longitude: 10));

      postPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();
    });

    test(
        'create() should create new object on the server, return the created '
        'object in ParseResponse results and update the calling object '
        'with the new data (objectId,createdAt). i.e: mutate the object state',
        () async {
      // arrange

      const resultFromServer = {
        keyVarObjectId: "DLde4rYA8C",
        keyVarCreatedAt: "2023-02-26T00:20:37.187Z"
      };
      final postData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));

      when(client.post(
        postPath,
        options: anyNamed("options"),
        data: postData,
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      // act
      ParseResponse response = await dietPlansObject.create();

      // assert
      final resultList = response.results;

      expect(resultList, isNotNull);

      expect(resultList, isA<List<ParseObject?>>());

      expect(resultList!.first, isNotNull);

      expect(resultList.first, isA<ParseObject>());

      final parseObject = (resultList.first as ParseObject);

      expect(
        parseObject.createdAt!.toIso8601String(),
        equals(resultFromServer[keyVarCreatedAt]),
      );

      expect(
        dietPlansObject.createdAt!.toIso8601String(),
        equals(resultFromServer[keyVarCreatedAt]),
      );

      expect(
        parseObject.objectId,
        equals(resultFromServer[keyVarObjectId]),
      );

      expect(
        dietPlansObject.objectId,
        equals(resultFromServer[keyVarObjectId]),
      );

      // the calling object (dietPlansObject) will be identical to the object
      // in the ParseResponse results
      expect(
        identical(dietPlansObject, parseObject),
        isTrue,
      );

      verify(client.post(
        postPath,
        options: anyNamed("options"),
        data: postData,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('create() should return error', () async {
      // arrange

      final postData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));
      final error = Exception('error');
      when(client.post(
        postPath,
        options: anyNamed("options"),
        data: postData,
      )).thenThrow(error);

      // act
      ParseResponse response = await dietPlansObject.create();

      // assert
      expect(response.success, isFalse);

      expect(response.result, isNull);

      expect(response.count, isZero);

      expect(response.results, isNull);

      expect(response.error, isNotNull);

      expect(response.error!.exception, equals(error));

      expect(response.error!.code, equals(ParseError.otherCause));

      expect(dietPlansObject.objectId, isNull);

      expect(dietPlansObject.createdAt, isNull);

      verify(client.post(
        postPath,
        options: anyNamed("options"),
        data: postData,
      )).called(1);

      verifyNoMoreInteractions(client);
    });
  });
}
