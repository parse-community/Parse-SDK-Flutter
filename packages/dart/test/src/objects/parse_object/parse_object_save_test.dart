import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  // TODO: add tests for save funcion
  group('save()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });
  });
}
