import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues(Map<String, String>());

  test('testBuilder', () async {
    await Parse().initialize('appId', 'serverUrl',
        clientKey: 'clientKey',
        liveQueryUrl: 'liveQueryUrl',
        appName: 'appName',
        appPackageName: 'somePackageName',
        appVersion: 'someAppVersion',
        masterKey: 'masterKey',
        sessionId: 'sessionId',
        fileDirectory: 'someDirectory',
        debug: true);

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
