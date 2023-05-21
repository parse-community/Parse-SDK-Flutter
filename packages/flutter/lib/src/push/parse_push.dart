part of flutter_parse_sdk_flutter;

class ParsePush {
  static final ParsePush instance = ParsePush._internal();
  static String keyType = "gcm";
  static String keyPushType = 'pushType';

  factory ParsePush() {
    return instance;
  }

  ParsePush._internal();

  Future<void> initialize(firebaseMessaging) async {
    // get GCM token
    firebaseMessaging.getToken().asStream().listen((event) async {
      // set token in ParseInstallation
      sdk.ParseInstallation parseInstallation =
          await sdk.ParseInstallation.currentInstallation();

      parseInstallation.deviceToken = event;
      parseInstallation.set(keyPushType, keyType);

      await parseInstallation.save();
    });
  }

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

  void _handlePush(String pushId, String timestamp, String channel,
      Map<String, dynamic>? data) {
    if (pushId.isEmpty || timestamp.isEmpty) {
      return;
    }

    if (data != null) {
      // show notification
      ParseNotification.instance.showNotification(data["alert"]);
    }
  }

  Future<void> subscribeToChannel(String value) async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    await parseInstallation.subscribeToChannel(value);
  }

  Future<void> unsubscribeFromChannel(String value) async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    await parseInstallation.unsubscribeFromChannel(value);
  }

  Future<List<dynamic>> getSubscribedChannels() async {
    sdk.ParseInstallation parseInstallation =
        await sdk.ParseInstallation.currentInstallation();

    return await parseInstallation.getSubscribedChannels();
  }
}
