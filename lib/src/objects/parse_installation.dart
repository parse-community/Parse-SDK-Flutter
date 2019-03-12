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
  static final List<String> readOnlyKeys = [
    //TODO
    keyDeviceToken, keyDeviceType, keyInstallationId,
    keyAppName, keyAppVersion, keyAppIdentifier, keyParseVersion
  ];
  static String _currentInstallationId;

  //Getters/setters

  Map get acl => super.get<Map>(keyVarAcl);

  set acl(Map acl) => set<Map>(keyVarAcl, acl);

  String get deviceToken => super.get<String>(keyDeviceToken);

  set deviceToken(String deviceToken) =>
      set<String>(keyDeviceToken, deviceToken);

  String get deviceType => super.get<String>(keyDeviceType);

  String get installationId => super.get<String>(keyInstallationId);

  set _installationId(String installationId) =>
      set<String>(keyInstallationId, installationId);

  String get appName => super.get<String>(keyAppName);

  String get appVersion => super.get<String>(keyAppVersion);

  String get appIdentifier => super.get<String>(keyAppIdentifier);

  String get parseVersion => super.get<String>(keyParseVersion);

  /// Creates an instance of ParseInstallation
  ParseInstallation(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
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
    return _currentInstallationId != null &&
        installation.installationId == _currentInstallationId;
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
    if (Platform.isAndroid)
      set<String>(keyDeviceType, "android");
    else if (Platform.isIOS)
      set<String>(keyDeviceType, "ios");
    else
      throw Exception("Unsupported platform/operating system");

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
    //ParseResponse parseResponse = await super.create();
    ParseResponse parseResponse = await _create();
    if (parseResponse.success && isCurrent) {
      saveInStorage(keyParseStoreInstallation);
    }
    return parseResponse;
  }

  /// Saves the current installation
  Future<ParseResponse> save() async {
    var isCurrent = await ParseInstallation.isCurrent(this);
    if (isCurrent) await _updateInstallation();
    //ParseResponse parseResponse = await super.save();
    ParseResponse parseResponse = await _save();
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

  /// Creates a new object and saves it online
  Future<ParseResponse> _create() async {
    try {
      var uri = _client.data.serverUrl + "$keyEndPointInstallations";
      var body = json.encode(toJson(forApiRQ: true));
      if (_debug) {
        logRequest(ParseCoreData().appName, className,
            ParseApiRQ.create.toString(), uri, body);
      }
      var result = await _client.post(uri, body: body);

      //Set the objectId on the object after it is created.
      //This allows you to perform operations on the object after creation
      if (result.statusCode == 201) {
        final map = json.decode(result.body);
        this.objectId = map["objectId"].toString();
      }

      return handleResponse(this, result, ParseApiRQ.create, _debug, className);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.create, _debug, className);
    }
  }

  /// Saves the current object online
  Future<ParseResponse> _save() async {
    if (getObjectData()[keyVarObjectId] == null) {
      return create();
    } else {
      try {
        var uri =
            "${ParseCoreData().serverUrl}$keyEndPointInstallations/$objectId";
        var body = json.encode(toJson(forApiRQ: true));
        if (_debug) {
          logRequest(ParseCoreData().appName, className,
              ParseApiRQ.save.toString(), uri, body);
        }
        var result = await _client.put(uri, body: body);
        return handleResponse(this, result, ParseApiRQ.save, _debug, className);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.save, _debug, className);
      }
    }
  }

  ///Subscribes the device to a channel of push notifications.
  void subscribeToChannel(String value) {
    final List<dynamic> channel = [value];
    this.addUnique("channels", channel);
  }

  ///Unsubscribes the device to a channel of push notifications.
  void unsubscribeFromChannel(String value) {
    final List<dynamic> channel = [value];
    this.removeAll("channels", channel);
  }

  ///Returns an <List<String>> containing all the channel names this device is subscribed to.
  Future<List<dynamic>> getSubscribedChannels() async {
    print("getSubscribedChannels");
    final apiResponse =
        await ParseObject(keyClassInstallation).getObject(this.objectId);

    if (apiResponse.success) {
      var installation = apiResponse.result as ParseObject;
      print("achou installation");
      return Future.value(installation.get<List<dynamic>>("channels"));
    } else {
      return null;
    }
  }
}
