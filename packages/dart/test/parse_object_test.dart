import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';
import 'parse_query_test.mocks.dart';

@GenerateMocks([ParseClient])
void main() {
  group('parseObject', () {
    test('should return expectedIncludeResult json when use fetch', () async {
      // arrange
      final MockParseClient client = MockParseClient();

      await Parse().initialize(
        'appId',
        'https://test.parse.com',
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

      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\":[{\"objectId\":\"Mn1iJTkWTE\",\"phone\":\"+12025550463\",\"createdAt\":\"2022-09-04T13:35:20.883Z\",\"updatedAt\":\"2022-11-14T10:55:56.202Z\",\"img\":{\"objectId\":\"8nGrLj3Mvk\",\"size\":67663,\"mime\":\"image/jpg\",\"file\":{\"__type\":\"File\",\"name\":\"dc7320ee9146ee19aed8997722fd4e3c.bin\",\"url\":\"http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin\"},\"createdAt\":\"2022-11-14T10:55:56.025Z\",\"updatedAt\":\"2022-11-14T10:55:56.025Z\",\"__type\":\"Object\",\"className\":\"MyFile\"}}]}"));

      // act
      ParseObject parseObject = await myUserObject.fetch(include: ["img"]);

      // desired output
      String expectedIncludeResult =
          '{className: MyFile, objectId: 8nGrLj3Mvk, createdAt: 2022-11-14T10:55:56.025Z, updatedAt: 2022-11-14T10:55:56.025Z, size: 67663, mime: image/jpg, file: {"__type":"File","name":"dc7320ee9146ee19aed8997722fd4e3c.bin","url":"http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin"}}';

      // asserts
      expect(
          parseEncode(parseObject.get<ParseObject>('img'), full: true)
              .toString(),
          expectedIncludeResult);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      // act
      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(Uri.decodeComponent(result.path),
          '/classes/MyUser/Mn1iJTkWTE?include=img');
    });

    test('should return expectedIncludeResult json when use getObject',
        () async {
      // arrange
      final MockParseClient client = MockParseClient();

      await Parse().initialize(
        'appId',
        'https://test.parse.com',
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

      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\":[{\"objectId\":\"Mn1iJTkWTE\",\"phone\":\"+12025550463\",\"createdAt\":\"2022-09-04T13:35:20.883Z\",\"updatedAt\":\"2022-11-14T10:55:56.202Z\",\"img\":{\"objectId\":\"8nGrLj3Mvk\",\"size\":67663,\"mime\":\"image/jpg\",\"file\":{\"__type\":\"File\",\"name\":\"dc7320ee9146ee19aed8997722fd4e3c.bin\",\"url\":\"http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin\"},\"createdAt\":\"2022-11-14T10:55:56.025Z\",\"updatedAt\":\"2022-11-14T10:55:56.025Z\",\"__type\":\"Object\",\"className\":\"MyFile\"}}]}"));

      // act
      ParseResponse response =
          await myUserObject.getObject("Mn1iJTkWTE", include: ["img"]);

      // asserts
      expect(response.results?.first, isA<ParseObject>());

      // get parseObject
      ParseObject parseObject = response.results?.first;

      // desired output
      String expectedIncludeResult =
          '{className: MyFile, objectId: 8nGrLj3Mvk, createdAt: 2022-11-14T10:55:56.025Z, updatedAt: 2022-11-14T10:55:56.025Z, size: 67663, mime: image/jpg, file: {"__type":"File","name":"dc7320ee9146ee19aed8997722fd4e3c.bin","url":"http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin"}}';

      // asserts
      expect(
          parseEncode(parseObject.get<ParseObject>('img'), full: true)
              .toString(),
          expectedIncludeResult);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      // act
      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(Uri.decodeComponent(result.path),
          '/classes/MyUser/Mn1iJTkWTE?include=img');
    });
  });
}
