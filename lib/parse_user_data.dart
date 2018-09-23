class ParseUserData {
  static ParseUserData _instance;

  static ParseUserData get instance => _instance;

  static void init(username, password, emailAddress) =>
      _instance ??= ParseUserData._init(username, password, emailAddress);

  String username;
  String password;
  String emailAddress;

  ParseUserData._init(this.username, this.password, this.emailAddress);

  factory ParseUserData() => _instance;

  @override
  String toString() =>
      "Username: $username \n"
      "Email Address:$emailAddress";
}
