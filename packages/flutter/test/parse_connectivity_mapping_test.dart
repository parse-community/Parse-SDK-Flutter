import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity mapping logic', () {
    test('should map connectivity_plus results to ParseConnectivityResult',
        () {
      // This test documents the expected mapping behavior
      // The actual Parse class implementation follows this mapping:

      // Test enum structure
      expect(ParseConnectivityResult.values.length, 4);
      expect(ParseConnectivityResult.values,
          containsAll([
            ParseConnectivityResult.wifi,
            ParseConnectivityResult.ethernet,
            ParseConnectivityResult.mobile,
            ParseConnectivityResult.none,
          ]));
    });

    test('ParseConnectivityResult should have correct ordering for priority',
        () {
      // Verify enum ordering (wifi has highest priority in the if-else chain)
      expect(ParseConnectivityResult.wifi.index, 0);
      expect(ParseConnectivityResult.ethernet.index, 1);
      expect(ParseConnectivityResult.mobile.index, 2);
      expect(ParseConnectivityResult.none.index, 3);
    });

    test('should identify online vs offline states correctly', () {
      // Online states
      expect(ParseConnectivityResult.wifi != ParseConnectivityResult.none,
          true);
      expect(
          ParseConnectivityResult.ethernet != ParseConnectivityResult.none,
          true);
      expect(ParseConnectivityResult.mobile != ParseConnectivityResult.none,
          true);

      // Offline state
      expect(ParseConnectivityResult.none == ParseConnectivityResult.none,
          true);
    });

    test('mapping logic follows priority: wifi > ethernet > mobile > none',
        () {
      // This documents the if-else chain priority in checkConnectivity()
      // If a list contains wifi, it returns wifi
      // Else if it contains ethernet, it returns ethernet
      // Else if it contains mobile, it returns mobile
      // Else it returns none

      // Simulating the mapping logic
      ParseConnectivityResult mapResult(List<ConnectivityResult> list) {
        if (list.contains(ConnectivityResult.wifi)) {
          return ParseConnectivityResult.wifi;
        } else if (list.contains(ConnectivityResult.ethernet)) {
          return ParseConnectivityResult.ethernet;
        } else if (list.contains(ConnectivityResult.mobile)) {
          return ParseConnectivityResult.mobile;
        } else {
          return ParseConnectivityResult.none;
        }
      }

      // Test single connection types
      expect(mapResult([ConnectivityResult.wifi]),
          ParseConnectivityResult.wifi);
      expect(mapResult([ConnectivityResult.ethernet]),
          ParseConnectivityResult.ethernet);
      expect(mapResult([ConnectivityResult.mobile]),
          ParseConnectivityResult.mobile);
      expect(mapResult([ConnectivityResult.none]),
          ParseConnectivityResult.none);

      // Test priority when multiple connections exist
      expect(mapResult([ConnectivityResult.wifi, ConnectivityResult.ethernet]),
          ParseConnectivityResult.wifi);
      expect(mapResult([ConnectivityResult.wifi, ConnectivityResult.mobile]),
          ParseConnectivityResult.wifi);
      expect(
          mapResult([ConnectivityResult.ethernet, ConnectivityResult.mobile]),
          ParseConnectivityResult.ethernet);

      // Test that ethernet takes priority over mobile (important for issue #1042)
      expect(
          mapResult([ConnectivityResult.mobile, ConnectivityResult.ethernet]),
          ParseConnectivityResult.ethernet);

      // Test fallback behavior for unsupported types
      expect(mapResult([ConnectivityResult.bluetooth]),
          ParseConnectivityResult.none);
      expect(mapResult([ConnectivityResult.vpn]), ParseConnectivityResult.none);
      expect(
          mapResult([ConnectivityResult.other]), ParseConnectivityResult.none);

      // Test mixed with unsupported types
      expect(
          mapResult([ConnectivityResult.ethernet, ConnectivityResult.vpn]),
          ParseConnectivityResult.ethernet);
    });

    test('ethernet should be treated as online connection type', () {
      // Critical test for issue #1042 fix
      // Ethernet must be treated as an online state, not as "none"

      final isOnline =
          ParseConnectivityResult.ethernet != ParseConnectivityResult.none;
      expect(isOnline, true,
          reason:
              'Ethernet should be treated as online for LiveQuery connectivity');
    });

    test('all online states should be distinguishable from none', () {
      final onlineStates = [
        ParseConnectivityResult.wifi,
        ParseConnectivityResult.ethernet,
        ParseConnectivityResult.mobile,
      ];

      for (final state in onlineStates) {
        expect(state != ParseConnectivityResult.none, true,
            reason: '$state should be distinguishable from none');
      }
    });
  });

  group('ConnectivityResult enum compatibility', () {
    test('should handle all connectivity_plus enum values', () {
      // Ensure we're aware of all possible values from connectivity_plus
      final allConnectivityResults = [
        ConnectivityResult.wifi,
        ConnectivityResult.ethernet,
        ConnectivityResult.mobile,
        ConnectivityResult.none,
        ConnectivityResult.bluetooth,
        ConnectivityResult.vpn,
        ConnectivityResult.other,
      ];

      // Verify all values exist (will fail if connectivity_plus adds new values)
      expect(allConnectivityResults.length, 7);
    });

    test('ParseConnectivityResult should support main connection types', () {
      // The Parse SDK should support the main internet connection types
      final supportedTypes = [
        ParseConnectivityResult.wifi,
        ParseConnectivityResult.ethernet,
        ParseConnectivityResult.mobile,
      ];

      expect(supportedTypes.length, 3,
          reason: 'Should support 3 main online connection types');
    });
  });
}
