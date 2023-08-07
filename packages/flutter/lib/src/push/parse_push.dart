part of flutter_parse_sdk_flutter;

/// A class that provides a mechanism for handling push notifications in the app.
class ParsePush {
  static final ParsePush instance = ParsePush._internal();

  static String keyType = "gcm";
  static String keyPushType = 'pushType';

  late ParseNotification _parseNotification;

  factory ParsePush() {
    return instance;
  }

  ParsePush._internal();

  /// Initialize ParsePush; for web a [vapidKey] is required.
  Future<void> initialize(
    firebaseMessaging, {
    String? vapidKey,
    required ParseNotification parseNotification,
  }) async {
    _parseNotification = parseNotification;

    // Get Google Cloud Messaging (GCM) token
    firebaseMessaging
        .getToken(vapidKey: vapidKey)
        .asStream()
        .listen((event) async {
      // Set token in installation
      sdk.ParseInstallation parseInstallation =
          await sdk.ParseInstallation.currentInstallation();

      parseInstallation.deviceToken = event;
      parseInstallation.set(keyPushType, keyType);

      await parseInstallation.save();
    });
  }

  /// Handle push notification message
  void onMessage(message) {
    String pushId = message.data["push_id"] ?? "";
    String timestamp = message.data["time"] ?? "";
    String dataString = message.data["data"] ?? "";
    String channel = message.data["channel"] ?? "";

    Map<String, dynamic>? data;
    try {
      data = json.decode(dataString);
    } catch (_) {}

    _handlePush(pushId, timestamp, channel, data);
  }

  /// Processes the incoming push notification message.
  void _handlePush(String pushId, String timestamp, String channel,
      Map<String, dynamic>? data) {
    if (pushId.isEmpty || timestamp.isEmpty) {
      return;
    }

    if (data != null) {
      // Show push notification
      _parseNotification.showNotification(data["alert"]);
    }
  }

  /// Subscribes the device to a channel of push notifications
  Future<void> subscribeToChannel(String value) async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    await parseInstallation.subscribeToChannel(value);
  }

  /// Unsubscribes the device to a channel of push notifications
  Future<void> unsubscribeFromChannel(String value) async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    await parseInstallation.unsubscribeFromChannel(value);
  }

  /// Returns an <List<String>> containing all the channel names this device is subscribed to
  Future<List<dynamic>> getSubscribedChannels() async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    return await parseInstallation.getSubscribedChannels();
  }
}
