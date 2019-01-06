class ParseDataServer {
  static ParseDataServer _instance;
  static ParseDataServer get instance => _instance;

  static void init(appId, serverUrl, {debug, appName, liveQueryUrl, masterKey, sessionId}){
      _instance = ParseDataServer._init(appId, serverUrl);

      if (debug != null) _instance.debug = debug;
      if (appName != null) _instance.appName = appName;
      if (liveQueryUrl != null) _instance.liveQueryURL = liveQueryUrl;
      if (masterKey != null) _instance.masterKey = masterKey;
      if (sessionId != null) _instance.sessionId = sessionId;
  }

  String appName;
  String applicationId;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String sessionId;
  bool debug;

  ParseDataServer._init(
      this.applicationId,
      this.serverUrl);

  factory ParseDataServer() => _instance;

  void setSessionId(String sessionId){
    this.sessionId = sessionId;
  }

  @override
  String toString() => "$applicationId $masterKey";
}
