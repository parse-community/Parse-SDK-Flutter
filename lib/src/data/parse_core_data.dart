part of flutter_parse_sdk;

/// Singleton class that defines all user keys and data
class ParseCoreData {

  factory ParseCoreData() => _instance;

  ParseCoreData._init(this.applicationId, this.serverUrl);

  static ParseCoreData _instance;

  static ParseCoreData get instance => _instance;

  /// Creates an instance of Parse Server
  ///
  /// This class should not be user unless switching servers during the app,
  /// which is odd. Should only be user by Parse.init
  static void init(String appId, String serverUrl,
      {bool debug,
      String appName,
      String liveQueryUrl,
      String masterKey,
      String clientKey,
      String sessionId,
      bool autoSendSessionId,
      SecurityContext securityContext}) {
    _instance = ParseCoreData._init(appId, serverUrl);

    if (debug != null)
      _instance.debug = debug;
    if (appName != null)
      _instance.appName = appName;
    if (liveQueryUrl != null)
      _instance.liveQueryURL = liveQueryUrl;
    if (clientKey != null)
      _instance.clientKey = clientKey;
    if (masterKey != null)
      _instance.masterKey = masterKey;
    if (sessionId != null)
      _instance.sessionId = sessionId;
    if (autoSendSessionId != null)
      _instance.autoSendSessionId = autoSendSessionId;
    if (securityContext != null)
      _instance.securityContext = securityContext;
  }

  String appName;
  String applicationId;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String clientKey;
  String sessionId;
  bool autoSendSessionId;
  SecurityContext securityContext;
  bool debug;
  SharedPreferences storage;

  /// Sets the current sessionId.
  ///
  /// This is generated when a users logs in, or calls currentUser to update
  /// their keys
  void setSessionId(String sessionId) {
    this.sessionId = sessionId;
  }

  Future<SharedPreferences> getStore() async {
    return storage ?? (storage = await SharedPreferences.getInstance());
  }

  @override
  String toString() => '$applicationId $masterKey';
}
