import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  test('should return true for exist TimeZone.', () async {
    // arrange
    await Parse().initialize(
      'appId',
      'https://example.com',
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

    // act
    final ParseInstallation installation =
        await ParseInstallation.currentInstallation();

    dynamic actualHasTimeZoneResult = installation.containsKey(keyTimeZone);

    // assert
    expect(actualHasTimeZoneResult, true);
  });
}
