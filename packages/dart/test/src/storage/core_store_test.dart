import 'package:test/test.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() {
  late CoreStoreMemoryImp store;

  setUp(() async {
    store = CoreStoreMemoryImp();
    await store.clear();
  });

  group('CoreStore getStringList', () {
    test('should return null when key does not exist', () async {
      final result = await store.getStringList('nonexistent_key');
      expect(result, isNull);
    });

    test('should return List<String> when stored as List<String>', () async {
      final testList = ['item1', 'item2', 'item3'];
      await store.setStringList('test_key', testList);

      final result = await store.getStringList('test_key');

      expect(result, isNotNull);
      expect(result, isA<List<String>>());
      expect(result, equals(testList));
    });

    test('should return empty list when stored empty list', () async {
      final testList = <String>[];
      await store.setStringList('empty_key', testList);

      final result = await store.getStringList('empty_key');

      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    test('should handle list with special characters', () async {
      final testList = [
        'item with spaces',
        'item\nwith\nnewlines',
        'item,with,commas',
        '{"json": "object"}',
      ];
      await store.setStringList('special_key', testList);

      final result = await store.getStringList('special_key');

      expect(result, isNotNull);
      expect(result, equals(testList));
    });

    test('should handle list with empty strings', () async {
      final testList = ['', 'non-empty', ''];
      await store.setStringList('empty_strings_key', testList);

      final result = await store.getStringList('empty_strings_key');

      expect(result, isNotNull);
      expect(result, equals(testList));
    });

    test('should handle list with unicode characters', () async {
      final testList = ['emoji 🎉', '日本語', 'العربية', 'מחרוזת'];
      await store.setStringList('unicode_key', testList);

      final result = await store.getStringList('unicode_key');

      expect(result, isNotNull);
      expect(result, equals(testList));
    });

    test('should overwrite existing list', () async {
      final firstList = ['a', 'b', 'c'];
      final secondList = ['x', 'y', 'z'];

      await store.setStringList('overwrite_key', firstList);
      await store.setStringList('overwrite_key', secondList);

      final result = await store.getStringList('overwrite_key');

      expect(result, equals(secondList));
    });

    test('should handle very long list', () async {
      final longList = List.generate(1000, (index) => 'item_$index');
      await store.setStringList('long_list_key', longList);

      final result = await store.getStringList('long_list_key');

      expect(result, isNotNull);
      expect(result?.length, 1000);
      expect(result?.first, 'item_0');
      expect(result?.last, 'item_999');
    });

    test('should return null for non-list values', () async {
      // Store a string value
      await store.setString('string_key', 'just a string');

      // getStringList should return null for non-list values
      final result = await store.getStringList('string_key');

      // This tests the improved getStringList handling
      // It should handle non-list types gracefully by returning null
      expect(result, isNull);
    });
  });

  group('CoreStore basic operations', () {
    test('should store and retrieve string', () async {
      await store.setString('string_test', 'hello world');
      final result = await store.getString('string_test');
      expect(result, 'hello world');
    });

    test('should store and retrieve int', () async {
      await store.setInt('int_test', 42);
      final result = await store.getInt('int_test');
      expect(result, 42);
    });

    test('should store and retrieve double', () async {
      await store.setDouble('double_test', 3.14159);
      final result = await store.getDouble('double_test');
      expect(result, closeTo(3.14159, 0.0001));
    });

    test('should store and retrieve bool', () async {
      await store.setBool('bool_test', true);
      final result = await store.getBool('bool_test');
      expect(result, true);
    });

    test('should check if key exists', () async {
      await store.setString('exists_key', 'value');

      final exists = await store.containsKey('exists_key');
      final notExists = await store.containsKey('not_exists_key');

      expect(exists, isTrue);
      expect(notExists, isFalse);
    });

    test('should remove key', () async {
      await store.setString('remove_key', 'to be removed');
      await store.remove('remove_key');

      final exists = await store.containsKey('remove_key');
      expect(exists, isFalse);
    });

    test('should clear all keys', () async {
      await store.setString('key1', 'value1');
      await store.setString('key2', 'value2');

      await store.clear();

      final exists1 = await store.containsKey('key1');
      final exists2 = await store.containsKey('key2');

      expect(exists1, isFalse);
      expect(exists2, isFalse);
    });
  });

  group('CoreStore edge cases', () {
    test('should handle null returns gracefully', () async {
      final stringResult = await store.getString('missing');
      final intResult = await store.getInt('missing');
      final doubleResult = await store.getDouble('missing');
      final boolResult = await store.getBool('missing');
      final listResult = await store.getStringList('missing');

      expect(stringResult, isNull);
      expect(intResult, isNull);
      expect(doubleResult, isNull);
      expect(boolResult, isNull);
      expect(listResult, isNull);
    });

    test('should handle special key names', () async {
      const specialKeys = [
        'key.with.dots',
        'key-with-dashes',
        'key_with_underscores',
        'key/with/slashes',
        'key:with:colons',
      ];

      for (final key in specialKeys) {
        await store.setString(key, 'value for $key');
        final result = await store.getString(key);
        expect(result, 'value for $key', reason: 'Failed for key: $key');
      }
    });
  });
}
