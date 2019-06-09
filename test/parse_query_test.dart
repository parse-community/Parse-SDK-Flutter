import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

class MockClient extends Mock implements ParseHTTPClient {}

void main() {
  group("queryBuilder", () {
    test('whereRelatedTo', () async {
      final client = MockClient();

      Parse().initialize('appId', 'https://test.parse.com', debug: true);

      var queryBuilder =
          QueryBuilder<ParseObject>(ParseObject('_User', client: client));
      queryBuilder.whereRelatedTo('likes', 'Post', '8TOXdXf3tz');

      when(client.data).thenReturn(ParseCoreData());
      await queryBuilder.query();

      Uri result = (verify(client.get(captureAny)).captured.single as Uri);

      expect(result.path, "/classes/_User");

      Uri expectedQuery = Uri(
          query:
              'where={"\$relatedTo":{"object":{"__type":"Pointer","className":"Post","objectId":"8TOXdXf3tz"},"key":"likes"}}');
      expect(result.query, expectedQuery.query);
    });
  });
}
