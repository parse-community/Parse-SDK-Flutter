import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import 'parse_query_test.mocks.dart';

@GenerateMocks([ParseClient])
void main() {
  group('queryBuilder', () {
    test('whereRelatedTo', () async {
      final MockParseClient client = MockParseClient();

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

      final QueryBuilder<ParseObject> queryBuilder =
          QueryBuilder<ParseObject>(ParseObject('_User', client: client));
      queryBuilder.whereRelatedTo('likes', 'Post', '8TOXdXf3tz');

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\":[{\"objectId\":\"eT9muOxBTJ\",\"username\":\"test\",\"createdAt\":\"2021-04-23T13:46:06.092Z\",\"updatedAt\":\"2021-04-23T13:46:23.586Z\",\"ACL\":{\"*\":{\"read\":true},\"eT9muOxBTJ\":{\"read\":true,\"write\":true}}}]}"));

      ParseResponse response = await queryBuilder.query();

      expect(response.results?.first, isA<ParseObject>());

      ParseObject parseObject = response.results?.first;

      expect(parseObject.get<String>(keyVarUsername), "test");
      expect(parseObject.objectId, "eT9muOxBTJ");
      expect(parseObject.createdAt, DateTime.parse("2021-04-23T13:46:06.092Z"));
      expect(parseObject.updatedAt, DateTime.parse("2021-04-23T13:46:23.586Z"));

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      expect(result.path, '/classes/_User');

      final Uri expectedQuery = Uri(
          query:
              'where={"\$relatedTo":{"object":{"__type":"Pointer","className":"Post","objectId":"8TOXdXf3tz"},"key":"likes"}}');
      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.or', () async {
      final MockParseClient client = MockParseClient();

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

      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "Liam");

      var lastName = QueryBuilder<ParseObject>(user)
        ..regEx('lastName', "Johnson");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.or(
        user,
        [firstName, lastName],
      );

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\": [{\"className\": \"_User\",\"objectId\": \"fqx5BECOME\",\"createdAt\": \"2022-10-25T06:04:47.138Z\",\"updatedAt\": \"2022-10-25T06:05:22.328Z\",\"firstName\": \"Liam1\",\"lastName\": \"Johnson1\"},{\"className\": \"_User\",\"objectId\": \"hAtRRYGrUO\",\"createdAt\": \"2022-01-24T15:53:48.396Z\",\"updatedAt\": \"2022-01-25T05:52:01.701Z\",\"firstName\": \"Liam2\",\"lastName\": \"Johnson2\"}]}"));

      var response = await mainQuery.query();

      expect(response.results?.first, isA<ParseObject>());

      ParseObject parseObject = response.results?.first;

      expect(parseObject.get<String>("firstName"), "Liam1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      expect(result.path, '/classes/_User');

      final Uri expectedQuery = Uri(
          query:
              'where={"\$or":[{"firstName":{"\$regex":"Liam"}},{"lastName":{"\$regex":"Johnson"}}]}');
      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.and', () async {
      final MockParseClient client = MockParseClient();

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

      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "jak");

      var lastName = QueryBuilder<ParseObject>(user)..regEx('lastName', "jaki");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.and(
        user,
        [firstName, lastName],
      );

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\": [{\"className\": \"_User\",\"objectId\": \"fqx5BECOME\",\"createdAt\": \"2022-10-25T06:04:47.138Z\",\"updatedAt\": \"2022-10-25T06:05:22.328Z\",\"firstName\": \"jak1\",\"lastName\": \"jaki1\"},{\"className\": \"_User\",\"objectId\": \"hAtRRYGrUO\",\"createdAt\": \"2022-01-24T15:53:48.396Z\",\"updatedAt\": \"2022-01-25T05:52:01.701Z\",\"firstName\": \"jak2\",\"lastName\": \"jaki2\"}]}"));

      var response = await mainQuery.query();

      expect(response.results?.first, isA<ParseObject>());

      ParseObject parseObject = response.results?.first;

      expect(parseObject.get<String>("firstName"), "jak1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      expect(result.path, '/classes/_User');

      final Uri expectedQuery = Uri(
          query:
              'where={"\$and":[{"firstName":{"\$regex":"jak"}},{"lastName":{"\$regex":"jaki"}}]}');
      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.nor', () async {
      final MockParseClient client = MockParseClient();

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

      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "Oliver");

      var lastName = QueryBuilder<ParseObject>(user)
        ..regEx('lastName', "Smith");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.nor(
        user,
        [firstName, lastName],
      );

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200,
          data:
              "{\"results\": [{\"className\": \"_User\",\"objectId\": \"fqx5BECOME\",\"createdAt\": \"2022-10-25T06:04:47.138Z\",\"updatedAt\": \"2022-10-25T06:05:22.328Z\",\"firstName\": \"Oliver1\",\"lastName\": \"Smith1\"},{\"className\": \"_User\",\"objectId\": \"hAtRRYGrUO\",\"createdAt\": \"2022-01-24T15:53:48.396Z\",\"updatedAt\": \"2022-01-25T05:52:01.701Z\",\"firstName\": \"Oliver2\",\"lastName\": \"Smith2\"}]}"));

      var response = await mainQuery.query();

      expect(response.results?.first, isA<ParseObject>());

      ParseObject parseObject = response.results?.first;

      expect(parseObject.get<String>("firstName"), "Oliver1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      expect(result.path, '/classes/_User');

      final Uri expectedQuery = Uri(
          query:
              'where={"\$nor":[{"firstName":{"\$regex":"Oliver"}},{"lastName":{"\$regex":"Smith"}}]}');
      expect(result.query, expectedQuery.query);
    });
  });
}
