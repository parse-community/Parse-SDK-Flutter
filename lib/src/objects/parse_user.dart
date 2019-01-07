part of flutter_parse_sdk;

class ParseUser {
  ParseHTTPClient _client;
  static final String className = '_User';
  String path = "/classes/$className";
  bool _debug;

  /// Creates an instance of ParseUser
  ///
  /// Users can set whether debug should be set on this class with a [bool],
  /// they can also create thier own custom version of [ParseHttpClient]
  ParseUser({debug, ParseHTTPClient client}) {
    client != null ? _client = client : _client = ParseHTTPClient();
    _debug = isDebugEnabled(debug, _client);
  }

  /// Creates a new user locally
  ///
  /// Requires [String] username, [String] password. [String] email address
  /// is required as well to create a full new user object on ParseServer. Only
  /// username and password is required to login
  create(String username, String password, [String emailAddress]) {
    User.init(username, password, emailAddress);
    return User.instance;
  }

  /// Gets the current user
  ///
  /// Current user is stored locally, but in case of a server update [bool]
  /// fromServer can be called and an updated version of the [User] object will be
  /// returned
  currentUser({bool fromServer: false}) async {
    if (_client.data.sessionId == null) {
      return null;
    } else if (fromServer == false) {
      return User.instance;
    } else {
      Uri tempUri = Uri.parse(_client.data.serverUrl);

      Uri uri = Uri(
          scheme: tempUri.scheme,
          host: tempUri.host,
          path: "${tempUri.path}/users/me");

      final response = await _client.get(uri, headers: {
        ParseConstants.HEADER_SESSION_TOKEN: _client.data.sessionId
      });
      return _handleResponse(response, ParseApiUser.currentUser);
    }
  }

  /// Registers a user on Parse Server
  ///
  /// After creating a new user via [Parse.create] call this method to register
  /// that user on Parse
  signUp() async {

    if (User().emailAddress == null) return null;

    Map<String, dynamic> bodyData = {};
    bodyData["email"] = User().emailAddress;
    bodyData["password"] = User().password;
    bodyData["username"] = User().username;

    Uri tempUri = Uri.parse(_client.data.serverUrl);

    Uri url = Uri(
        scheme: tempUri.scheme,
        host: tempUri.host,
        path: "${tempUri.path}$path");

    final response = await _client.post(url,
        headers: {
          ParseConstants.HEADER_REVOCABLE_SESSION: "1",
        },
        body: JsonEncoder().convert(bodyData));

    _handleResponse(response, ParseApiUser.signUp);
    return User.instance;
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
          "username": User.instance.username,
          "password": User.instance.password
        });

    final response = await _client.post(url, headers: {
      ParseConstants.HEADER_REVOCABLE_SESSION: "1",
    });

    _handleResponse(response, ParseApiUser.login);
    return User.instance;
  }

  /// Removes the current user from the session data
  logout(){
    _client.data.sessionId = null;
    User.logout();
  }

  /// Sends a verification email to the users email address
  verificationEmailRequest() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/verificationEmailRequest",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResponse(
        response, ParseApiUser.verificationEmailRequest);
  }

  /// Sends a password reset email to the users email address
  requestPasswordReset() async {
    final response = await _client.post(
        "${_client.data.serverUrl}/requestPasswordReset",
        body: JsonEncoder().convert({"email": User().emailAddress}));

    return _handleResponse(response, ParseApiUser.requestPasswordReset);
  }

  /// Saves the current user
  ///
  /// If changes are made to the current user, call save to sync them with
  /// Parse Server
  save() async {
    if (User.instance.objectId == null) {
      return signUp();
    } else {
      final response = await _client.put(
          _client.data.serverUrl + "$path/${User().objectId}",
          body: JsonEncoder().convert(User().getObjectData()));
      return _handleResponse(response, ParseApiUser.save);
    }
  }

  /// Removes a user from Parse Server locally and online
  destroy() async {
    final response = await _client.delete(
        _client.data.serverUrl + "$path/${User().objectId}",
        headers: {"X-Parse-Session-Token": _client.data.sessionId});

    _handleResponse(response, ParseApiUser.destroy);

    return User.instance.objectId;
  }

  /// Gets a list of all users (limited return)
  all() async {
    final response = await _client.get(_client.data.serverUrl + "$path");
    return _handleResponse(response, ParseApiUser.all);
  }

  /// Handles all the reponse data for this class
  _handleResponse(Response response, ParseApiUser type) {
    Map<String, dynamic> responseData = JsonDecoder().convert(response.body);

    var responseString = ' \n';

    responseString += "----"
        "\n${_client.data.appName} API Response ($className : ${type.toString()}) :";

    if (response.statusCode == 200 || response.statusCode == 201) {
      responseString += "\nStatus Code: ${response.statusCode}";
      responseString += "\nPayload: ${responseData.toString()}";

      if (responseData.containsKey('objectId')) {
        User.instance.fromJson(JsonDecoder().convert(response.body) as Map);
        _client.data.sessionId = responseData['sessionToken'];
      }
    } else {
      responseString += "\nStatus Code: ${responseData['code']}";
      responseString += "\nException: ${responseData['error']}";
    }

    if (_client.data.debug || _debug) {
      responseString += "\n----\n";
      print(responseString);
    }

    return User.instance;
  }
}
