part of flutter_parse_sdk;

/// User class that contains the current user data
class User extends ParseBase {
  static User _instance;

  static User get instance => _instance;

  /// Creates an instance of a ParseUser
  static void init(username, password, emailAddress) =>
      _instance ??= User._init(username, password, emailAddress);

  /// Clears user data to mimic logout
  static void logout() => _instance = null;

  String acl;
  String username;
  String password;
  String emailAddress;

  /// Creates a singleton instance of a user.
  ///
  /// There can only be one user
  User._init(this.username, this.password, this.emailAddress): super();

  factory User() => _instance;

  /// Returns a [User] from a [Map] object
  fromJson(objectData) {
    if (getObjectData() == null) setObjectData(objectData);
    getObjectData().addAll(objectData);
    if (getObjectData().containsKey(ParseConstants.OBJECT_ID)) objectId = getObjectData()[ParseConstants.OBJECT_ID];
    if (getObjectData().containsKey(ParseConstants.CREATED_AT)) createdAt = convertStringToDateTime(getObjectData()[ParseConstants.CREATED_AT]);
    if (getObjectData().containsKey(ParseConstants.UPDATED_AT)) updatedAt = convertStringToDateTime(getObjectData()[ParseConstants.UPDATED_AT]);
    if (getObjectData().containsKey(ACL)) acl = getObjectData()[ACL].toString();
    if (getObjectData().containsKey(USERNAME)) username = getObjectData()[USERNAME];
    if (getObjectData().containsKey(PASSWORD)) password = getObjectData()[PASSWORD];
    if (getObjectData().containsKey(EMAIL)) emailAddress = getObjectData()[EMAIL];

    if (updatedAt == null) updatedAt = createdAt;

    return this;
  }

  /// Returns a JSON string of the current user
  Map<String, dynamic> toJson() => {
        ACL: acl,
        USERNAME: username,
        PASSWORD: password,
        EMAIL: emailAddress,
      };

  @override
  String toString() => "Username: $username \n"
      "Email Address:$emailAddress";

  static const String USERNAME = 'Username';
  static const String EMAIL = 'Email';
  static const String PASSWORD = 'Password';
  static const String ACL = 'ACL';
}
