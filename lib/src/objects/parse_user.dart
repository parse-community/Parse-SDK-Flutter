part of flutter_parse_sdk;

class ParseUser extends ParseObject implements ParseCloneable {
  ParseUser.clone(Map map)
      : this(map[keyVarUsername], map[keyVarPassword], map[keyVarEmail]);

  @override
  clone(Map map) {
    return this.fromJson(map);
  }

  static final String keyUsername = 'username';
  static final String keyEmailAddress = 'email';
  static final String path = "$keyEndPointClasses$keyClassUser";

  Map get acl => super.get<Map>(keyVarAcl);

  set acl(Map acl) => set<Map>(keyVarAcl, acl);

  String get username => super.get<String>(keyVarUsername);

  set username(String username) => set<String>(keyVarUsername, username);

  String get password => super.get<String>(keyVarPassword);

  set password(String password) => set<String>(keyVarPassword, password);

  String get emailAddress => super.get<String>(keyVarEmail);

  set emailAddress(String emailAddress) =>
      set<String>(keyVarEmail, emailAddress);

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
      {bool debug, ParseHTTPClient client})
      : super(keyClassUser) {
    _debug = isDebugEnabled(objectLevelDebug: debug);
    _client = client ??
        ParseHTTPClient(
            autoSendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    this.username = username;
    this.password = password;
    this.emailAddress = emailAddress;
  }

  ParseUser.forQuery() : super(keyClassUser);

  createUser(String username, String password, [String emailAddress]) {
    return ParseUser(username, password, emailAddress);
  }

  /// Gets the current user from the server
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  static Future<ParseResponse> getCurrentUserFromServer(
      {String token, bool debug, ParseHTTPClient client}) async {
    bool _debug = isDebugEnabled(objectLevelDebug: debug);
    ParseHTTPClient _client = client ??
        ParseHTTPClient(
            autoSendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    // We can't get the current user and session without a sessionId
    if ((ParseCoreData().sessionId == null) && (token == null)) {
      return null;
    }

    final Map<String, String> headers = {};
    if (token != null) {
      headers[keyHeaderSessionToken] = token;
    }

    try {
      Uri tempUri = Uri.parse(ParseCoreData().serverUrl);

      Uri uri = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointUserName");

      final response = await _client.get(uri, headers: headers);
      return _handleResponse(_getEmptyUser(), response, ParseApiRQ.currentUser,
          _debug, _getEmptyUser().className);
    } on Exception catch (e) {
      return _handleException(
          e, ParseApiRQ.currentUser, _debug, _getEmptyUser().className);
    }
  }

  /// Gets the current user from storage
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  static currentUser() {
    return _getUserFromLocalStore();
  }

  /// Registers a user on Parse Server
  ///
  /// After creating a new user via [Parse.create] call this method to register
  /// that user on Parse
  Future<ParseResponse> signUp() async {
    try {
      if (emailAddress == null) return null;

      Map<String, dynamic> bodyData = {};
      bodyData[keyVarEmail] = emailAddress;
      bodyData[keyVarPassword] = password;
      bodyData[keyVarUsername] = username;

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$path");

      final response = await _client.post(url,
          headers: {
            keyHeaderRevocableSession: "1",
          },
          body: json.encode(bodyData));

      return _handleResponse(
          this, response, ParseApiRQ.signUp, _debug, className);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.signUp, _debug, className);
    }
  }

  /// Logs a user in via Parse
  ///
  /// Once a user is created using [Parse.create] and a username and password is
  /// provided, call this method to login.
  Future<ParseResponse> login() async {
    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointLogin",
          queryParameters: {
            keyVarUsername: username,
            keyVarPassword: password
          });

      final response = await _client.get(url, headers: {
        keyHeaderRevocableSession: "1",
      });

      return _handleResponse(
          this, response, ParseApiRQ.login, _debug, className);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.login, _debug, className);
    }
  }

  // Logs in a user anonymously
  Future<ParseResponse> loginAnonymous() async {
    try {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}$keyEndPointUsers",
      );

      var uuid = new Uuid();

      final response = await _client.post(url,
          headers: {
            keyHeaderRevocableSession: "1",
          },
          body: jsonEncode({
            "authData": {
              "anonymous": {"id": uuid.v4()}
            }
          }));

      return _handleResponse(
          this, response, ParseApiRQ.loginAnonymous, _debug, className);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.loginAnonymous, _debug, className);
    }
  }

  /// Sends a request to delete the sessions token from the
  /// server. Will also delete the local user data unless
  /// deleteLocalUserData is false.
  logout({bool deleteLocalUserData = true}) async {
    if (deleteLocalUserData) {
      _client.data.sessionId = null;
      unpin(key: keyParseStoreUser);
      setObjectData(null);
    }

    try {
      if (username == null) return null;

      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri url = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}$keyEndPointLogout");

      final response = await _client.post(
        url,
      );

      return _handleResponse(
          this, response, ParseApiRQ.logout, _debug, className);
    } on Exception catch (e) {
      return _handleException(e, ParseApiRQ.logout, _debug, className);
    }
  }

  /// Sends a verification email to the users email address
  Future<ParseResponse> verificationEmailRequest() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}$keyEndPointVerificationEmail",
          body: json.encode({keyVarEmail: emailAddress}));
      return _handleResponse(this, response,
          ParseApiRQ.verificationEmailRequest, _debug, className);
    } on Exception catch (e) {
      return _handleException(
          e, ParseApiRQ.verificationEmailRequest, _debug, className);
    }
  }

  /// Sends a password reset email to the users email address
  Future<ParseResponse> requestPasswordReset() async {
    try {
      final response = await _client.post(
          "${_client.data.serverUrl}$keyEndPointRequestPasswordReset",
          body: json.encode({keyVarEmail: emailAddress}));
      return _handleResponse(
          this, response, ParseApiRQ.requestPasswordReset, _debug, className);
    } on Exception catch (e) {
      return _handleException(
          e, ParseApiRQ.requestPasswordReset, _debug, className);
    }
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  Future<ParseResponse> save() async {
    if (objectId == null) {
      return signUp();
    } else {
      try {
        var uri = _client.data.serverUrl + "$path/$objectId";
        var body =
            json.encode(toJson(forApiRQ: true), toEncodable: dateTimeEncoder);
        final response = await _client.put(uri, body: body);
        return _handleResponse(
            this, response, ParseApiRQ.save, _debug, className);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.save, _debug, className);
      }
    }
  }

  /// Removes a user from Parse Server locally and online
  Future<ParseResponse> destroy() async {
    if (objectId != null) {
      try {
        final response =
            await _client.delete(_client.data.serverUrl + "$path/$objectId");
        return _handleResponse(
            this, response, ParseApiRQ.destroy, _debug, className);
      } on Exception catch (e) {
        return _handleException(e, ParseApiRQ.destroy, _debug, className);
      }
    }

    return null;
  }

  /// Gets a list of all users (limited return)
  static Future<ParseResponse> all({bool debug, ParseHTTPClient client}) async {
    var emptyUser = ParseUser(null, null, null);

    bool _debug = isDebugEnabled(objectLevelDebug: debug);
    ParseHTTPClient _client = client ??
        ParseHTTPClient(
            autoSendSessionId: true,
            securityContext: ParseCoreData().securityContext);

    try {
      final response = await _client.get("${ParseCoreData().serverUrl}/$path");

      ParseResponse parseResponse =
          ParseResponse.handleResponse<ParseUser>(emptyUser, response);

      if (_debug) {
        logger(ParseCoreData().appName, keyClassUser,
            ParseApiRQ.getAll.toString(), parseResponse);
      }

      return parseResponse;
    } on Exception catch (e) {
      return ParseResponse.handleException(e);
    }
  }

  static Future<ParseUser> _getUserFromLocalStore() async {
    var userJson =
        (await ParseCoreData().getStore()).getString(keyParseStoreUser);

    if (userJson != null) {
      var userMap = parseDecode(json.decode(userJson));

      if (userMap != null) {
        ParseCoreData().setSessionId(userMap[keyParamSessionToken]);
        return _getEmptyUser()..fromJson(userMap);
      }
    }

    return null;
  }

  /// Handles an API response and logs data if [bool] debug is enabled
  static ParseResponse _handleException(
      Exception exception, ParseApiRQ type, bool debug, String className) {
    ParseResponse parseResponse = ParseResponse.handleException(exception);

    if (debug) {
      logger(
          ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    return parseResponse;
  }

  /// Handles all the response data for this class
  static ParseResponse _handleResponse(ParseUser user, Response response,
      ParseApiRQ type, bool debug, String className) {
    ParseResponse parseResponse =
        ParseResponse.handleResponse<ParseUser>(user, response);

    if (debug) {
      logger(
          ParseCoreData().appName, className, type.toString(), parseResponse);
    }

    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);
    if (responseData.containsKey(keyVarObjectId)) {
      parseResponse.result.fromJson(responseData);
      ParseCoreData().setSessionId(responseData[keyParamSessionToken]);
    }

    if (type == ParseApiRQ.getAll || type == ParseApiRQ.destroy) {
      return parseResponse;
    } else {
      parseResponse.result?.saveInStorage(keyParseStoreUser);
      return parseResponse;
    }
  }

  static ParseUser _getEmptyUser() => ParseUser(null, null, null);
}
