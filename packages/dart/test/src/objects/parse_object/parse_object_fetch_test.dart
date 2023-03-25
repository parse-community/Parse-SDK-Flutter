import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  group('fetch()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
        'fetch() should return fresh data from the server about an object using its ID',
        () async {
      // arrange
      dietPlansObject.objectId = "Mn1iJTkWTE";

      final getPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).replace(query: 'include=afile,owner').toString();

      const resultsFromServer = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            "Name": "A string",
            "Description": "A string",
            "Carbs": 1,
            "Fat": 1,
            "Status": true,
            "Protein": 1,
            "co_owner": {
              "__type": "Pointer",
              "className": "_User",
              "objectId": "cmWCmCAyQQ"
            },
            "owner": {
              "objectId": "eTSwGnAOAq",
              "username": "n@g.com",
              "createdAt": "2023-03-01T03:37:41.011Z",
              "updatedAt": "2023-03-01T03:37:41.011Z",
              "ACL": {
                "*": {"read": true},
                "eTSwGnAOAq": {"read": true, "write": true}
              },
              "__type": "Object",
              "className": "_User"
            },
            "location": {
              "__type": "GeoPoint",
              "latitude": 40,
              "longitude": -30
            },
            "anArray": [1, "a string"],
            "afile": {
              "__type": "File",
              "name": "resume.txt",
              "url": "https://exampe.com/gyBUISapgwfxB/resume.txt"
            },
            "createdAt": "2023-03-05T00:25:31.466Z",
            "updatedAt": "2023-03-05T00:25:31.466Z",
            "users": {"__type": "Relation", "className": "_User"}
          },
        ]
      };

      final expectedParseObject = ParseObject('Diet_Plans')
        ..fromJson(resultsFromServer['results']!.first);

      when(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultsFromServer),
        ),
      );

      // act
      ParseObject parseObject = await dietPlansObject.fetch(
        include: ['afile', 'owner'],
      );

      // assert

      expect(
        jsonEncode(parseObject.toJson(full: true)),
        equals(jsonEncode(expectedParseObject.toJson(full: true))),
      );

      verify(client.get(
        getPath,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'fetch() should return the same calling object in case of an error and '
        'the object data should remain the same', () async {
      // arrange
      dietPlansObject.objectId = "Mn1iJTkWTE";

      const keyFat = 'keyFat';
      const keyFatValue = 15;

      dietPlansObject.set(keyFat, keyFatValue);

      final getPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      final error = Exception('error');

      when(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenThrow(error);

      // act
      ParseObject parseObject = await dietPlansObject.fetch();

      // assert
      expect(identical(parseObject, dietPlansObject), isTrue);

      expect(dietPlansObject.get<int>(keyFat), equals(keyFatValue));

      verify(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('fetch() should throw exception if the objectId is null or empty ',
        () async {
      // arrange
      dietPlansObject.objectId = null;

      expect(
        () async => await dietPlansObject.fetch(),
        throwsA(isA<String>()),
        reason: 'the objectId is null',
      );

      dietPlansObject.objectId = '';

      expect(
        () async => await dietPlansObject.fetch(),
        throwsA(isA<String>()),
        reason: 'the objectId is empty',
      );
    });
  });
}
