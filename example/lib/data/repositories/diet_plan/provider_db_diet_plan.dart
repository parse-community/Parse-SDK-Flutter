import 'dart:convert' as json;

import 'package:flutter_plugin_example/data/base/api_error.dart';
import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:sembast/sembast.dart';

class DietPlanProviderDB implements DietPlanProviderContract {
  DietPlanProviderDB(this._db, this._store);

  final StoreRef<String, Map<String, dynamic>> _store;
  final Database _db;

  @override
  Future<ApiResponse> add(DietPlan item) async {
    final Map<String, dynamic> values = convertItemToStorageMap(item);
    await _store.record(item.objectId).put(_db, values);
    final Map<String, dynamic> recordFromDB =
        await _store.record(item.objectId).get(_db);

    return ApiResponse(
        true, 200, <dynamic>[convertRecordToItem(values: recordFromDB)], null);
  }

  @override
  Future<ApiResponse> addAll(List<DietPlan> items) async {
    final List<DietPlan> itemsInDb = List<DietPlan>();

    for (final DietPlan item in items) {
      final ApiResponse response = await add(item);
      if (response.success) {
        final DietPlan itemInDB = response.result;
        itemsInDb.add(itemInDB);
      }
    }

    if (itemsInDb.isEmpty) {
      return errorResponse;
    } else {
      return ApiResponse(true, 200, itemsInDb, null);
    }
  }

  @override
  Future<ApiResponse> getAll() async {
    final List<DietPlan> foodItems = List<DietPlan>();

    final List<SortOrder> sortOrders = List<SortOrder>();
    sortOrders.add(SortOrder(keyName));
    final Finder finder = Finder(sortOrders: sortOrders);
    final List<RecordSnapshot<String, Map<String, dynamic>>> records =
        await _store.find(_db, finder: finder);

    if (records.isNotEmpty) {
      for (final RecordSnapshot<String, Map<String, dynamic>> record
          in records) {
        final DietPlan userFood = convertRecordToItem(record: record);
        foodItems.add(userFood);
      }
    } else {
      return errorResponse;
    }

    return ApiResponse(true, 200, foodItems, null);
  }

  @override
  Future<ApiResponse> getById(String id) async {
    final Finder finder = Finder(filter: Filter.equals('objectId', id));

    final RecordSnapshot<String, Map<String, dynamic>> record =
        await _store.findFirst(_db, finder: finder);
    if (record != null) {
      final DietPlan userFood = convertRecordToItem(record: record);
      return ApiResponse(true, 200, <dynamic>[userFood], null);
    } else {
      return errorResponse;
    }
  }

  @override
  Future<ApiResponse> getNewerThan(DateTime date) async {
    final List<DietPlan> foodItems = List<DietPlan>();

    final Finder finder = Finder(
        filter:
            Filter.greaterThan(keyVarUpdatedAt, date.millisecondsSinceEpoch));

    final List<RecordSnapshot<String, Map<String, dynamic>>> records =
        await _store.find(_db, finder: finder);

    for (final RecordSnapshot<String, Map<String, dynamic>> record in records) {
      final DietPlan convertedDietPlan = convertRecordToItem(record: record);
      foodItems.add(convertedDietPlan);
    }

    if (records == null) {
      return errorResponse;
    }

    return ApiResponse(true, 200, foodItems, null);
  }

  @override
  Future<ApiResponse> remove(DietPlan item) async {
    final Finder finder =
        Finder(filter: Filter.equals('objectId', item.objectId));
    _store.delete(_db, finder: finder);
    return ApiResponse(true, 200, null, null);
  }

  @override
  Future<ApiResponse> updateAll(List<DietPlan> items) async {
    final List<DietPlan> updatedItems = List<DietPlan>();

    for (final DietPlan item in items) {
      final ApiResponse response = await update(item);
      if (response.success) {
        final DietPlan responseItem = response.result;
        updatedItems.add(responseItem);
      }
    }

    if (updatedItems == null) {
      return errorResponse;
    }

    return ApiResponse(true, 200, updatedItems, null);
  }

  @override
  Future<ApiResponse> update(DietPlan item) async {
    final Map<String, dynamic> values = convertItemToStorageMap(item);
    final Finder finder =
        Finder(filter: Filter.equals('objectId', item.objectId));
    final int returnedCount =
        await _store.update(_db, values, finder: finder);

    if (returnedCount == 0) {
      return add(item);
    }

    return ApiResponse(
        true, 200, <dynamic>[item], null);
  }

  Map<String, dynamic> convertItemToStorageMap(DietPlan item) {
    final Map<String, dynamic> values = Map<String, dynamic>();
    // ignore: invalid_use_of_protected_member
    values['value'] = json.jsonEncode(item.toJson(full: true));
    values[keyVarObjectId] = item.objectId;
    if (item.updatedAt != null) {
      values[keyVarUpdatedAt] = item.updatedAt.millisecondsSinceEpoch;
    }

    return values;
  }

  DietPlan convertRecordToItem(
      {RecordSnapshot<String, Map<String, dynamic>> record,
      Map<String, dynamic> values}) {
    try {
      values ??= record.value;
      final DietPlan item =
          DietPlan.clone().fromJson(json.jsonDecode(values['value']));
      return item;
    } catch (e) {
      return null;
    }
  }

  static ApiError error = ApiError(1, 'No records found', false, '');
  ApiResponse errorResponse = ApiResponse(false, 1, null, error);
}
