class ParseData {
  static ParseData _instance;

  static ParseData get instance => _instance;

  static void init(appId, serverUrl, {liveQueryUrl, masterKey, sessionId}) =>
      _instance ??= ParseData._init(appId, serverUrl, liveQueryUrl, masterKey, sessionId);

  String applicationId;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String sessionId;

  ParseData._init(this.applicationId, this.serverUrl, [this.liveQueryURL, this.masterKey, this.sessionId]);

  factory ParseData() => _instance;

  @override
  String toString() => "$applicationId $masterKey";
}
