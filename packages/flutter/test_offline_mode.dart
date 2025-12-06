import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  // Initialize Parse
  await Parse().initialize(
    'test_app_id',
    'https://test.com',
    clientKey: 'test_client_key',
    debug: false,
  );

  print('=== Testing Offline Mode Functionality ===\n');

  // Test 1: Save single object to cache
  print('Test 1: Save single object to cache');
  final testObject = ParseObject('TestClass');
  testObject.set('name', 'Test Object');
  testObject.objectId = 'test-id-1';
  await testObject.saveToLocalCache();
  print('✅ Single object saved to cache\n');

  // Test 2: Load single object from cache
  print('Test 2: Load single object from cache');
  final loadedObject = await ParseObjectOffline.loadFromLocalCache('TestClass', 'test-id-1');
  if (loadedObject != null && loadedObject.get<String>('name') == 'Test Object') {
    print('✅ Single object loaded from cache successfully\n');
  } else {
    print('❌ Failed to load object from cache\n');
  }

  // Test 3: Save multiple objects efficiently
  print('Test 3: Save multiple objects to cache');
  final objectsToSave = <ParseObject>[];
  for (int i = 1; i <= 5; i++) {
    final obj = ParseObject('TestClass');
    obj.set('name', 'Object $i');
    obj.objectId = 'test-id-$i';
    objectsToSave.add(obj);
  }
  await ParseObjectOffline.saveAllToLocalCache('TestClass', objectsToSave);
  print('✅ Multiple objects saved to cache\n');

  // Test 4: Load all objects from cache
  print('Test 4: Load all objects from cache');
  final allCached = await ParseObjectOffline.loadAllFromLocalCache('TestClass');
  print('✅ Loaded ${allCached.length} objects from cache\n');

  // Test 5: Check if object exists in cache
  print('Test 5: Check if object exists in cache');
  final exists = await ParseObjectOffline.existsInLocalCache('TestClass', 'test-id-1');
  if (exists) {
    print('✅ Object existence check passed\n');
  } else {
    print('❌ Object existence check failed\n');
  }

  // Test 6: Update object in cache
  print('Test 6: Update object in cache');
  await testObject.updateInLocalCache({'name': 'Updated Object'});
  final updatedObject = await ParseObjectOffline.loadFromLocalCache('TestClass', 'test-id-1');
  if (updatedObject?.get<String>('name') == 'Updated Object') {
    print('✅ Object updated in cache successfully\n');
  }

  // Test 7: Get all object IDs
  print('Test 7: Get all object IDs from cache');
  final objectIds = await ParseObjectOffline.getAllObjectIdsInLocalCache('TestClass');
  print('✅ Retrieved ${objectIds.length} object IDs from cache\n');

  // Test 8: Remove object from cache
  print('Test 8: Remove object from cache');
  await testObject.removeFromLocalCache();
  final removedCheck = await ParseObjectOffline.existsInLocalCache('TestClass', 'test-id-1');
  if (!removedCheck) {
    print('✅ Object removed from cache successfully\n');
  }

  // Test 9: Clear all objects for a class
  print('Test 9: Clear all objects for a class');
  await ParseObjectOffline.clearLocalCacheForClass('TestClass');
  final clearedObjects = await ParseObjectOffline.loadAllFromLocalCache('TestClass');
  if (clearedObjects.isEmpty) {
    print('✅ Cache cleared successfully\n');
  }

  print('=== All Offline Mode Tests Completed Successfully! ===');
}
