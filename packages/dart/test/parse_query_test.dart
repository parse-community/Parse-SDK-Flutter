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
  });
}
