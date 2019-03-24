import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_db_diet_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../repository_mock_utils.dart';

void main() {
  DietPlanProviderContract repository;

  Store _getStore(Database database) {
    return database.getStore('repository_$keyDietPlan');
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
    final Store store = _getStore(database);
    store.clear();
    database.clear();
  });

  test('create DB instance', () async {
    expect(true, repository != null);
  });

  test('add DietPlan from DB', () async {
    // Given
    final DietPlan expected = getDummyDietPlan();

    // When
    final ApiResponse response = await repository.add(expected);
    final DietPlan actual = response.result;

    // Then
    expect(actual.objectId, expected.objectId);
    expect(actual.protein, expected.protein);
  });

  test('addAll DietPlan from DB', () async {
    // Given
    const String objectIdPrefix = '12345abc';
    final List<DietPlan> actual = List<DietPlan>();

    final DietPlan item1 = getDummyDietPlan();
    item1.objectId = '${objectIdPrefix}0';
    actual.add(item1);

    final DietPlan item2 = getDummyDietPlan();
    item2.objectId = '${objectIdPrefix}1';
    actual.add(item2);

    // When
    final ApiResponse response = await repository.addAll(actual);
    final List<DietPlan> items = await response.result;

    // Then
    expect(response.success, true);
    expect(actual[0].objectId, items[0].objectId);
    expect(actual[1].objectId, items[1].objectId);
  });

  test('getById DietPlan from DB', () async {
    // Given
    final DietPlan actual = getDummyDietPlan();

    // When
    await repository.add(actual);
    final ApiResponse response = await repository.getById('1234abcd');

    // Then
    final DietPlan expected = response.result;
    expect(actual.objectId, expected.objectId);
    expect(actual.protein, expected.protein);
  });

  test('getAll DietPlan from DB', () async {
    // Given
    const String objectIdPrefix = '12345abc';
    final DietPlan item1 = getDummyDietPlan()..objectId = '${objectIdPrefix}0';
    final DietPlan item2 = getDummyDietPlan()..objectId = '${objectIdPrefix}1';
    final List<DietPlan> actual = List<DietPlan>()..add(item1)..add(item2);

    // When
    await repository.addAll(actual);

    // Then
    final ApiResponse response = await repository.getAll();
    final List<DietPlan> expected = response.result;

    expect(2, expected.length);
    expect(actual[0].objectId, expected[0].objectId);
    expect(actual[1].objectId, expected[1].objectId);
  });

  test('getNewerThan DietPlan from DB', () async {
    // Given
    final DietPlan expected = getDummyDietPlan();
    // ignore: invalid_use_of_protected_member
    expected.getObjectData()['keyUpdatedAt'] = DateTime.now();
    await repository.add(expected);

    // When
    DateTime dateTime = DateTime.now();
    dateTime = dateTime.subtract(Duration(hours: 1));
    final ApiResponse response = await repository.getNewerThan(dateTime);
    final List<DietPlan> actual = response.result;

    // Then
    expect(actual.isNotEmpty, true);
    expect(actual.first.objectId, expected.objectId);
  });

  test('update DietPlan from DB', () async {
    // Given
    final DietPlan item = getDummyDietPlan();
    item.protein = 1000;
    await repository.add(item);

    // When
    item.protein = 1000;
    final ApiResponse response = await repository.update(item);
    final DietPlan userFood = response.result;

    // Then
    expect(item.objectId, userFood.objectId);
    expect(userFood.protein, 1000);
  });

  test('updateAll DietPlan from DB', () async {
    // Given
    const String objectIdPrefix = '12345abc';

    final List<DietPlan> actual = List<DietPlan>();
    final DietPlan item1 = getDummyDietPlan();
    item1.objectId = '${objectIdPrefix}0';
    actual.add(item1);

    final DietPlan item2 = getDummyDietPlan();
    item2.objectId = '${objectIdPrefix}1';
    actual.add(item2);

    await repository.addAll(actual);

    // When
    actual[0].protein = 1000;
    actual[1].protein = 1000;
    final ApiResponse response = await repository.updateAll(actual);
    final List<DietPlan> expected = response.result;

    // Then
    expect(actual[0].objectId, expected[0].objectId);
    expect(actual[1].objectId, expected[1].objectId);
    expect(expected[0].protein, 1000);
    expect(expected[1].protein, 1000);
  });

  test('delete DietPlan from DB', () async {
    // Given
    final DietPlan actual = getDummyDietPlan();
    await repository.add(actual);

    // When
    await repository.remove(actual);
    final ApiResponse response = await repository.getById(actual.objectId);

    // Then
    expect(response.result == null, true);
  });
}
