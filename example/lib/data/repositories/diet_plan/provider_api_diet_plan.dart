import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

class DietPlanProviderApi implements DietPlanProviderContract {
  DietPlanProviderApi();

  @override
  Future<ApiResponse> add(DietPlan item) async {
    return getApiResponse<DietPlan>(await item.save());
  }

  @override
  Future<ApiResponse> addAll(List<DietPlan> items) async {
    final List<DietPlan> responses = List<DietPlan>();

    for (final DietPlan item in items) {
      final ApiResponse response = await add(item);

      if (!response.success) {
        return response;
      }

      response?.results?.forEach(responses.add);
    }

    return ApiResponse(true, 200, responses, null);
  }

  @override
  Future<ApiResponse> getAll() async {
    return getApiResponse<DietPlan>(await DietPlan().getAll());
  }

  @override
  Future<ApiResponse> getById(String id) async {
    return getApiResponse<DietPlan>(await DietPlan().getObject(id));
  }

  @override
  Future<ApiResponse> getNewerThan(DateTime date) async {
    final QueryBuilder<DietPlan> query = QueryBuilder<DietPlan>(DietPlan())
      ..whereGreaterThan(keyVarCreatedAt, date);
    return getApiResponse<DietPlan>(await query.query());
  }

  @override
  Future<ApiResponse> remove(DietPlan item) async {
    return getApiResponse<DietPlan>(await item.delete());
  }

  @override
  Future<ApiResponse> update(DietPlan item) async {
    return getApiResponse<DietPlan>(await item.save());
  }

  @override
  Future<ApiResponse> updateAll(List<DietPlan> items) async {
    final List<DietPlan> responses = List<DietPlan>();

    for (final DietPlan item in items) {
      final ApiResponse response = await update(item);

      if (!response.success) {
        return response;
      }

      response?.results?.forEach(responses.add);
    }

    return ApiResponse(true, 200, responses, null);
  }
}
