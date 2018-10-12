class ParseDataServer {
  static ParseDataServer _instance;

  static ParseDataServer get instance => _instance;

  static void init(appId, serverUrl, {liveQueryUrl, masterKey, sessionId}) =>
      _instance ??= ParseDataServer._init(appId, serverUrl, liveQueryURL: liveQueryUrl, masterKey: masterKey, sessionId: sessionId);

  String applicationId;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String sessionId;

  ParseDataServer._init(this.applicationId, this.serverUrl,
      {this.liveQueryURL, this.masterKey, this.sessionId});

  factory ParseDataServer() => _instance;

  void setSessionId(String sessionId){
    this.sessionId = sessionId;
  }

  @override
  String toString() => "$applicationId $masterKey";
}
