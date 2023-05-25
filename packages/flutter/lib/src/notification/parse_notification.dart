part of flutter_parse_sdk_flutter;

/// A class that provides a mechanism for showing system notifications in the app.
class ParseNotification {
  static final ParseNotification instance = ParseNotification._internal();
  static String keyNotificationChannelName = "parse";

  factory ParseNotification() {
    return instance;
  }

  ParseNotification._internal() {
    // Initialize notifications helper package
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: keyNotificationChannelName,
            channelName: keyNotificationChannelName,
            channelDescription: 'Notification channel for parse')
      ],
    );
  }

  /// Show notification
  void showNotification(title) {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: Random().nextInt(1000),
      channelKey: keyNotificationChannelName,
      title: title,
    ));
  }
}
