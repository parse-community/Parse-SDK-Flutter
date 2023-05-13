import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/user.dart';

abstract class UserProviderContract {
  Future<User> createUser(
      String username, String password, String emailAddress);
  Future<User> currentUser();
  Future<ApiResponse> signUp(User user);
  Future<ApiResponse> login(User user);
  void logout(User user);
  Future<ApiResponse> getCurrentUserFromServer();
  Future<ApiResponse> requestPasswordReset(User user);
  Future<ApiResponse> verificationEmailRequest(User user);
  Future<ApiResponse> save(User user);
  Future<ApiResponse> destroy(User user);
  Future<ApiResponse> allUsers();
}
