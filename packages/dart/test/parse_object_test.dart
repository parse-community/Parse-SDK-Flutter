import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';
import 'parse_query_test.mocks.dart';

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
                "url": "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
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
      )).thenAnswer((_) async => ParseNetworkResponse(statusCode: 200, data: jsonEncode(desiredOutput)));

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
          "url": "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
        },
      };
      var objectJsonDesiredOutput = jsonEncode(objectDesiredOutput);

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(jsonEncode(parseEncode(parseObject.get<ParseObject>('img'), full: true)), objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.path), '/classes/MyUser/Mn1iJTkWTE?include=img');
    });

    test('should return expectedIncludeResult json when use getObject', () async {
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
                "url": "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
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
      )).thenAnswer((_) async => ParseNetworkResponse(statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      ParseResponse response = await myUserObject.getObject("Mn1iJTkWTE", include: ["img"]);

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
          "url": "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
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

      expect(jsonEncode(parseEncode(parseObject.get<ParseObject>('img'), full: true)), objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.path), '/classes/MyUser/Mn1iJTkWTE?include=img');
    });
  });
}
