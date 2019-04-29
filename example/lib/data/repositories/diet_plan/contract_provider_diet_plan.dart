import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';

abstract class DietPlanProviderContract {
  Future<ApiResponse> add(DietPlan item);

  Future<ApiResponse> addAll(List<DietPlan> items);

  Future<ApiResponse> update(DietPlan item);

  Future<ApiResponse> updateAll(List<DietPlan> items);

  Future<ApiResponse> remove(DietPlan item);

  Future<ApiResponse> getById(String id);

  Future<ApiResponse> getAll();

  Future<ApiResponse> getNewerThan(DateTime date);
}
