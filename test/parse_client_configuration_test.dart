import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues(Map<String, String>());

  test('testBuilder', () async {
    await Parse().initialize('appId', 'serverUrl',
        clientKey: 'clientKey',
        liveQueryUrl: 'liveQueryUrl',
        appName: 'appName',
        masterKey: 'masterKey',
        sessionId: 'sessionId',
        debug: true);

    expect(ParseCoreData().applicationId, 'appId');
    expect(ParseCoreData().serverUrl, 'serverUrl');
    expect(ParseCoreData().clientKey, 'clientKey');
    expect(ParseCoreData().liveQueryURL, 'liveQueryUrl');
    expect(ParseCoreData().appName, 'appName');
    expect(ParseCoreData().masterKey, 'masterKey');
    expect(ParseCoreData().sessionId, 'sessionId');
    expect(ParseCoreData().debug, true);
  });
}
