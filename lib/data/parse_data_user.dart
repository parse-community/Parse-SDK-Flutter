import 'package:parse_server_sdk/objects/parse_base.dart';

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

  fromJson(Map<String, dynamic> objectData) {
    setObjectData(objectData);

    acl = getObjectData()[ACL];
    username = getObjectData()[USERNAME];
    password = getObjectData()[PASSWORD];
    emailAddress = getObjectData()[EMAIL];
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
