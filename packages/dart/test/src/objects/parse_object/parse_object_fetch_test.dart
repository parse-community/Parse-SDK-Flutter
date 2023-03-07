import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

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
        include: ['img', 'owner'],
      );

      // assert
    });
  });
}
