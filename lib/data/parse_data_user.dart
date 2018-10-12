class ParseDataUser {
  static ParseDataUser _instance;

  static ParseDataUser get instance => _instance;

  static void init(username, password, emailAddress) =>
      _instance ??= ParseDataUser._init(username, password, emailAddress);

  String username;
  String password;
  String emailAddress;

  ParseDataUser._init(this.username, this.password, this.emailAddress);

  factory ParseDataUser() => _instance;

  @override
  String toString() =>
      "Username: $username \n"
      "Email Address:$emailAddress";
}
