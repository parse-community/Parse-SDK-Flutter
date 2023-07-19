part of flutter_parse_sdk_flutter;

/// A class that provides a mechanism for showing system notifications in the app.
class ParseNotification {
  static final ParseNotification instance = ParseNotification._internal();
  static String keyNotificationChannelName = "parse";

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidInitializationSettings? _androidNotificationSettings;
  DarwinInitializationSettings? _iOSNotificationSettings;
  DarwinInitializationSettings? _macOSNotificationSettings;
  LinuxInitializationSettings? _linuxNotificationSettings;

  factory ParseNotification() {
    return instance;
  }

  ParseNotification._internal() {
    _initialize();
  }

  setNotificationSettings(
      {AndroidInitializationSettings? androidNotificationSettings,
      DarwinInitializationSettings? iOSNotificationSettings,
      DarwinInitializationSettings? macOSNotificationSettings,
      LinuxInitializationSettings? linuxNotificationSettings}) {
    _androidNotificationSettings = androidNotificationSettings;
    _iOSNotificationSettings = iOSNotificationSettings;
    _macOSNotificationSettings = macOSNotificationSettings;
    _linuxNotificationSettings = linuxNotificationSettings;
  }

  /// Initialize notification helper
  Future<void> _initialize() async {
    InitializationSettings initializationSettings = InitializationSettings(
        android: _androidNotificationSettings ??
            const AndroidInitializationSettings('launch_background'),
        iOS: _iOSNotificationSettings,
        linux: _linuxNotificationSettings,
        macOS: _macOSNotificationSettings);

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      keyNotificationChannelName, // id
      keyNotificationChannelName, // title
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Show notification
  void showNotification(title) {
    _flutterLocalNotificationsPlugin.show(
        Random().nextInt(1000),
        title,
        null,
        NotificationDetails(
          android: AndroidNotificationDetails(
            keyNotificationChannelName,
            keyNotificationChannelName,
            // other properties...
          ),
        ));
  }
}
