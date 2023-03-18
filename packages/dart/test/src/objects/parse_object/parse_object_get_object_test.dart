import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  group('getObject()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    late String getPath;

    const objectId = "Mn1iJTkWTE";

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);

      dietPlansObject.objectId = objectId;

      getPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).replace(query: 'include=afile,owner').toString();
    });

    test('getObject() should get a object form the server using its objectId',
        () async {
      // arrange
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
      final response = await dietPlansObject.getObject(
        objectId,
        include: ['afile', 'owner'],
      );

      // assert
      expect(response.count, equals(1));

      expect(response.success, isTrue);

      expect(response.results, isNotNull);

      expect(response.results, isA<List<ParseObject>>());

      final responseResults = List<ParseObject>.from(response.results!);

      final parseObjectFromServer = responseResults.first;

      expect(
        jsonEncode(parseObjectFromServer.toJson(full: true)),
        equals(jsonEncode(expectedParseObject.toJson(full: true))),
      );

      verify(client.get(
        getPath,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('getObject() should return error', () async {
      // arrange

      final error = Exception('error');

      when(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenThrow(error);

      // act
      final response = await dietPlansObject.getObject(
        objectId,
        include: ['afile', 'owner'],
      );

      // assert
      expect(response.success, isFalse);

      expect(response.result, isNull);

      expect(response.count, isZero);

      expect(response.results, isNull);

      expect(response.error, isNotNull);

      expect(response.error!.exception, equals(error));

      expect(response.error!.code, equals(ParseError.otherCause));

      verify(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).called(1);

      verifyNoMoreInteractions(client);
    });
  });
}
