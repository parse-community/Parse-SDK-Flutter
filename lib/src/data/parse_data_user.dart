part of flutter_parse_sdk;

class User extends ParseBase {
  static User _instance;

  static User get instance => _instance;

  static void init(username, password, emailAddress) =>
      _instance ??= User._init(username, password, emailAddress);

  String acl;
  String username;
  String password;
  String emailAddress;

  User._init(this.username, this.password, this.emailAddress): super();

  factory User() => _instance;

  fromJson(Map objectData) {
    if (getObjectData() == null) setObjectData(objectData);
    getObjectData().addAll(objectData);
    if (getObjectData().containsKey(ParseConstants.OBJECT_ID)) objectId = getValue(ParseConstants.OBJECT_ID).toString();
    if (getObjectData().containsKey(ParseConstants.CREATED_AT)) createdAt = convertStringToDateTime(getValue(ParseConstants.CREATED_AT).toString());
    if (getObjectData().containsKey(ParseConstants.UPDATED_AT)) updatedAt = convertStringToDateTime(getValue(ParseConstants.UPDATED_AT).toString());
    if (getObjectData().containsKey(ACL)) acl = getValue(ACL).toString();
    if (getObjectData().containsKey(USERNAME)) username = getValue(USERNAME).toString();
    if (getObjectData().containsKey(PASSWORD)) password = getValue(PASSWORD).toString();
    if (getObjectData().containsKey(EMAIL)) emailAddress = getValue(EMAIL).toString();

    if (updatedAt == null) updatedAt = createdAt;

    return this;
  }

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
