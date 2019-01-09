part of flutter_parse_sdk;

class ParseUser extends ParseBase {
  ParseHTTPClient _client;
  static final String className = '_User';
  String path = "/classes/$className";
  bool _debug;

  String acl;
  String username;
  String password;
  String emailAddress;

  /// Creates an instance of ParseUser
  ///
  /// Users can set whether debug should be set on this class with a [bool],
  /// they can also create thier own custom version of [ParseHttpClient]
  ///
  /// Creates a new user locally
  ///
  /// Requires [String] username, [String] password. [String] email address
  /// is required as well to create a full new user object on ParseServer. Only
  /// username and password is required to login
  ParseUser(this.username, this.password, this.emailAddress, {bool debug, ParseHTTPClient client}) : super() {
    client == null ? _client = ParseHTTPClient() : _client = client;
    _debug = isDebugEnabled(client, objectLevelDebug: debug);
  }

  /// Returns a [User] from a [Map] object
  fromJson(objectData) {
    if (getObjectData() == null) {
      setObjectData(objectData);
    } else {
      getObjectData().addAll(objectData);
    }

    if (getObjectData().containsKey(OBJECT_ID))
      objectId = getObjectData()[OBJECT_ID];
    if (getObjectData().containsKey(CREATED_AT))
      createdAt = stringToDateTime(getObjectData()[CREATED_AT]);
    if (getObjectData().containsKey(UPDATED_AT))
      updatedAt = stringToDateTime(getObjectData()[UPDATED_AT]);
    if (getObjectData().containsKey(ACL)) acl = getObjectData()[ACL].toString();
    if (getObjectData().containsKey(USERNAME))
      username = getObjectData()[USERNAME];
    if (getObjectData().containsKey(PASSWORD))
      password = getObjectData()[PASSWORD];
    if (getObjectData().containsKey(EMAIL))
      emailAddress = getObjectData()[EMAIL];

    if (updatedAt == null) updatedAt = createdAt;

    saveInStorage(PARSE_STORE_USER);

    return getObjectData();
  }

  /// Returns a [String] that's human readable. Ideal for printing logs
  @override
  String toString() =>
      "Username: $username \nEmail Address:$emailAddress";

  static const String USERNAME = 'Username';
  static const String EMAIL = 'Email';
  static const String PASSWORD = 'Password';
  static const String ACL = 'ACL';


  create(String username, String password, [String emailAddress]) {
    return ParseUser(username, password, emailAddress);
  }

  /// Gets the current user from the server
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  getCurrentUserFromServer() async {

    // We can't get the current user and session without a sessionId
    if (_client.data.sessionId == null) return null;
    
    Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri uri = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}/users/me");

      final response = await _client.get(uri, headers: {
        HEADER_SESSION_TOKEN: _client.data.sessionId
      });
      return _handleResponse(response, ParseApiRQ.currentUser);
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
  signUp() async {
    if (emailAddress == null) return null;

    Map<String, dynamic> bodyData = {};
    bodyData["email"] = emailAddress;
    bodyData["password"] = password;
    bodyData["username"] = username;

    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}$path");

    final response = await _client.post(url,
        headers: {
          HEADER_REVOCABLE_SESSION: "1",
        },
        body: JsonEncoder().convert(bodyData));

    _handleResponse(response, ParseApiRQ.signUp);
    return this;
  }

  /// Logs a user in via Parse
  ///
  /// Once a user is created using [Parse.create] and a username and password is
  /// provided, call this method to login.
  login() async {
    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}/login",
        queryParameters: {
          "username": username,
          "password": password
        });

    final response = await _client.post(url, headers: {
      HEADER_REVOCABLE_SESSION: "1",
    });

    _handleResponse(response, ParseApiRQ.login);
    return this;
  }

  /// Removes the current user from the session data
  logout(){
    _client.data.sessionId = null;
    setObjectData(null);
  }

  /// Sends a verification email to the users email address
  verificationEmailRequest() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/verificationEmailRequest",
        body: JsonEncoder().convert({"email": emailAddress}));

    return _handleResponse(
        response, ParseApiRQ.verificationEmailRequest);
  }

  /// Sends a password reset email to the users email address
  requestPasswordReset() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/requestPasswordReset",
        body: JsonEncoder().convert({"email": emailAddress}));

    return _handleResponse(response, ParseApiRQ.requestPasswordReset);
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  save() async {
    if (objectId == null) {
      return signUp();
    } else {
      final response = await _client.put(
          _client.data.serverUrl + "$path/$objectId",
          body: JsonEncoder().convert(getObjectData()));
      return _handleResponse(response, ParseApiRQ.save);
    }
  }

  /// Removes a user from Parse Server locally and online
  destroy() async {
    final response = await _client.delete(
        _client.data.serverUrl + "$path/$objectId",
        headers: {"X-Parse-Session-Token": _client.data.sessionId});

    _handleResponse(response, ParseApiRQ.destroy);

    return objectId;
  }

  /// Gets a list of all users (limited return)
  all() async {
    final response = await _client.get(_client.data.serverUrl + "$path");
    return _handleResponse(response, ParseApiRQ.all);
  }

  /// Handles all the reponse data for this class
  _handleResponse(Response response, ParseApiRQ type) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    var responseString = ' \n';

    responseString += "----""\n${_client.data.appName} API Response ($className : ${type.toString()}) :";

    if (response.statusCode == 200 || response.statusCode == 201) {
      responseString += "\nStatus Code: ${response.statusCode}";
      responseString += "\nPayload: ${responseData.toString()}";

      if (responseData.containsKey('objectId')) {
        fromJson(responseData);
        _client.data.sessionId = responseData['sessionToken'];
        saveInStorage(PARSE_STORE_USER);
      }
    } else {
      responseString += "\nStatus Code: ${responseData['code']}";
      responseString += "\nException: ${responseData['error']}";
    }

    if (_client.data.debug || _debug) {
      responseString += "\n----\n";
      print(responseString);
    }

    return this;
  }

  static _getUserFromLocalStore() {
    var userJson = ParseCoreData().getStore().getString(PARSE_STORE_USER);

    if (userJson != null) {
      var userMap = JsonDecoder().convert(userJson);

      if (userJson != null && userMap != null) {

        ParseCoreData().sessionId = userMap['sessionToken'];

        var user = ParseUser(userMap['username'], userMap['password'], userMap['emailAddress']);
        user.fromJson(userMap);
        return user;
      }
    }

    return null;
  }
}
