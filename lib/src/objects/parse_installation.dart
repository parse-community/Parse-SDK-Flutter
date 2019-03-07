part of flutter_parse_sdk;

class ParseInstallation extends ParseObject {
  static final String keyTimeZone = 'timeZone';
  static final String keyLocaleIdentifier = 'localeIdentifier';
  static final String keyDeviceToken = 'deviceToken';
  static final String keyDeviceType = 'deviceType';
  static final String keyInstallationId = 'installationId';
  static final String keyAppName = 'appName';
  static final String keyAppVersion = 'appVersion';
  static final String keyAppIdentifier = 'appIdentifier';
  static final String keyParseVersion = 'parseVersion';
  static final List<String> readOnlyKeys = [ //TODO
    keyDeviceToken, keyDeviceType, keyInstallationId,
    keyAppName, keyAppVersion, keyAppIdentifier, keyParseVersion
  ];
  static String _currentInstallationId;

  //Getters/setters

  Map get acl => super.get<Map>(keyVarAcl);

  set acl(Map acl) => set<Map>(keyVarAcl, acl);

  String get deviceToken => super.get<String>(keyDeviceToken);

  set deviceToken(String deviceToken) => set<String>(keyDeviceToken, deviceToken);

  String get deviceType => super.get<String>(keyDeviceType);

  String get installationId => super.get<String>(keyInstallationId);

  set _installationId(String installationId) => set<String>(keyInstallationId, installationId);

  String get appName => super.get<String>(keyAppName);

  String get appVersion => super.get<String>(keyAppVersion);

  String get appIdentifier => super.get<String>(keyAppIdentifier);

  String get parseVersion => super.get<String>(keyParseVersion);

  /// Creates an instance of ParseInstallation
  ParseInstallation(
      {bool debug,
      ParseHTTPClient client,
      bool autoSendSessionId})
      : super(keyClassInstallation) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  ParseInstallation.forQuery() : super(keyClassUser);

  static Future<bool> isCurrent(ParseInstallation installation) async {
    if (_currentInstallationId == null) {
      _currentInstallationId = (await _getFromLocalStore()).installationId;
    }
    return _currentInstallationId != null && installation.installationId == _currentInstallationId;
  }

  /// Gets the current installation from storage
  static Future<ParseInstallation> currentInstallation() async {
    var installation = await _getFromLocalStore();
    if (installation == null) {
      installation = await _createInstallation();
    }
    return installation;
  }

  /// Updates the installation with current device data
  _updateInstallation() async {
    //Device type
    if (Platform.isAndroid) set<String>(keyDeviceType, "android");
    else if (Platform.isIOS) set<String>(keyDeviceType, "ios");
    else throw Exception("Unsupported platform/operating system");

    //Locale
    String locale = await Devicelocale.currentLocale;
    if (locale != null && locale.isNotEmpty) {
      set<String>(keyLocaleIdentifier, locale);
    }

    //Timezone
    //TODO set<String>(keyTimeZone, );

    //App info
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    set<String>(keyAppName, packageInfo.appName);
    set<String>(keyAppVersion, packageInfo.version);
    set<String>(keyAppIdentifier, packageInfo.packageName);
    set<String>(keyParseVersion, keySdkVersion);
  }

  Future<ParseResponse> create() async {
    var isCurrent = await ParseInstallation.isCurrent(this);
    if (isCurrent) await _updateInstallation();
    ParseResponse parseResponse = await super.create();
    if (parseResponse.success && isCurrent) {
      saveInStorage(keyParseStoreInstallation);
    }
    return parseResponse;
  }

  /// Saves the current installation
  Future<ParseResponse> save() async {
    var isCurrent = await ParseInstallation.isCurrent(this);
    if (isCurrent) await _updateInstallation();
    ParseResponse parseResponse = await super.save();
    if (parseResponse.success && isCurrent) {
      saveInStorage(keyParseStoreInstallation);
    }
    return parseResponse;
  }

  /// Gets the locally stored installation
  static Future<ParseInstallation> _getFromLocalStore() async {
    var installationJson =
        (await ParseCoreData().getStore()).getString(keyParseStoreInstallation);

    if (installationJson != null) {
      var installationMap = parseDecode(json.decode(installationJson));

      if (installationMap != null) {
        return new ParseInstallation()..fromJson(installationMap);
      }
    }

    return null;
  }

  /// Creates a installation for current device
  /// Assumes that this is called because there is no previous installation
  /// so it creates and sets the static current installation UUID
  static Future<ParseInstallation> _createInstallation() async {
    if (_currentInstallationId == null) {
      _currentInstallationId = Uuid().v4();
    }
    var installation = new ParseInstallation();
    installation._installationId = _currentInstallationId;
    await installation._updateInstallation();
    return installation;
  }
}
