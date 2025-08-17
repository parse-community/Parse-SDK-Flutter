import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  // Initialize Parse
  await Parse().initialize(
    'test_app_id',
    'https://test.com',
    clientKey: 'test_client_key',
    debug: false,
  );
  
  // Test if ParseObjectOffline extension is available
  print('Testing ParseObjectOffline extension...');
  
  // Create a test object
  final object = ParseObject('TestClass');
  object.set('name', 'Test Object');
  
  // Test extension methods
  try {
    // This should work if the extension is available
    await object.saveToLocalCache();
    print('✅ saveToLocalCache() method available');
    
    // Test static method
    final cached = await ParseObjectOffline.loadAllFromLocalCache('TestClass');
    print('✅ ParseObjectOffline.loadAllFromLocalCache() available');
    print('Found ${cached.length} cached objects');
    
    print('🎉 ParseObjectOffline extension is working!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
