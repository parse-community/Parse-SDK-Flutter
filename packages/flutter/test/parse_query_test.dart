import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockClient extends Mock implements ParseHTTPClient {}

void main() {
  SharedPreferences.setMockInitialValues(Map<String, String>());

  group('queryBuilder', () {
    test('whereRelatedTo', () async {
      final MockClient client = MockClient();

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

      when(client.data).thenReturn(ParseCoreData());
      await queryBuilder.query();

      final Uri result =
          Uri.parse(verify(client.get<String>(captureAny)).captured.single);

      expect(result.path, '/classes/_User');

      final Uri expectedQuery = Uri(
          query:
              'where={"\$relatedTo":{"object":{"__type":"Pointer","className":"Post","objectId":"8TOXdXf3tz"},"key":"likes"}}');
      expect(result.query, expectedQuery.query);
    });
  });
}
