import 'package:mockito/annotations.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

const serverUrl = 'https://example.com';

Future<void> initializeParse() async {
  await Parse().initialize(
    'appId',
    serverUrl,
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
}

@GenerateMocks([ParseClient])
void main() {
  test(
      'The parseClassName property in the ParseObject class should be equal '
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
