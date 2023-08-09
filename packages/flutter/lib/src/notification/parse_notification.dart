part of flutter_parse_sdk_flutter;

/// A class that provides a mechanism for showing system notifications in the app.
class ParseNotification {
  ParseNotification({required this.onShowNotification});

  final void Function(String value) onShowNotification;

  /// Show notification
  void showNotification(title) {
    onShowNotification.call(title);
  }
}
