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

  group('getAll()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    late String getPath;

    setUp(() {
      client = MockParseClient();

      dietPlansObject = ParseObject("Diet_Plans", client: client);

      getPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();
    });

    test('getAll() should return all objects', () async {
      // arrange

      const desiredOutput = {
        "results": [
          {
            "objectId": "lHJEkg7kxm",
            "Name": "Textbook",
            "Description":
                "For an active lifestyle and a straight forward macro plan, we suggest this plan.",
            "Fat": 25,
            "Carbs": 50,
            "Protein": 25,
            "Status": false,
            "user": {
              "__type": "Pointer",
              "className": "_User",
              "objectId": "cmWCmCAyQQ"
            },
            "createdAt": "2023-02-24T15:39:44.800Z",
            "updatedAt": "2023-02-24T22:28:17.867Z",
            "location": {"__type": "GeoPoint", "latitude": 50, "longitude": 0},
            "anArray": ["3", "4"]
          },
          {
            "objectId": "15NCdmBFBw",
            "Name": "Zone Diet",
            "Description":
                "Popular with CrossFit users. Zone Diet targets similar macros.",
            "Fat": 30,
            "Carbs": 40,
            "Protein": 30,
            "Status": true,
            "user": {
              "__type": "Pointer",
              "className": "_User",
              "objectId": "cmWCmCAyQQ"
            },
            "createdAt": "2023-02-24T15:44:17.781Z",
            "updatedAt": "2023-02-24T22:28:45.446Z",
            "location": {"__type": "GeoPoint", "latitude": 10, "longitude": 20},
            "anArray": ["1", "2"],
            "afile": {
              "__type": "File",
              "name": "33b6acb416c0mmer-wallpapers.png",
              "url": "https://parsefiles.back4app.com/gyBkQBRSapgwfxB/cers.png"
            }
          }
        ]
      };

      when(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(desiredOutput),
          ));

      // act
      ParseResponse response = await dietPlansObject.getAll();

      // assert
      List<ParseObject> listParseObject = List<ParseObject>.from(
        response.results!,
      );

      expect(response.results?.first, isA<ParseObject>());

      expect(response.count, equals(2));

      expect(
        listParseObject.length,
        equals(desiredOutput["results"]!.length),
      );

      verify(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('getAll() should return error', () async {
      // arrange

      final error = Exception('error');

      when(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenThrow(error);

      // act
      ParseResponse response = await dietPlansObject.getAll();

      // assert
      expect(response.success, isFalse);

      expect(response.result, isNull);

      expect(response.count, isZero);

      expect(response.results, isNull);

      expect(response.error, isNotNull);

      expect(response.error!.exception, equals(error));

      expect(response.error!.code, equals(-1));

      verify(client.get(
        getPath,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).called(1);

      verifyNoMoreInteractions(client);
    });
  });
}
