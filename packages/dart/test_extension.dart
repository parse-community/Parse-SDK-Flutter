import 'package:parse_server_sdk/parse_server_sdk.dart';

Future<void> main() async {
  // Initialize Parse
  await Parse().initialize("keyApplicationId", "keyParseServerUrl",
      clientKey: "keyParseClientKey",
      debug: true,
      autoSendSessionId: true,
      coreStore: CoreStoreMemoryImp());

  // Test if ParseObjectOffline extension is available
  var dietPlan = ParseObject('DietPlan')
    ..set('Name', 'Test')
    ..set('Fat', 50);

  try {
    // Test static method from extension
    var cachedObjects = await ParseObjectOffline.loadAllFromLocalCache('DietPlan');
    print('Extension static method works! Found ${cachedObjects.length} cached objects');
    
    // Test instance method from extension
    await dietPlan.saveToLocalCache();
    print('Extension instance method works! Saved object to cache');
    
  } catch (e) {
    print('Extension methods not available: $e');
  }
}
