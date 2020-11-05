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
  static Future<void> init(
    String appId,
    String serverUrl, {
    bool debug,
    String appName,
    String appVersion,
    String appPackageName,
    String locale,
    String liveQueryUrl,
    String masterKey,
    String clientKey,
    String sessionId,
    bool autoSendSessionId,
    SecurityContext securityContext,
    CoreStore store,
    Map<String, ParseObjectConstructor> registeredSubClassMap,
    ParseUserConstructor parseUserConstructor,
    ParseFileConstructor parseFileConstructor,
    List<int> liveListRetryIntervals,
    ParseConnectivityProvider connectivityProvider,
    String fileDirectory,
    Stream<void> appResumedStream,
  }) async {
    _instance = ParseCoreData._init(appId, serverUrl);

    _instance.storage ??= store ?? CoreStoreMemoryImp();

    if (debug != null) {
      _instance.debug = debug;
    }
    if (appName != null) {
      _instance.appName = appName;
    }
    if (appVersion != null) {
      _instance.appVersion = appVersion;
    }
    if (appPackageName != null) {
      _instance.appPackageName = appPackageName;
    }
    if (locale != null) {
      _instance.locale = locale;
    }
    if (liveQueryUrl != null) {
      _instance.liveQueryURL = liveQueryUrl;
    }
    if (clientKey != null) {
      _instance.clientKey = clientKey;
    }
    if (masterKey != null) {
      _instance.masterKey = masterKey;
    }
    if (sessionId != null) {
      _instance.sessionId = sessionId;
    }
    if (autoSendSessionId != null) {
      _instance.autoSendSessionId = autoSendSessionId;
    }
    if (securityContext != null) {
      _instance.securityContext = securityContext;
    }
    if (liveListRetryIntervals != null) {
      _instance.liveListRetryIntervals = liveListRetryIntervals;
    } else {
      _instance.liveListRetryIntervals = parseIsWeb
          ? <int>[0, 500, 1000, 2000, 5000]
          : <int>[0, 500, 1000, 2000, 5000, 10000];
    }

    _instance._subClassHandler = ParseSubClassHandler(
      registeredSubClassMap: registeredSubClassMap,
      parseUserConstructor: parseUserConstructor,
      parseFileConstructor: parseFileConstructor,
    );
    if (connectivityProvider != null) {
      _instance.connectivityProvider = connectivityProvider;
    }

    if (fileDirectory != null) {
      _instance.fileDirectory = fileDirectory;
    }

    if (appResumedStream != null) {
      _instance.appResumedStream = appResumedStream;
    }
  }

  String appName;
  String appVersion;
  String appPackageName;
  String applicationId;
  String locale;
  String serverUrl;
  String liveQueryURL;
  String masterKey;
  String clientKey;
  String sessionId;
  bool autoSendSessionId;
  SecurityContext securityContext;
  bool debug;
  CoreStore storage;
  ParseSubClassHandler _subClassHandler;
  List<int> liveListRetryIntervals;
  ParseConnectivityProvider connectivityProvider;
  String fileDirectory;
  Stream<void> appResumedStream;

  void registerSubClass(
      String className, ParseObjectConstructor objectConstructor) {
    _subClassHandler.registerSubClass(className, objectConstructor);
  }

  void registerUserSubClass(ParseUserConstructor parseUserConstructor) {
    _subClassHandler.registerUserSubClass(parseUserConstructor);
  }

  void registerFileSubClass(ParseFileConstructor parseFileConstructor) {
    _subClassHandler.registerFileSubClass(parseFileConstructor);
  }

  ParseObject createObject(String classname) {
    return _subClassHandler.createObject(classname);
  }

  ParseUser createParseUser(
      String username, String password, String emailAddress,
      {String sessionToken, bool debug, ParseHTTPClient client}) {
    return _subClassHandler.createParseUser(username, password, emailAddress,
        sessionToken: sessionToken, debug: debug, client: client);
  }

  ParseFileBase createFile({String url, String name}) =>
      _subClassHandler.createFile(name: name, url: url);

  /// Sets the current sessionId.
  ///
  /// This is generated when a users logs in, or calls currentUser to update
  /// their keys
  void setSessionId(String sessionId) {
    this.sessionId = sessionId;
  }

  CoreStore getStore() {
    return storage;
  }

  @override
  String toString() => '$applicationId $masterKey';
}
