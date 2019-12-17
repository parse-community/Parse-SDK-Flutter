import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:sembast/sembast.dart';

import 'contract_provider_user.dart';
import 'provider_api_user.dart';
import 'provider_db_user.dart';

class UserRepository implements UserProviderContract {
  static UserRepository init(Database dbConnection,
      {UserProviderContract mockDBProvider,
      UserProviderContract mockAPIProvider}) {
    final UserRepository repository = UserRepository();

    if (mockDBProvider != null) {
      repository.db = mockDBProvider;
    } else {
      final StoreRef<String, Map<String, dynamic>> store =
          stringMapStoreFactory.store('repository_user');
      repository.db = UserProviderDB(dbConnection, store);
    }

    if (mockAPIProvider != null) {
      repository.api = mockAPIProvider;
    } else {
      repository.api = UserProviderApi();
    }

    return repository;
  }

  UserProviderContract api;
  UserProviderContract db;

  @override
  Future<User> createUser(
      String username, String password, String emailAddress) async {
    api.createUser(username, password, emailAddress);

    final User user = await api.createUser(username, password, emailAddress);
    if (user != null) {
      await db.createUser(username, password, emailAddress);
    }

    return user;
  }

  @override
  Future<User> currentUser() => db.currentUser();

  @override
  Future<ApiResponse> destroy(User user) async {
    ApiResponse response = await api.destroy(user);
    response = await db.destroy(user);
    return response;
  }

  @override
  Future<ApiResponse> allUsers() => api.allUsers();

  @override
  Future<ApiResponse> getCurrentUserFromServer() =>
      api.getCurrentUserFromServer();

  @override
  Future<ApiResponse> login(User user) => api.login(user);

  @override
  void logout(User user) => api.logout(user);

  @override
  Future<ApiResponse> requestPasswordReset(User user) =>
      api.requestPasswordReset(user);

  @override
  Future<ApiResponse> save(User user) async {
    ApiResponse response = await api.save(user);
    response = await db.save(user);
    return response;
  }

  @override
  Future<ApiResponse> signUp(User user) => api.signUp(user);

  @override
  Future<ApiResponse> verificationEmailRequest(User user) => api.signUp(user);
}
