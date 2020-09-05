part of flutter_parse_sdk;

/// Connection status check result.
enum ParseConnectivityResult {
  /// WiFi: Device connected via Wi-Fi
  wifi,

  /// Mobile: Device connected to cellular network
  mobile,

  /// None: Device not connected to any network
  none
}

abstract class ParseConnectivityProvider {
  Future<ParseConnectivityResult> checkConnectivity();
  Stream<ParseConnectivityResult> get connectivityStream;
}
