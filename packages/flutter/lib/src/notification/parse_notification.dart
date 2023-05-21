part of flutter_parse_sdk_flutter;

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

  void showNotification(title) {
    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: Random().nextInt(1000),
      channelKey: keyNotificationChannelName,
      title: title,
    ));
  }
}
