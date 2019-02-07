part of flutter_parse_sdk;

/// Singleton class that defines all user keys and data
class ParseCoreData {
  static ParseCoreData _instance;

  static ParseCoreData get instance => _instance;

  /// Creates an instance of Parse Server
  ///
  /// This class should not be user unless switching servers during the app,
  /// which is odd. Should only be user by Parse.init
  static void init(appId, serverUrl,
      {debug, appName, liveQueryUrl, masterKey, clientKey, sessionId}) {
    _instance = ParseCoreData._init(appId, serverUrl);

    if (debug != null) _instance.debug = debug;
    if (appName != null) _instance.appName = appName;
    if (liveQueryUrl != null) _instance.liveQueryURL = liveQueryUrl;
    if (clientKey != null) _instance.clientKey = clientKey;
    if (masterKey != null) _instance.masterKey = masterKey;
    if (sessionId != null) _instance.sessionId = sessionId;
  }

  String appName;
  String applicationId;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String clientKey;
  String sessionId;
  bool debug;
  SharedPreferences storage;

  ParseCoreData._init(this.applicationId, this.serverUrl);

  factory ParseCoreData() => _instance;

  /// Sets the current sessionId.
  ///
  /// This is generated when a users logs in, or calls currentUser to update
  /// their keys
  void setSessionId(String sessionId) {
    this.sessionId = sessionId;
  }

  void initStorage() async {
    storage = await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> getStore() async {
    return storage != null ? storage : await SharedPreferences.getInstance();
  }

  @override
  String toString() => "$applicationId $masterKey";
}
