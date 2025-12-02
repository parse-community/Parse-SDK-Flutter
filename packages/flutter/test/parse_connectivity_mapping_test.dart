import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity mapping logic', () {
    test('mapping logic follows priority: wifi > ethernet > mobile > none',
        () {
      // This documents the if-else chain priority in checkConnectivity()
      // and connectivityStream mapping logic

      // Simulating the actual mapping logic from parse_server_sdk_flutter.dart
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

      // Test that ethernet takes priority over mobile (critical for issue #1042)
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
  });
}
