import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues(<String, String>{});

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
      restRetryIntervals: [100, 200, 300],
      restRetryIntervalsForWrites: [500, 1000],
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
    expect(ParseCoreData().restRetryIntervals, [100, 200, 300]);
    expect(ParseCoreData().restRetryIntervalsForWrites, [500, 1000]);
  });

  test('testDefaultValues', () async {
    // arrange - initialize with only required parameters
    await Parse().initialize(
      'appId',
      'serverUrl',
      appName: 'appName',
      appPackageName: 'somePackageName',
      appVersion: 'someAppVersion',
    );

    // assert - verify default values are used
    expect(ParseCoreData().applicationId, 'appId');
    expect(ParseCoreData().serverUrl, 'serverUrl');
    expect(ParseCoreData().debug, false); // default
    expect(ParseCoreData().autoSendSessionId, true); // default
    expect(ParseCoreData().clientKey, null); // not provided
    expect(ParseCoreData().masterKey, null); // not provided
    expect(ParseCoreData().sessionId, null); // not provided
    expect(ParseCoreData().liveQueryURL, null); // not provided
    expect(ParseCoreData().restRetryIntervals, [0, 250, 500, 1000, 2000]);
    expect(ParseCoreData().restRetryIntervalsForWrites, <int>[]);
  });
}
