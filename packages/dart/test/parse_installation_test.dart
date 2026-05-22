import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> _initParse() => Parse().initialize(
  'appId',
  'https://example.com',
  debug: true,
  fileDirectory: 'someDirectory',
  appName: 'appName',
  appPackageName: 'somePackageName',
  appVersion: 'someAppVersion',
);

void main() {
  setUpAll(() async {
    await _initParse();
  });

  test('installation has a timeZone field', () async {
    final installation = await ParseInstallation.currentInstallation();
    expect(installation.containsKey(keyTimeZone), isTrue);
  });

  // Regression: the SDK previously compared `int == Duration` when matching
  // offsets against the timezone database. On timezone <0.11.0 that's always
  // false, so the timeZone field was persisted as "". See
  // _getNameLocalTimeZone() in parse_installation.dart.
  test('installation timeZone is not empty', () async {
    final installation = await ParseInstallation.currentInstallation();
    final tzValue = installation.get<String>(keyTimeZone);
    expect(tzValue, isNotNull);
    expect(
      tzValue,
      isNotEmpty,
      reason: 'Regression: timeZone was being stored as "".',
    );
  });

  test('installation timeZone is an IANA name or the OS-reported name',
      () async {
    tz.initializeTimeZones();
    final installation = await ParseInstallation.currentInstallation();
    final tzValue = installation.get<String>(keyTimeZone)!;

    final bool isIana = tz.timeZoneDatabase.locations.containsKey(tzValue);
    final bool matchesSystem = tzValue == DateTime.now().timeZoneName;

    expect(
      isIana || matchesSystem,
      isTrue,
      reason:
          'timeZone "$tzValue" should be an IANA zone or the OS-reported '
          'name (fallback for Windows/Web).',
    );
  });

  test('when timeZone is matched via offset, its offset equals the local offset',
      () async {
    tz.initializeTimeZones();
    final installation = await ParseInstallation.currentInstallation();
    final tzValue = installation.get<String>(keyTimeZone)!;

    final location = tz.timeZoneDatabase.locations[tzValue];
    if (location == null) {
      // OS-reported, non-IANA fallback (Windows/Web). Nothing to verify.
      return;
    }

    final dynamic zoneOffset = location.currentTimeZone.offset;
    final int zoneOffsetMs = zoneOffset is Duration
        ? zoneOffset.inMilliseconds
        : zoneOffset as int;

    expect(zoneOffsetMs, equals(DateTime.now().timeZoneOffset.inMilliseconds));
  });
}
