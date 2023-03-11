import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('testBuilder', () async {
    // arrange
    await Parse().initialize(
      'appId',
      'serverUrl',
      clientKey: 'clientKey',
      liveQueryUrl: 'liveQueryUrl',
      appName: 'appName',
      appPackageName: 'somePackageName',
      appVersion: 'someAppVersion',
      masterKey: 'masterKey',
      sessionId: 'sessionId',
      fileDirectory: 'someDirectory',
      debug: true,
    );

    // assert
    expect(ParseCoreData().applicationId, 'appId');
    expect(ParseCoreData().serverUrl, 'serverUrl');
    expect(ParseCoreData().clientKey, 'clientKey');
    expect(ParseCoreData().liveQueryURL, 'liveQueryUrl');
    expect(ParseCoreData().appName, 'appName');
    expect(ParseCoreData().appPackageName, 'somePackageName');
    expect(ParseCoreData().appVersion, 'someAppVersion');
    expect(ParseCoreData().masterKey, 'masterKey');
    expect(ParseCoreData().sessionId, 'sessionId');
    expect(ParseCoreData().debug, true);
    expect(ParseCoreData().fileDirectory, 'someDirectory');
  });
}
