import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_db_diet_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository_mock_utils.dart';

void main() {
  DietPlanProviderContract repository;
  SharedPreferences.setMockInitialValues(<String, String>{});

  StoreRef<String, Map<String, dynamic>> _getStore(Database database) {
    final StoreRef<String, Map<String, dynamic>> store =
        stringMapStoreFactory.store('repository_diet');
    return store;
  }

  Future<DietPlanProviderContract> getRepository() async {
    if (repository == null) {
      final Database database = await getDB();
      repository ??= DietPlanProviderDB(database, _getStore(database));
    }

    return repository;
  }

  setUp(() async {
    await setupParseInstance();
    await getRepository();
  });

  tearDown(() async {
    final Database database = await getDB();
    _getStore(database).drop(database);
  });

  test('create DB instance', () async {
    expect(true, repository != null);
  });

  test('add DietPlan from DB', () async {
    // arrange
    final DietPlan expected = getDummyDietPlan();

    // act
    final ApiResponse response = await repository.add(expected);
    final DietPlan actual = response.result;

    await deleteFromApi(response.results);

    // assert
    expect(actual.objectId, expected.objectId);
    expect(actual.protein, expected.protein);
  });

  test('addAll DietPlan from DB', () async {
    // arrange
    const String objectIdPrefix = '12345abc';
    final List<DietPlan> actual = <DietPlan>[];

    final DietPlan item1 = getDummyDietPlan();
    item1.objectId = '${objectIdPrefix}0';
    actual.add(item1);

    final DietPlan item2 = getDummyDietPlan();
    item2.objectId = '${objectIdPrefix}1';
    actual.add(item2);

    // act
    final ApiResponse response = await repository.addAll(actual);
    final List<DietPlan> items = response.results;

    // assert
    expect(response.success, true);
    expect(actual[0].objectId, items[0].objectId);
    expect(actual[1].objectId, items[1].objectId);
  });

  test('getById DietPlan from DB', () async {
    // arrange
    final DietPlan actual = getDummyDietPlan();

    // act
    final ApiResponse response = await repository.add(actual);
    final ApiResponse updateResponse = await repository.getById('1234abcd');

    await deleteFromApi(response.results);
    await deleteFromApi(updateResponse.results);

    // assert
    final DietPlan expected = response.result;
    expect(actual.objectId, expected.objectId);
    expect(actual.protein, expected.protein);
  });

  test('getAll DietPlan from DB', () async {
    // arrange
    const String objectIdPrefix = '12345abc';
    final DietPlan item1 = getDummyDietPlan()..objectId = '${objectIdPrefix}0';
    final DietPlan item2 = getDummyDietPlan()..objectId = '${objectIdPrefix}1';
    final List<DietPlan> actual = <DietPlan>[item1, item2];

    // act
    final ApiResponse response = await repository.addAll(actual);

    final ApiResponse updateResponse = await repository.getAll();
    final List<DietPlan> expected = updateResponse.results;

    await deleteFromApi(response.results);
    await deleteFromApi(updateResponse.results);

    // assert
    expect(2, expected.length);
    expect(actual[0].objectId, expected[0].objectId);
    expect(actual[1].objectId, expected[1].objectId);
  });

  test('getNewerThan DietPlan from DB', () async {
    // arrange
    final DietPlan expected = getDummyDietPlan();

    expected[keyVarUpdatedAt] = DateTime.now();
    final ApiResponse response = await repository.add(expected);

    // act
    DateTime dateTime = DateTime.now();
    dateTime = dateTime.subtract(const Duration(hours: 1));
    final ApiResponse updateResponse = await repository.getNewerThan(dateTime);
    final List<DietPlan> actual = updateResponse.results;

    await deleteFromApi(response.results);
    await deleteFromApi(updateResponse.results);

    // assert
    expect(actual.isNotEmpty, true);
    expect(actual.first.objectId, expected.objectId);
  });

  test('update DietPlan from DB', () async {
    // arrange
    final DietPlan item = getDummyDietPlan();
    item.protein = 1000;
    final ApiResponse apiResponse = await repository.add(item);

    // act
    item.protein = 1000;
    final ApiResponse updateResponse = await repository.update(item);
    final DietPlan userFood = updateResponse.result;

    await deleteFromApi(apiResponse.results);
    await deleteFromApi(updateResponse.results);

    // assert
    expect(item.objectId, userFood.objectId);
    expect(userFood.protein, 1000);
  });

  test('updateAll DietPlan from DB', () async {
    // arrange
    const String objectIdPrefix = '12345abc';

    final List<DietPlan> actual = <DietPlan>[];
    final DietPlan item1 = getDummyDietPlan();
    item1.objectId = '${objectIdPrefix}0';
    actual.add(item1);

    final DietPlan item2 = getDummyDietPlan();
    item2.objectId = '${objectIdPrefix}1';
    actual.add(item2);

    final ApiResponse apiResponse = await repository.addAll(actual);

    await deleteFromApi(apiResponse.results);

    // act
    actual[0].protein = 1000;
    actual[1].protein = 1000;
    final ApiResponse updateResponse = await repository.updateAll(actual);
    final List<DietPlan> expected = updateResponse.results;

    await deleteFromApi(updateResponse.results);
    await deleteFromApi(updateResponse.results);
    await deleteFromApi(apiResponse.results);

    // assert
    expect(actual[0].objectId, expected[0].objectId);
    expect(actual[1].objectId, expected[1].objectId);
    expect(expected[0].protein, 1000);
    expect(expected[1].protein, 1000);
  });

  test('delete DietPlan from DB', () async {
    // arrange
    final DietPlan actual = getDummyDietPlan();
    repository.add(actual);

    // act
    repository.remove(actual);
    final ApiResponse response = await repository.getById(actual.objectId);

    // assert
    expect(response.result == null, true);
  });
}
