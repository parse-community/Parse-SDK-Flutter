import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_api_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_db_diet_plan.dart';
import 'package:flutter_plugin_example/domain/utils/collection_utils.dart';
import 'package:sembast/sembast.dart';

class DietPlanRepository implements DietPlanProviderContract {
  static DietPlanRepository init(Database dbConnection,
      {DietPlanProviderContract repositoryDB,
      DietPlanProviderContract repositoryAPI}) {
    final DietPlanRepository repository = DietPlanRepository();

    if (repositoryDB != null) {
      repository.db = repositoryDB;
    } else {
      final Store store = dbConnection.getStore('repository-$keyDietPlan');
      repository.db = DietPlanProviderDB(dbConnection, store);
    }

    if (repositoryAPI != null) {
      repository.api = repositoryAPI;
    } else {
      repository.api = DietPlanProviderApi();
    }

    return repository;
  }

  DietPlanProviderContract api;
  DietPlanProviderContract db;

  @override
  Future<ApiResponse> add(DietPlan item,
      {bool apiOnly = false, bool dbOnly = false}) async {
    if (apiOnly) {
      return await api.add(item);
    }
    if (dbOnly) {
      return await db.add(item);
    }

    final ApiResponse response = await api.add(item);
    if (response.success) {
      await db.add(item);
    }

    return response;
  }

  @override
  Future<ApiResponse> addAll(List<DietPlan> items,
      {bool apiOnly = false, bool dbOnly = false}) async {
    if (apiOnly) {
      return await api.addAll(items);
    }
    if (dbOnly) {
      return await db.addAll(items);
    }

    final ApiResponse response = await api.addAll(items);

    if (response.success && isValidList(response.result)) {
      await db.addAll(items);
    }

    return response;
  }

  @override
  Future<ApiResponse> getAll(
      {bool fromApi = false, bool fromDb = false}) async {
    if (fromApi) {
      return api.getAll();
    }
    if (fromDb) {
      return db.getAll();
    }

    ApiResponse response = await db.getAll();
    if (response.result == null) {
      response = await api.getAll();
    }

    return db.getAll();
  }

  @override
  Future<ApiResponse> getById(String id,
      {bool fromApi = false, bool fromDb = false}) async {
    if (fromApi) {
      return api.getAll();
    }
    if (fromDb) {
      return db.getAll();
    }

    ApiResponse response = await db.getById(id);
    if (response.result == null) {
      response = await api.getById(id);
    }

    return response;
  }

  @override
  Future<ApiResponse> getNewerThan(DateTime date,
      {bool fromApi = false, bool fromDb = false}) async {
    if (fromApi) {
      return await api.getNewerThan(date);
    }
    if (fromDb) {
      return await db.getNewerThan(date);
    }

    final ApiResponse response = await api.getNewerThan(date);

    if (response.success && response.result != null) {
      final List<DietPlan> list = response.result;
      await db.updateAll(list);
    }

    return response;
  }

  @override
  Future<ApiResponse> remove(DietPlan item,
      {bool apiOnly = false, bool dbOnly = false}) async {
    if (apiOnly) {
      return await api.remove(item);
    }
    if (dbOnly) {
      return await db.remove(item);
    }

    ApiResponse response = await api.remove(item);
    response = await db.remove(item);
    return response;
  }

  @override
  Future<ApiResponse> update(DietPlan item,
      {bool apiOnly = false, bool dbOnly = false}) async {
    if (apiOnly) {
      return await api.update(item);
    }
    if (dbOnly) {
      return await db.update(item);
    }

    ApiResponse response = await api.update(item);
    response = await db.update(item);
    return response;
  }

  @override
  Future<ApiResponse> updateAll(List<DietPlan> items,
      {bool apiOnly = false, bool dbOnly = false}) async {
    if (apiOnly) {
      await api.updateAll(items);
    }
    if (dbOnly) {
      await db.updateAll(items);
    }

    ApiResponse response = await api.updateAll(items);
    if (response.success && isValidList(response.result)) {
      response = await db.updateAll(items);
    }

    return response;
  }
}
