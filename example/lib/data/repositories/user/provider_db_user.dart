import 'dart:convert' as json;

import 'package:flutter_plugin_example/data/base/api_error.dart';
import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/user.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:sembast/sembast.dart';

import 'contract_provider_user.dart';

class UserProviderDB implements UserProviderContract {
  UserProviderDB(this._db, this._store);

  final StoreRef<String, Map<String, dynamic>> _store;
  final Database _db;

  @override
  Future<User> createUser(
      String username, String password, String emailAddress) async {
    final User user = User(username, password, emailAddress);
    final Map<String, dynamic> values = convertItemToStorageMap(user);
    await _store.record(user.objectId).put(_db, values);
    final Map<String, dynamic> recordFromDB =
        await _store.record(user.objectId).get(_db);
    return convertRecordToItem(record: recordFromDB);
  }

  @override
  Future<User> currentUser() {
    return null;
  }

  @override
  Future<ApiResponse> getCurrentUserFromServer() async {
    return null;
  }

  @override
  Future<ApiResponse> destroy(User user) async {
    final Finder finder =
        Finder(filter: Filter.equals('objectId', user.objectId));
    await _store.delete(_db, finder: finder);
    return ApiResponse(true, 200, null, null);
  }

  @override
  Future<ApiResponse> login(User user) async {
    return null;
  }

  @override
  Future<ApiResponse> requestPasswordReset(User user) async {
    return null;
  }

  @override
  Future<ApiResponse> save(User user) async {
    final Map<String, dynamic> values = convertItemToStorageMap(user);
    await _store.record(user.objectId).put(_db, values);
    final Map<String, dynamic> recordFromDB =
        await _store.record(user.objectId).get(_db);
    return ApiResponse(
        true, 200, <dynamic>[convertRecordToItem(record: recordFromDB)], null);
  }

  @override
  Future<ApiResponse> signUp(User user) {
    return null;
  }

  @override
  Future<ApiResponse> verificationEmailRequest(User user) async {
    return null;
  }

  @override
  Future<ApiResponse> allUsers() async {
    return null;
  }

  @override
  void logout(User user) {}

  Map<String, dynamic> convertItemToStorageMap(User item) {
    final Map<String, dynamic> values = Map<String, dynamic>();
    // ignore: invalid_use_of_protected_member
    values['value'] = json.jsonEncode(item.toJson(full: true));
    values[keyVarObjectId] = item.objectId;
    item.updatedAt != null
        ? values[keyVarUpdatedAt] = item.updatedAt.millisecondsSinceEpoch
        : values[keyVarCreatedAt] = DateTime.now().millisecondsSinceEpoch;
    return values;
  }

  User convertRecordToItem({dynamic record, Map<String, dynamic> values}) {
    try {
      values ??= record.value;
      final User item = User.clone().fromJson(json.jsonDecode(values['value']));
      return item;
    } catch (e) {
      return null;
    }
  }

  static ApiError error = ApiError(1, 'No records found', false, '');
  ApiResponse errorResponse = ApiResponse(false, 1, null, error);
}
