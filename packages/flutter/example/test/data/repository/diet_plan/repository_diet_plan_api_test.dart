import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_api_diet_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository_mock_utils.dart';

void main() {
  DietPlanProviderContract? repository;
  SharedPreferences.setMockInitialValues(<String, String>{});

  Future<DietPlanProviderContract?> getRepository() async {
    repository ??= DietPlanProviderApi();
    return repository;
  }

  setUp(() async {
    await setupParseInstance();
    await getRepository();
  });

  tearDown(() async {
    repository = null;
  });

  group('API Integration tests', () {
    test('create DB instance', () async {
      expect(true, repository != null);
    });

    test('add DietPlan from API', () async {
      // arrange
      final DietPlan expected = getDummyDietPlan();
      expected['objectId'] = null;

      // act
      final ApiResponse? response = await repository?.add(expected);
      final DietPlan actual = response?.result;

      await deleteFromApi(response?.results);

      // assert
      expect(actual.protein, expected.protein);
    });

    test('addAll DietPlan from API', () async {
      // arrange
      final List<DietPlan> actual = <DietPlan>[];
      final DietPlan item1 = getDummyDietPlan();
      item1['objectId'] = null;
      item1.protein = 5;
      actual.add(item1);
      final DietPlan item2 = getDummyDietPlan();
      item2['objectId'] = null;
      item2.protein = 6;
      actual.add(item2);

      // act
      final ApiResponse? response = await repository?.addAll(actual);
      final List? items = response?.results;

      await deleteFromApi(response?.results);

      // assert
      expect(response?.success, true);
      expect(actual[1].objectId, items?[1].objectId);
    });

    test('getById DietPlan from API', () async {
      // arrange
      final DietPlan dummy = getDummyDietPlan();
      dummy['objectId'] = null;

      // act
      final ApiResponse? response = await repository?.add(dummy);
      final DietPlan expected = response?.result;
      final ApiResponse? updateResponse =
          await repository?.getById(expected.objectId ?? "");
      final DietPlan actual = updateResponse?.result;

      await deleteFromApi(response?.results);
      await deleteFromApi(updateResponse?.results);

      // assert
      expect(actual.objectId, expected.objectId);
      expect(actual.protein, expected.protein);
    });

    test('getNewerThan DietPlan from API', () async {
      // arrange
      final DietPlan dummy = getDummyDietPlan();
      dummy['objectId'] = null;

      // act
      final ApiResponse? baseResponse = await repository?.add(dummy);
      final ApiResponse? responseWithResult = await repository
          ?.getNewerThan(DateTime.now().subtract(const Duration(days: 1)));
      final ApiResponse? responseWithoutResult = await repository
          ?.getNewerThan(DateTime.now().add(const Duration(days: 1)));

      await deleteFromApi(baseResponse?.results);
      await deleteFromApi(responseWithoutResult?.results);
      await deleteFromApi(responseWithResult?.results);

      // assert
      expect(responseWithResult?.success, true);
      expect(responseWithoutResult?.success, true);
      expect(responseWithResult?.result, isNotNull);
      expect(responseWithoutResult?.result, isNull);
    });

    test('getAll DietPlan from API', () async {
      // arrange
      final List<DietPlan> actual = <DietPlan>[];

      final DietPlan item1 = getDummyDietPlan();
      item1['objectId'] = null;
      item1.protein = 5;
      actual.add(item1);
      final DietPlan item2 = getDummyDietPlan();
      item2['objectId'] = null;
      item2.protein = 6;
      actual.add(item2);

      // act
      final ApiResponse? response = await repository?.addAll(actual);

      await deleteFromApi(response?.results);

      // assert
      expect(response?.success, true);
      expect(response?.result, isNotNull);
    });

    test('update DietPlan from API', () async {
      // arrange
      final DietPlan expected = getDummyDietPlan();
      expected['objectId'] = null;
      final ApiResponse? response = await repository?.add(expected);
      final DietPlan initialResponse = response?.result;

      // act
      initialResponse.protein = 10;
      final ApiResponse? updateResponse =
          await repository?.update(initialResponse);
      final DietPlan actual = updateResponse?.result;

      await deleteFromApi(response?.results);
      await deleteFromApi(updateResponse?.results);

      // assert
      expect(actual.protein, 10);
    });

    test('updateAll DietPlan from API', () async {
      // arrange
      final List<DietPlan> actual = <DietPlan>[];

      final DietPlan item1 = getDummyDietPlan();
      item1['objectId'] = null;
      item1.protein = 7;
      actual.add(item1);
      final DietPlan item2 = getDummyDietPlan();
      item2['objectId'] = null;
      item2.protein = 8;
      actual.add(item2);
      await repository?.addAll(actual);

      // act
      item1.protein = 9;
      item2.protein = 10;
      final ApiResponse? updateResponse = await repository?.updateAll(actual);
      final List? updated = updateResponse?.results;

      await deleteFromApi(updateResponse?.results);

      // assert
      expect(updated?[0].protein, 9);
      expect(updated?[1].protein, 10);
    });
  });
}
