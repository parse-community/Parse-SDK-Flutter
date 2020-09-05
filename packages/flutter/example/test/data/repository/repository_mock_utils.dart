import 'dart:io';

import 'package:flutter_plugin_example/data/model/diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_api_diet_plan.dart';
import 'package:flutter_plugin_example/data/repositories/diet_plan/provider_db_diet_plan.dart';
import 'package:flutter_plugin_example/domain/constants/application_constants.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class MockDietPlanProviderApi extends Mock implements DietPlanProviderApi {}

class MockDietPlanProviderDB extends Mock implements DietPlanProviderDB {}

Future<Database> getDB() async {
  final String dbDirectory = Directory.current.path;
  final String dbPath = join(dbDirectory, 'no_sql_test');
  final DatabaseFactory dbFactory = databaseFactoryIo;
  return await dbFactory.openDatabase(dbPath);
}

Future<void> setupParseInstance() async {
  await Parse().initialize(keyParseApplicationId, keyParseServerUrl,
      masterKey: keyParseMasterKey, appName: keyApplicationName, debug: true);
}

DietPlan getDummyDietPlan() {
  return DietPlan()
    ..set('objectId', '1234abcd')
    ..set(keyVarUpdatedAt, DateTime.now())
    ..name = 'Test Diet Plan'
    ..description = 'Some random description about a diet plan'
    ..protein = 40
    ..carbs = 40
    ..fat = 20
    ..status = false;
}

Future<void> deleteFromApi(List<dynamic> results) async {
  if (results != null && results.isNotEmpty) {
    for (final ParseObject item in results) {
      await item.delete();
    }
  }
}
