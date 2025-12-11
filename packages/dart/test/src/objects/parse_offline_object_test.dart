import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('ParseObjectOffline Extension', () {
    const testClassName = 'TestOfflineClass';

    setUp(() async {
      // Clear cache before each test
      await ParseObjectOffline.clearLocalCacheForClass(testClassName);
    });

    tearDown(() async {
      // Clean up after each test
      await ParseObjectOffline.clearLocalCacheForClass(testClassName);
    });

    group('saveToLocalCache', () {
      test('should save object to local cache', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'test123'
          ..set('name', 'Test Object')
          ..set('value', 42);

        // Act
        await obj.saveToLocalCache();

        // Assert
        final exists = await ParseObjectOffline.existsInLocalCache(
          testClassName,
          'test123',
        );
        expect(exists, isTrue);
      });

      test('should update existing object in cache', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'test123'
          ..set('name', 'Original Name');

        await obj.saveToLocalCache();

        // Act - Update the object
        obj.set('name', 'Updated Name');
        await obj.saveToLocalCache();

        // Assert
        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'test123',
        );
        expect(loaded, isNotNull);
        expect(loaded!.get<String>('name'), equals('Updated Name'));
      });
    });

    group('loadFromLocalCache', () {
      test('should load object from local cache', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'load123'
          ..set('name', 'Load Test')
          ..set('count', 100);

        await obj.saveToLocalCache();

        // Act
        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'load123',
        );

        // Assert
        expect(loaded, isNotNull);
        expect(loaded!.objectId, equals('load123'));
        expect(loaded.get<String>('name'), equals('Load Test'));
        expect(loaded.get<int>('count'), equals(100));
      });

      test('should return null for non-existent object', () async {
        // Act
        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'nonexistent',
        );

        // Assert
        expect(loaded, isNull);
      });
    });

    group('saveAllToLocalCache', () {
      test('should save multiple objects to cache', () async {
        // Arrange
        final objects = List.generate(5, (i) {
          return ParseObject(testClassName)
            ..objectId = 'batch$i'
            ..set('index', i);
        });

        // Act
        await ParseObjectOffline.saveAllToLocalCache(testClassName, objects);

        // Assert
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(5));
        for (int i = 0; i < 5; i++) {
          expect(ids.contains('batch$i'), isTrue);
        }
      });

      test('should update existing and add new objects in batch', () async {
        // Arrange - Save initial objects
        final initialObjects = [
          ParseObject(testClassName)
            ..objectId = 'obj1'
            ..set('value', 'initial1'),
          ParseObject(testClassName)
            ..objectId = 'obj2'
            ..set('value', 'initial2'),
        ];
        await ParseObjectOffline.saveAllToLocalCache(
          testClassName,
          initialObjects,
        );

        // Act - Update one and add new
        final updateObjects = [
          ParseObject(testClassName)
            ..objectId = 'obj1'
            ..set('value', 'updated1'),
          ParseObject(testClassName)
            ..objectId = 'obj3'
            ..set('value', 'new3'),
        ];
        await ParseObjectOffline.saveAllToLocalCache(
          testClassName,
          updateObjects,
        );

        // Assert
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(3)); // obj1, obj2, obj3

        final updated = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'obj1',
        );
        expect(updated!.get<String>('value'), equals('updated1'));
      });

      test('should skip objects without objectId', () async {
        // Arrange
        final objects = [
          ParseObject(testClassName)
            ..objectId = 'valid1'
            ..set('value', 1),
          ParseObject(testClassName)..set('value', 2), // No objectId
        ];

        // Act
        await ParseObjectOffline.saveAllToLocalCache(testClassName, objects);

        // Assert
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(1));
        expect(ids.first, equals('valid1'));
      });
    });

    group('loadAllFromLocalCache', () {
      test('should load all objects from cache', () async {
        // Arrange
        final objects = List.generate(3, (i) {
          return ParseObject(testClassName)
            ..objectId = 'all$i'
            ..set('index', i);
        });
        await ParseObjectOffline.saveAllToLocalCache(testClassName, objects);

        // Act
        final loaded = await ParseObjectOffline.loadAllFromLocalCache(
          testClassName,
        );

        // Assert
        expect(loaded.length, equals(3));
      });

      test('should return empty list for empty cache', () async {
        // Act
        final loaded = await ParseObjectOffline.loadAllFromLocalCache(
          'EmptyClass',
        );

        // Assert
        expect(loaded, isEmpty);
      });
    });

    group('removeFromLocalCache', () {
      test('should remove object from cache', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'remove123'
          ..set('name', 'To Remove');
        await obj.saveToLocalCache();

        // Act
        await obj.removeFromLocalCache();

        // Assert
        final exists = await ParseObjectOffline.existsInLocalCache(
          testClassName,
          'remove123',
        );
        expect(exists, isFalse);
      });
    });

    group('updateInLocalCache', () {
      test('should update specific fields in cached object', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'update123'
          ..set('name', 'Original')
          ..set('count', 1);
        await obj.saveToLocalCache();

        // Act
        await obj.updateInLocalCache({'name': 'Modified', 'count': 99});

        // Assert
        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'update123',
        );
        expect(loaded!.get<String>('name'), equals('Modified'));
        expect(loaded.get<int>('count'), equals(99));
      });
    });

    group('existsInLocalCache', () {
      test('should return true for existing object', () async {
        // Arrange
        final obj = ParseObject(testClassName)
          ..objectId = 'exists123'
          ..set('name', 'Exists');
        await obj.saveToLocalCache();

        // Act
        final exists = await ParseObjectOffline.existsInLocalCache(
          testClassName,
          'exists123',
        );

        // Assert
        expect(exists, isTrue);
      });

      test('should return false for non-existing object', () async {
        // Act
        final exists = await ParseObjectOffline.existsInLocalCache(
          testClassName,
          'nonexistent',
        );

        // Assert
        expect(exists, isFalse);
      });
    });

    group('clearLocalCacheForClass', () {
      test('should clear all objects for a class', () async {
        // Arrange
        final objects = List.generate(5, (i) {
          return ParseObject(testClassName)
            ..objectId = 'clear$i'
            ..set('index', i);
        });
        await ParseObjectOffline.saveAllToLocalCache(testClassName, objects);

        // Act
        await ParseObjectOffline.clearLocalCacheForClass(testClassName);

        // Assert
        final loaded = await ParseObjectOffline.loadAllFromLocalCache(
          testClassName,
        );
        expect(loaded, isEmpty);
      });
    });

    group('getAllObjectIdsInLocalCache', () {
      test('should return all object IDs', () async {
        // Arrange
        final objects = [
          ParseObject(testClassName)
            ..objectId = 'id1'
            ..set('v', 1),
          ParseObject(testClassName)
            ..objectId = 'id2'
            ..set('v', 2),
          ParseObject(testClassName)
            ..objectId = 'id3'
            ..set('v', 3),
        ];
        await ParseObjectOffline.saveAllToLocalCache(testClassName, objects);

        // Act
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );

        // Assert
        expect(ids.length, equals(3));
        expect(ids, containsAll(['id1', 'id2', 'id3']));
      });

      test('should return empty list for empty cache', () async {
        // Act
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          'EmptyClass',
        );

        // Assert
        expect(ids, isEmpty);
      });
    });
  });
}
