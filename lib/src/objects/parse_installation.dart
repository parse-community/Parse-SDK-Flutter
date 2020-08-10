part of flutter_parse_sdk;

class ParseInstallation extends ParseObject {
  /// Creates an instance of ParseInstallation
  ParseInstallation(
      {bool debug, ParseHTTPClient client, bool autoSendSessionId})
      : super(keyClassInstallation) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId:
                autoSendSessionId ?? ParseCoreData().autoSendSessionId,
            securityContext: ParseCoreData().securityContext);
  }

  ParseInstallation.forQuery() : super(keyClassUser);

  static final List<String> readOnlyKeys = <String>[
    keyDeviceToken,
    keyDeviceType,
    keyInstallationId,
    keyAppName,
    keyAppVersion,
    keyAppIdentifier,
    keyParseVersion
  ];
  static String _currentInstallationId;

  //Getters/setters
  Map<String, dynamic> get acl => super.get<Map<String, dynamic>>(keyVarAcl);

  set acl(Map<String, dynamic> acl) =>
      set<Map<String, dynamic>>(keyVarAcl, acl);

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

  static Future<bool> isCurrent(ParseInstallation installation) async {
    _currentInstallationId ??= (await _getFromLocalStore()).installationId;
    return _currentInstallationId != null &&
        installation.installationId == _currentInstallationId;
  }

  /// Gets the current installation from storage
  static Future<ParseInstallation> currentInstallation() async {
    ParseInstallation installation = await _getFromLocalStore();
    installation ??= await _createInstallation();
    return installation;
  }

  /// Updates the installation with current device data
  Future<void> _updateInstallation() async {
    //Device type
    if (Platform.isAndroid) {
      set<String>(keyDeviceType, 'android');
    } else if (Platform.isIOS) {
      set<String>(keyDeviceType, 'ios');
    } else if (Platform.isLinux) {
      set<String>(keyDeviceType, 'Linux');
    } else if (Platform.isMacOS) {
      set<String>(keyDeviceType, 'MacOS');
    } else if (Platform.isWindows) {
      set<String>(keyDeviceType, 'Windows');
    }

    //Locale
    final String locale = kIsWeb ? ui.window.locale.toString() : await Devicelocale.currentLocale;
    if (locale != null && locale.isNotEmpty) {
      set<String>(keyLocaleIdentifier, locale);
    }

    //Timezone

    //App info
    if (!kIsWeb) {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      set<String>(keyAppName, packageInfo.appName);
      set<String>(keyAppVersion, packageInfo.version);
      set<String>(keyAppIdentifier, packageInfo.packageName);
    }
    set<String>(keyParseVersion, keySdkVersion);
  }

  @override
  Future<ParseResponse> create() async {
    final bool isCurrent = await ParseInstallation.isCurrent(this);
    if (isCurrent) {
      await _updateInstallation();
    }

    final ParseResponse parseResponse = await _create();
    if (parseResponse.success && isCurrent) {
      saveInStorage(keyParseStoreInstallation);
    }
    return parseResponse;
  }

  /// Saves the current installation
  @override
  Future<ParseResponse> save() async {
    final bool isCurrent = await ParseInstallation.isCurrent(this);
    if (isCurrent) {
      await _updateInstallation();
    }
    //ParseResponse parseResponse = await super.save();
    final ParseResponse parseResponse = await _save();
    if (parseResponse.success && isCurrent) {
      saveInStorage(keyParseStoreInstallation);
    }
    return parseResponse;
  }

  /// Gets the locally stored installation
  static Future<ParseInstallation> _getFromLocalStore() async {
    final CoreStore coreStore = ParseCoreData().getStore();

    final String installationJson =
        await coreStore.getString(keyParseStoreInstallation);

    if (installationJson != null) {
      final Map<String, dynamic> installationMap =
          json.decode(installationJson);

      if (installationMap != null) {
        return ParseInstallation()..fromJson(installationMap);
      }
    }

    return null;
  }

  /// Creates a installation for current device
  /// Assumes that this is called because there is no previous installation
  /// so it creates and sets the static current installation UUID
  static Future<ParseInstallation> _createInstallation() async {
    _currentInstallationId ??= Uuid().v4();

    final ParseInstallation installation = ParseInstallation();
    installation._installationId = _currentInstallationId;
    await installation._updateInstallation();
    return installation;
  }

  /// Creates a new object and saves it online
  Future<ParseResponse> _create() async {
    try {
      final String uri = '${_client.data.serverUrl}$keyEndPointInstallations';
      final String body = json.encode(toJson(forApiRQ: true));
      final Map<String, String> headers = <String, String>{
        keyHeaderContentType: keyHeaderContentTypeJson
      };
      if (_debug) {
        logRequest(ParseCoreData().appName, parseClassName,
            ParseApiRQ.create.toString(), uri, body);
      }

      final Response result =
          await _client.post(uri, body: body, headers: headers);

      //Set the objectId on the object after it is created.
      //This allows you to perform operations on the object after creation
      if (result.statusCode == 201) {
        final Map<String, dynamic> map = json.decode(result.body);
        objectId = map['objectId'].toString();
      }

      return handleResponse<ParseInstallation>(
          this, result, ParseApiRQ.create, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.create, _debug, parseClassName);
    }
  }

  /// Saves the current object online
  Future<ParseResponse> _save() async {
    if (objectId == null) {
      return create();
    } else {
      try {
        final String uri =
            '${ParseCoreData().serverUrl}$keyEndPointInstallations/$objectId';
        final String body = json.encode(toJson(forApiRQ: true));
        if (_debug) {
          logRequest(ParseCoreData().appName, parseClassName,
              ParseApiRQ.save.toString(), uri, body);
        }
        final Response result = await _client.put(uri, body: body);
        return handleResponse<ParseInstallation>(
            this, result, ParseApiRQ.save, _debug, parseClassName);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.save, _debug, parseClassName);
      }
    }
  }

  ///Subscribes the device to a channel of push notifications.
  Future<void> subscribeToChannel(String value) async {
    final List<dynamic> channel = <String>[value];
    setAddAllUnique('channels', channel);
    await save();
  }

  ///Unsubscribes the device to a channel of push notifications.
  Future<void> unsubscribeFromChannel(String value) async {
    final List<dynamic> channel = <String>[value];
    setRemove('channels', channel);
    await save();
  }

  ///Returns an <List<String>> containing all the channel names this device is subscribed to.
  Future<List<dynamic>> getSubscribedChannels() async {
    print('getSubscribedChannels');
    final ParseResponse apiResponse =
        await ParseObject(keyClassInstallation).getObject(objectId);

    if (apiResponse.success) {
      final ParseObject installation = apiResponse.result;
      return Future<List<dynamic>>.value(
          installation.get<List<dynamic>>('channels'));
    } else {
      return null;
    }
  }
}
