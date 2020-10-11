import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

import 'contract_provider_user.dart';

class UserProviderApi implements UserProviderContract {
  @override
  Future<User> createUser(
      String username, String password, String emailAddress) {
    return Future<User>.value(User(username, password, emailAddress));
  }

  @override
  Future<User> currentUser() {
    return ParseUser.currentUser();
  }

  @override
  Future<ApiResponse> getCurrentUserFromServer() async {
    final ParseUser user = await ParseUser.currentUser();
    return getApiResponse<User>(await ParseUser.getCurrentUserFromServer(
        user?.get<String>(keyHeaderSessionToken)));
  }

  @override
  Future<ApiResponse> destroy(User user) async {
    return getApiResponse<User>(await user.destroy());
  }

  @override
  Future<ApiResponse> login(User user) async {
    return getApiResponse<User>(await user.login());
  }

  @override
  Future<ApiResponse> requestPasswordReset(User user) async {
    return getApiResponse<User>(await user.requestPasswordReset());
  }

  @override
  Future<ApiResponse> save(User user) async {
    return getApiResponse<User>(await user.save());
  }

  @override
  Future<ApiResponse> signUp(User user) async {
    return getApiResponse<User>(await user.signUp());
  }

  @override
  Future<ApiResponse> verificationEmailRequest(User user) async {
    return getApiResponse<User>(await user.verificationEmailRequest());
  }

  @override
  Future<ApiResponse> allUsers() async {
    return getApiResponse(await ParseUser.all());
  }

  @override
  void logout(User user) => user.logout();
}
