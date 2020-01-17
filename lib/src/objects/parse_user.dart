part of flutter_parse_sdk;

class ParseUser extends ParseObject implements ParseCloneable {
  /// Creates an instance of ParseUser
  ///
  /// Users can set whether debug should be set on this class with a [bool],
  /// they can also create their own custom version of [ParseHttpClient]
  ///
  /// Creates a new user locally
  ///
  /// Requires [String] username, [String] password. [String] email address
  /// is required as well to create a full new user object on ParseServer. Only
  /// username and password is required to login
  ParseUser(String username, String password, String emailAddress,
      {String sessionToken, bool debug, ParseHTTPClient client})
      : super(keyClassUser) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            sendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    this.username = username;
    this.password = password;
    this.emailAddress = emailAddress;
    this.sessionToken = sessionToken;
  }

  ParseUser.forQuery() : super(keyClassUser);

  ParseUser.clone(Map<String, dynamic> map)
      : this(map[keyVarUsername], map[keyVarPassword], map[keyVarEmail]);

  @override
  dynamic clone(Map<String, dynamic> map) =>
      ParseUser.clone(map)..fromJson(map);

  static const String keyEmailVerified = 'emailVerified';
  static const String keyUsername = 'username';
  static const String keyEmailAddress = 'email';
  static const String path = '$keyEndPointClasses$keyClassUser';

  Map<String, dynamic> get acl => super.get<Map<String, dynamic>>(keyVarAcl);

  set acl(Map<String, dynamic> acl) =>
      set<Map<String, dynamic>>(keyVarAcl, acl);

  bool get emailVerified => super.get<bool>(keyEmailVerified);

  set emailVerified(bool emailVerified) =>
      set<bool>(keyEmailVerified, emailVerified);

  String get username => super.get<String>(keyVarUsername);

  set username(String username) => set<String>(keyVarUsername, username);

  String get password => super.get<String>(keyVarPassword);

  set password(String password) => set<String>(keyVarPassword, password);

  String get emailAddress => super.get<String>(keyVarEmail);

  set emailAddress(String emailAddress) =>
      set<String>(keyVarEmail, emailAddress);

  String get sessionToken => super.get<String>(keyVarSessionToken);

  set sessionToken(String sessionToken) =>
      set<String>(keyVarSessionToken, sessionToken);

  Map<String, dynamic> get authData =>
      super.get<Map<String, dynamic>>(keyVarAuthData);

  set authData(Map<String, dynamic> authData) =>
      set<Map<String, dynamic>>(keyVarAuthData, authData);

  static ParseUser createUser(
      [String username, String password, String emailAddress]) {
    return ParseUser(username, password, emailAddress);
  }

  /// Gets the current user from the server
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned.
  ///
  /// NOTE: If using custom ParseUserObject create instance and user [getUpdatedUser]
  static Future<ParseResponse> getCurrentUserFromServer(String token,
      {bool debug, ParseHTTPClient client}) async {
    final ParseUser user = _getEmptyUser();
    user.sessionToken = token;
    return user.getUpdatedUser(debug: debug, client: client);
  }

  /// Get the updated version of the user from the server
  ///
  /// Uses token to get the latest version of the user. Prefer this to [getCurrentUserFromServer]
  /// if using custom ParseUser object
  Future<ParseResponse> getUpdatedUser(
      {bool debug, ParseHTTPClient client}) async {
    final bool _debug = isDebugEnabled(objectLevelDebug: debug);
    final ParseHTTPClient _client = client ??
        ParseHTTPClient(
            sendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    // We can't get the current user and session without a sessionId
    if ((ParseCoreData().sessionId == null) && (sessionToken == null)) {
      return null;
    }

    final Map<String, String> headers = <String, String>{};
    if (sessionToken != null) {
      headers[keyHeaderSessionToken] = sessionToken;
    }

    try {
      final Uri url = getSanitisedUri(_client, '$keyEndPointUserName');
      final Response response = await _client.get(url, headers: headers);
      return await _handleResponse(this, response,
          ParseApiRQ.currentUser, _debug, this.parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.currentUser, _debug, parseClassName);
    }
  }

  /// Gets the current user from storage
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  static Future<dynamic> currentUser({ParseCloneable customUserObject}) async {
    if (customUserObject != null) {
      return await _getUserFromLocalStore(cloneable: customUserObject);
    } else {
      return await _getUserFromLocalStore();
    }
  }

  /// Registers a user on Parse Server
  ///
  /// After creating a new user via [Parse.create] call this method to register
  /// that user on Parse
  Future<ParseResponse> signUp() async {
    try {
      if (emailAddress == null) {
        return null;
      }

      final Map<String, dynamic> bodyData = _getObjectData();
      final Uri url = getSanitisedUri(_client, '$path');
      final String body = json.encode(bodyData);
      _saveChanges();
      final String installationId = await _getInstallationId();
      final Response response = await _client.post(url,
          headers: <String, String>{
            keyHeaderRevocableSession: '1',
            if (installationId != null) keyHeaderInstallationId: installationId,
          },
          body: body);

      return await _handleResponse(
          this, response, ParseApiRQ.signUp, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.signUp, _debug, parseClassName);
    }
  }

  /// Logs a user in via Parse
  ///
  /// Once a user is created using [Parse.create] and a username and password is
  /// provided, call this method to login.
  Future<ParseResponse> login() async {
    try {
      final Map<String, dynamic> queryParams = <String, String>{
        keyVarUsername: username,
        keyVarPassword: password
      };

      final Uri url = getSanitisedUri(_client, '$keyEndPointLogin',
          queryParams: queryParams);
      _saveChanges();
      final Response response =
          await _client.get(url, headers: <String, String>{
        keyHeaderRevocableSession: '1',
      });

      return await _handleResponse(
          this, response, ParseApiRQ.login, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.login, _debug, parseClassName);
    }
  }

  // Logs in a user anonymously
  Future<ParseResponse> loginAnonymous() async {
    try {
      final Uri url = getSanitisedUri(_client, '$keyEndPointUsers');
      final Uuid uuid = Uuid();
      final String installationId = await _getInstallationId();

      final Response response = await _client.post(url,
          headers: <String, String>{
            keyHeaderRevocableSession: '1',
            if (installationId != null) keyHeaderInstallationId: installationId,
          },
          body: jsonEncode(<String, dynamic>{
            'authData': <String, dynamic>{
              'anonymous': <String, dynamic>{'id': uuid.v4()}
            }
          }));

      return await _handleResponse(
          this, response, ParseApiRQ.loginAnonymous, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.loginAnonymous, _debug, parseClassName);
    }
  }

  // Logs in a user using a service
  static Future<ParseResponse> loginWith(
      String provider, Object authData) async {
    final ParseUser user = ParseUser.createUser();
    final ParseResponse response = await user._loginWith(provider, authData);
    return response;
  }

  Future<ParseResponse> _loginWith(String provider, Object authData) async {
    try {
      final Uri url = getSanitisedUri(_client, '$keyEndPointUsers');
      final String installationId = await _getInstallationId();
      final Response response = await _client.post(url,
          headers: <String, String>{
            keyHeaderRevocableSession: '1',
            if (installationId != null) keyHeaderInstallationId: installationId,
          },
          body: jsonEncode(<String, dynamic>{
            'authData': <String, dynamic>{provider: authData}
          }));

      return await _handleResponse(
          this, response, ParseApiRQ.loginWith, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.loginWith, _debug, parseClassName);
    }
  }

  /// Sends a request to delete the sessions token from the
  /// server. Will also delete the local user data unless
  /// deleteLocalUserData is false.
  Future<ParseResponse> logout({bool deleteLocalUserData = true}) async {
    final String sessionId = _client.data.sessionId;

    forgetLocalSession();

    if (deleteLocalUserData == true) {
      await this.deleteLocalUserData();
    }

    try {
      final Uri url = getSanitisedUri(_client, '$keyEndPointLogout');
      final Response response = await _client.post(url,
          headers: <String, String>{keyHeaderSessionToken: sessionId});

      return await _handleResponse(
          this, response, ParseApiRQ.logout, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.logout, _debug, parseClassName);
    }
  }

  void forgetLocalSession() async {
    _client.data.sessionId = null;
    ParseCoreData().setSessionId(null);
  }

  /// Delete the local user data.
  Future<void> deleteLocalUserData() async {
    await unpin(key: keyParseStoreUser);
    _setObjectData(null);
  }

  /// Sends a verification email to the users email address
  Future<ParseResponse> verificationEmailRequest() async {
    try {
      final Response response = await _client.post(
          '${_client.data.serverUrl}$keyEndPointVerificationEmail',
          body: json.encode(<String, dynamic>{keyVarEmail: emailAddress}));
      return await _handleResponse(this, response,
          ParseApiRQ.verificationEmailRequest, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.verificationEmailRequest, _debug, parseClassName);
    }
  }

  /// Sends a password reset email to the users email address
  Future<ParseResponse> requestPasswordReset() async {
    try {
      final Response response = await _client.post(
          '${_client.data.serverUrl}$keyEndPointRequestPasswordReset',
          body: json.encode(<String, dynamic>{keyVarEmail: emailAddress}));
      return await _handleResponse(this, response,
          ParseApiRQ.requestPasswordReset, _debug, parseClassName);
    } on Exception catch (e) {
      return handleException(
          e, ParseApiRQ.requestPasswordReset, _debug, parseClassName);
    }
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  @override
  Future<ParseResponse> save() async {
    if (objectId == null) {
      return await signUp();
    } else {
      final ParseResponse response = await super.save();
      if (response.success) {
        await _onResponseSuccess();
      }
      return response;
    }
  }

  Future<void> _onResponseSuccess() async {
    await saveInStorage(keyParseStoreUser);
  }

  /// Removes a user from Parse Server locally and online
  Future<ParseResponse> destroy() async {
    if (objectId != null) {
      try {
        final Uri url = getSanitisedUri(_client, '$_path/$objectId');
        final Response response = await _client.delete(url);
        return await _handleResponse(
            this, response, ParseApiRQ.destroy, _debug, parseClassName);
      } on Exception catch (e) {
        return handleException(e, ParseApiRQ.destroy, _debug, parseClassName);
      }
    }

    return null;
  }

  /// Gets a list of all users (limited return)
  static Future<ParseResponse> all({bool debug, ParseHTTPClient client}) async {
    final ParseUser emptyUser = _getEmptyUser();

    final bool _debug = isDebugEnabled(objectLevelDebug: debug);
    final ParseHTTPClient _client = client ??
        ParseHTTPClient(
            sendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    try {
      final Uri url = getSanitisedUri(_client, '$path');
      final Response response = await _client.get(url);
      final ParseResponse parseResponse = handleResponse<ParseUser>(
          emptyUser, response, ParseApiRQ.getAll, _debug, keyClassUser);
      return parseResponse;
    } on Exception catch (e) {
      return handleException(e, ParseApiRQ.getAll, _debug, keyClassUser);
    }
  }

  static Future<dynamic> _getUserFromLocalStore(
      {ParseCloneable cloneable}) async {
    final CoreStore coreStore = ParseCoreData().getStore();
    final String userJson = await coreStore.getString(keyParseStoreUser);

    if (userJson != null) {
      final Map<String, dynamic> userMap = json.decode(userJson);
      if (cloneable != null) {
        return cloneable.clone(userMap);
      } else {
        ParseCoreData().setSessionId(userMap[keyParamSessionToken]);
        return parseDecode(userMap);
      }
    }

    return null;
  }

  /// Handles all the response data for this class
  static Future<ParseResponse> _handleResponse(ParseUser user,
      Response response, ParseApiRQ type, bool debug, String className) async {
    final ParseResponse parseResponse =
        handleResponse<ParseUser>(user, response, type, debug, className);

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    if (responseData.containsKey(keyVarObjectId)) {
      user.sessionToken = responseData[keyParamSessionToken];
      ParseCoreData().setSessionId(user.sessionToken);
    }

    if ((parseResponse.statusCode != 200 && parseResponse.statusCode != 201) ||
        type == ParseApiRQ.getAll ||
        type == ParseApiRQ.destroy ||
        type == ParseApiRQ.requestPasswordReset ||
        type == ParseApiRQ.verificationEmailRequest ||
        type == ParseApiRQ.logout) {
      return parseResponse;
    } else {
      final ParseUser user = parseResponse.result;
      await user?._onResponseSuccess();
      return parseResponse;
    }
  }

  static ParseUser _getEmptyUser() => ParseUser(null, null, null);

  static Future<String> _getInstallationId() async {
    final ParseInstallation parseInstallation =
        await ParseInstallation.currentInstallation();
    return parseInstallation?.installationId;
  }
}
