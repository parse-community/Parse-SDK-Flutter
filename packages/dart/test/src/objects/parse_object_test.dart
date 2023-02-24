import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../parse_query_test.mocks.dart';

@GenerateMocks([ParseClient])
void main() {
  group('parseObject', () {
    late MockParseClient client;
    setUp(() async {
      client = MockParseClient();

      await Parse().initialize(
        'appId',
        'https://example.com',
        debug: true,
        // to prevent automatic detection
        fileDirectory: 'someDirectory',
        // to prevent automatic detection
        appName: 'appName',
        // to prevent automatic detection
        appPackageName: 'somePackageName',
        // to prevent automatic detection
        appVersion: 'someAppVersion',
      );
    });

    test('should return expectedIncludeResult json when use fetch', () async {
      // arrange
      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      var desiredOutput = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            "phone": "+12025550463",
            "createdAt": "2022-09-04T13:35:20.883Z",
            "updatedAt": "2022-11-14T10:55:56.202Z",
            "img": {
              "objectId": "8nGrLj3Mvk",
              "size": "67663",
              "mime": "image/jpg",
              "file": {
                "__type": "File",
                "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
                "url":
                    "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
              },
              "createdAt": "2022-11-14T10:55:56.025Z",
              "updatedAt": "2022-11-14T10:55:56.025Z",
              "__type": "Object",
              "className": "MyFile",
            },
          }
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      ParseObject parseObject = await myUserObject.fetch(include: ["img"]);

      var objectDesiredOutput = {
        "className": "MyFile",
        "objectId": "8nGrLj3Mvk",
        "createdAt": "2022-11-14T10:55:56.025Z",
        "updatedAt": "2022-11-14T10:55:56.025Z",
        "size": "67663",
        "mime": "image/jpg",
        "file": {
          "__type": "File",
          "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
          "url":
              "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
        },
      };
      var objectJsonDesiredOutput = jsonEncode(objectDesiredOutput);

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(
          jsonEncode(
              parseEncode(parseObject.get<ParseObject>('img'), full: true)),
          objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.query), 'include=img');
    });

    test('should return expectedIncludeResult json when use getObject',
        () async {
      // arrange
      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      var desiredOutput = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            "phone": "+12025550463",
            "createdAt": "2022-09-04T13:35:20.883Z",
            "updatedAt": "2022-11-14T10:55:56.202Z",
            "img": {
              "objectId": "8nGrLj3Mvk",
              "size": "67663",
              "mime": "image/jpg",
              "file": {
                "__type": "File",
                "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
                "url":
                    "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
              },
              "createdAt": "2022-11-14T10:55:56.025Z",
              "updatedAt": "2022-11-14T10:55:56.025Z",
              "__type": "Object",
              "className": "MyFile",
            },
          }
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      ParseResponse response =
          await myUserObject.getObject("Mn1iJTkWTE", include: ["img"]);

      ParseObject parseObject = response.results?.first;

      var objectDesiredOutput = {
        "className": "MyFile",
        "objectId": "8nGrLj3Mvk",
        "createdAt": "2022-11-14T10:55:56.025Z",
        "updatedAt": "2022-11-14T10:55:56.025Z",
        "size": "67663",
        "mime": "image/jpg",
        "file": {
          "__type": "File",
          "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
          "url":
              "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
        },
      };
      var objectJsonDesiredOutput = jsonEncode(objectDesiredOutput);

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(
          jsonEncode(
              parseEncode(parseObject.get<ParseObject>('img'), full: true)),
          objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.query), 'include=img');
    });

    group('getAll()', () {
      test('getAll() should return all objects', () async {
        // arrange
        ParseObject dietPlansObject = ParseObject("Diet_Plans", client: client);

        var desiredOutput = {
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
              "location": {
                "__type": "GeoPoint",
                "latitude": 50,
                "longitude": 0
              },
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
              "location": {
                "__type": "GeoPoint",
                "latitude": 10,
                "longitude": 20
              },
              "anArray": ["1", "2"],
              "afile": {
                "__type": "File",
                "name": "33b6acb416c0mmer-wallpapers.png",
                "url":
                    "https://parsefiles.back4app.com/gyBkQBRSapgwfxB/cers.png"
              }
            }
          ]
        };

        when(client.get(
          any,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).thenAnswer((_) async => ParseNetworkResponse(
            statusCode: 200, data: jsonEncode(desiredOutput)));

        // act
        ParseResponse response = await dietPlansObject.getAll();

        // assert
        List<ParseObject> listParseObject = List<ParseObject>.from(
          response.results!,
        );

        expect(response.results?.first, isA<ParseObject>());

        expect(
            listParseObject.length, equals(desiredOutput["results"]!.length));

        verify(client.get(
          captureAny,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).called(1);

        verifyNoMoreInteractions(client);
      });
      test('getAll() should return error', () async {
        // arrange
        ParseObject dietPlansObject = ParseObject("Diet_Plans", client: client);

        final error = Exception('error');

        when(client.get(
          any,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).thenThrow(error);

        // act
        ParseResponse response = await dietPlansObject.getAll();

        // assert

        expect(response.results, isNull);
        expect(response.error, isNotNull);
        expect(response.error!.exception, equals(error));
        expect(response.error!.code, equals(-1));

        verify(client.get(
          captureAny,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).called(1);

        verifyNoMoreInteractions(client);
      });
    });
  });
}
