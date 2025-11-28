import 'package:mockito/annotations.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../test_utils.dart';

@GenerateMocks([ParseClient])
void main() {
  test('The parseClassName property in the ParseObject class should be equal '
      'to the name passed via the constructor', () async {
    // arrange

    await initializeParse();

    const className = 'Diet_Plans';

    // act
    final dietPlansObject = ParseObject(className);

    // assert
    expect(dietPlansObject.parseClassName, equals(className));
  });
}
