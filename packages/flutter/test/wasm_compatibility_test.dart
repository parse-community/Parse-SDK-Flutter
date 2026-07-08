/// Smoke test to verify the package compiles and runs in WASM.
///
/// This test does not use platform plugins (shared_preferences,
/// connectivity_plus, path_provider) which may have WASM compatibility issues.
/// Tests that require platform plugins use @TestOn('vm') to skip WASM.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() {
  test('ParseConnectivityResult enum values are accessible', () {
    expect(ParseConnectivityResult.wifi, isNotNull);
    expect(ParseConnectivityResult.mobile, isNotNull);
    expect(ParseConnectivityResult.ethernet, isNotNull);
    expect(ParseConnectivityResult.none, isNotNull);
  });
}
