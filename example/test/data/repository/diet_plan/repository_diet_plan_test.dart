import 'package:flutter_plugin_example/data/base/api_response.dart';
import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/contract_provider_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/repository_diet_plan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository_mock_utils.dart';

void main() {
  DietPlanRepository repository;
  SharedPreferences.setMockInitialValues(Map<String, String>());

  DietPlanProviderContract apiRepository;
  DietPlanProviderContract dbRepository;

  Future<DietPlanProviderContract> getApiRepository() async {
    final DietPlanProviderContract repositoryApi = MockDietPlanProviderApi();

    const String objectIdPrefix = '12345abc';
    final DietPlan item1 = getDummyDietPlan()..objectId = '${objectIdPrefix}0';
    final DietPlan item2 = getDummyDietPlan()..objectId = '${objectIdPrefix}1';
    final List<DietPlan> mockList = List<DietPlan>()..add(item1)..add(item2);

    when(repositoryApi.add(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(
            ApiResponse(true, 200, <dynamic>[getDummyDietPlan()], null)));
    when(repositoryApi.addAll(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(ApiResponse(true, 200, mockList, null)));
    when(repositoryApi.update(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(
            ApiResponse(true, 200, <dynamic>[getDummyDietPlan()], null)));
    when(repositoryApi.updateAll(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(ApiResponse(true, 200, mockList, null)));
    when(repositoryApi.getNewerThan(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(ApiResponse(true, 200, mockList, null)));
    when(repositoryApi.getById(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(
            ApiResponse(true, 200, <dynamic>[getDummyDietPlan()], null)));
    when(repositoryApi.getById(any)).thenAnswer((_) async =>
        Future<ApiResponse>.value(ApiResponse(true, 200, mockList, null)));

    return repositoryApi;
  }

  Future<DietPlanProviderContract> getDBRepository() {
    return Future<DietPlanProviderContract>.value(MockDietPlanProviderDB());
  }

  Future<DietPlanRepository> getRepository() async {
    apiRepository = await getApiRepository();
    dbRepository = await getDBRepository();

    final DietPlanRepository repository = DietPlanRepository.init(null,
        mockDBProvider: dbRepository, mockAPIProvider: apiRepository);

    return repository;
  }

  setUp(() async {
    await setupParseInstance();
    repository = await getRepository();
  });

  test('create DB instance', () async {
    expect(true, repository != null);
  });

  test('add DietPlan from DB', () async {
    // Given && When
    await repository.add(any);

    // Then
    verify(dbRepository.add(any)).called(1);
    verify(apiRepository.add(any)).called(1);
  });

  test('addAll DietPlan from DB', () async {
    // Given && When
    await repository.addAll(any);

    // Then
    verify(dbRepository.addAll(any)).called(1);
    verify(apiRepository.addAll(any)).called(1);
  });

  test('getAll DietPlan from DB', () async {
    // Given && When
    await repository.getAll();

    // Then
    verify(dbRepository.getAll()).called(1);
    verifyNever(apiRepository.getAll());
  });

  test('getAll DietPlan from API', () async {
    // Given && When
    await repository.getAll(fromApi: true);

    // Then
    verifyNever(dbRepository.getAll());
    verify(apiRepository.getAll()).called(1);
  });

  test('getNewerThan DietPlan from DB', () async {
    // Given && When
    await repository.getNewerThan(DateTime.now());

    // Then
    verifyNever(dbRepository.getNewerThan(DateTime.now()));
    verify(apiRepository.getNewerThan(any));
  });

  test('updateAll DietPlan from DB', () async {
    // Given && When
    await repository.updateAll(any);

    // Then
    verify(dbRepository.updateAll(any)).called(1);
    verify(apiRepository.updateAll(any)).called(1);
  });

  test('delete DietPlan from DB', () async {
    // Given && When
    await repository.remove(any);

    // Then
    verify(dbRepository.remove(any)).called(1);
    verify(apiRepository.remove(any)).called(1);
  });
}
