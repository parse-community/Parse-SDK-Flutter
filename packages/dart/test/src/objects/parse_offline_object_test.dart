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

    group('map key versioning', () {
      test('a class named X_v2 does not collide with class X', () async {
        // The map key used to be '${cacheKey}_v2', so class 'X_v2' produced
        // offline_cache_X_v2 — the live map key of class 'X'. Clearing one
        // therefore wiped the other.
        await (ParseObject('X')..objectId = 'belongsToX').saveToLocalCache();
        await (ParseObject(
          'X_v2',
        )..objectId = 'belongsToXv2').saveToLocalCache();

        await ParseObjectOffline.clearLocalCacheForClass('X_v2');

        final survivors = await ParseObjectOffline.loadAllFromLocalCache('X');
        expect(
          survivors.map((o) => o.objectId),
          equals(['belongsToX']),
          reason: 'clearing X_v2 must not touch class X',
        );
        await ParseObjectOffline.clearLocalCacheForClass('X');
      });

      test(
        'clearing class X_v2 does not destroy class X before it migrates',
        () async {
          // offline_cache_X_v2 is BOTH the raw list-format key of class 'X_v2'
          // and the unmigrated map key of class 'X'. Clearing X_v2 must not
          // take X's cache with it.
          final store = ParseCoreData().getStore();
          await store.setString(
            'offline_cache_X_v2',
            '{"xOnly":"{\\"className\\":\\"X\\",'
                '\\"objectId\\":\\"xOnly\\",\\"name\\":\\"Belongs to X\\"}"}',
          );

          await ParseObjectOffline.clearLocalCacheForClass('X_v2');

          final survived = await ParseObjectOffline.loadFromLocalCache(
            'X',
            'xOnly',
          );
          expect(
            survived,
            isNotNull,
            reason: "clearing X_v2 must not delete class X's unmigrated cache",
          );
          expect(survived!.get<String>('name'), equals('Belongs to X'));
          await ParseObjectOffline.clearLocalCacheForClass('X');
        },
      );

      test('an existing _v2 cache is moved to the new key', () async {
        final store = ParseCoreData().getStore();
        const base = 'offline_cache_$testClassName';
        await store.setString(
          '${base}_v2',
          '{"old1":"{\\"className\\":\\"$testClassName\\",'
              '\\"objectId\\":\\"old1\\",\\"name\\":\\"Legacy\\"}"}',
        );

        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'old1',
        );
        expect(loaded, isNotNull);
        expect(loaded!.get<String>('name'), equals('Legacy'));

        // Moved once, not read from the old key forever.
        expect(await store.getString('$base:v2'), isNotNull);
        expect(await store.getString('${base}_v2'), isNull);
      });
    });

    group('updateInLocalCache encoding', () {
      test('encodes raw values into Parse wire format', () async {
        final when = DateTime.utc(2026, 8, 10, 12, 30);
        final obj = ParseObject(testClassName)
          ..objectId = 'encode1'
          ..set('name', 'before');
        await obj.saveToLocalCache();

        // Cached entries hold what toJson(full: true) produces. A raw DateTime
        // or ParseGeoPoint merged in as-is would not survive the round trip.
        final updated = await obj.updateInLocalCache({
          'name': 'after',
          'when': when,
          'where': ParseGeoPoint(latitude: 1.5, longitude: -2.5),
        });
        expect(updated, isTrue);

        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'encode1',
        );
        expect(loaded, isNotNull);
        expect(loaded!.get<String>('name'), equals('after'));
        // Decodes back as real Parse types, the same as a server response.
        expect(loaded.get<DateTime>('when'), equals(when));
        final geo = loaded.get<ParseGeoPoint>('where');
        expect(geo, isNotNull);
        expect(geo!.latitude, equals(1.5));
        expect(geo.longitude, equals(-2.5));
      });
    });

    group('legacy format migration', () {
      test('migrates a List<String> cache and drops the legacy key', () async {
        // Arrange: seed the pre-map format directly under the legacy key.
        final store = ParseCoreData().getStore();
        const legacyKey = 'offline_cache_$testClassName';
        await store.setStringList(legacyKey, <String>[
          '{"className":"$testClassName","objectId":"legacy1","name":"One"}',
          '{"className":"$testClassName","objectId":"legacy2","name":"Two"}',
        ]);

        // Act
        final loaded = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'legacy1',
        );

        // Assert: the object survives the migration...
        expect(loaded, isNotNull);
        expect(loaded!.objectId, equals('legacy1'));
        expect(loaded.get<String>('name'), equals('One'));

        // ...the rest of the bucket came across too...
        final all = await ParseObjectOffline.loadAllFromLocalCache(
          testClassName,
        );
        expect(all.length, equals(2));

        // ...and the legacy key is gone, so it migrates exactly once.
        expect(await store.getStringList(legacyKey), isNull);
        expect(await store.getString('$legacyKey:v2'), isNotNull);
      });
    });

    group('concurrent mutations', () {
      test('concurrent saves of different ids all survive', () async {
        // Every mutation is a read-modify-write of one map. Without
        // per-key serialisation these interleave and the last writer wins,
        // silently dropping the others.
        final objects = List.generate(20, (i) {
          return ParseObject(testClassName)
            ..objectId = 'concurrent$i'
            ..set('index', i);
        });

        // Act: fire them all off without awaiting in between.
        await Future.wait(objects.map((o) => o.saveToLocalCache()));

        // Assert
        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(20));
        for (var i = 0; i < 20; i++) {
          expect(ids, contains('concurrent$i'));
        }
      });

      test('concurrent batch saves do not clobber each other', () async {
        List<ParseObject> batch(String prefix) => List.generate(10, (i) {
          return ParseObject(testClassName)
            ..objectId = '$prefix$i'
            ..set('index', i);
        });

        await Future.wait([
          ParseObjectOffline.saveAllToLocalCache(testClassName, batch('a')),
          ParseObjectOffline.saveAllToLocalCache(testClassName, batch('b')),
          ParseObjectOffline.saveAllToLocalCache(testClassName, batch('c')),
        ]);

        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(30));
      });

      test('concurrent save and remove leave a consistent cache', () async {
        final keep = List.generate(10, (i) {
          return ParseObject(testClassName)
            ..objectId = 'keep$i'
            ..set('index', i);
        });
        final doomed = ParseObject(testClassName)
          ..objectId = 'doomed'
          ..set('index', -1);
        await ParseObjectOffline.saveAllToLocalCache(testClassName, [doomed]);

        await Future.wait(<Future<void>>[
          ...keep.map((o) => o.saveToLocalCache()),
          doomed.removeFromLocalCache(),
        ]);

        final ids = await ParseObjectOffline.getAllObjectIdsInLocalCache(
          testClassName,
        );
        expect(ids.length, equals(10));
        expect(ids, isNot(contains('doomed')));
      });
    });

    group('cacheNamespace', () {
      tearDown(() async {
        await ParseObjectOffline.clearLocalCacheForClass(testClassName);
        ParseObjectOffline.cacheNamespace = null;
        await ParseObjectOffline.clearLocalCacheForClass(testClassName);
      });

      test('separates the caches of two accounts', () async {
        // Account A caches an object.
        ParseObjectOffline.cacheNamespace = 'userA';
        await (ParseObject(testClassName)
              ..objectId = 'secretOfA'
              ..set('name', 'A only'))
            .saveToLocalCache();

        // Switching account must not expose it.
        ParseObjectOffline.cacheNamespace = 'userB';
        expect(
          await ParseObjectOffline.loadFromLocalCache(
            testClassName,
            'secretOfA',
          ),
          isNull,
        );
        expect(
          await ParseObjectOffline.loadAllFromLocalCache(testClassName),
          isEmpty,
        );

        // Switching back restores it.
        ParseObjectOffline.cacheNamespace = 'userA';
        final back = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'secretOfA',
        );
        expect(back, isNotNull);
        expect(back!.get<String>('name'), equals('A only'));

        // Clearing one namespace leaves the other alone.
        ParseObjectOffline.cacheNamespace = 'userB';
        await (ParseObject(testClassName)..objectId = 'ofB').saveToLocalCache();
        await ParseObjectOffline.clearLocalCacheForNamespace([testClassName]);
        ParseObjectOffline.cacheNamespace = 'userA';
        expect(
          await ParseObjectOffline.loadAllFromLocalCache(testClassName),
          hasLength(1),
        );
        await ParseObjectOffline.clearLocalCacheForClass(testClassName);
      });

      test('null namespace keeps the historic key layout', () async {
        ParseObjectOffline.cacheNamespace = null;
        await (ParseObject(
          testClassName,
        )..objectId = 'plain').saveToLocalCache();
        final store = ParseCoreData().getStore();
        expect(
          await store.getString('offline_cache_$testClassName:v2'),
          isNotNull,
        );
      });

      test(
        'namespace and class name cannot be confused for one another',
        () async {
          // Joining with '_' was ambiguous: 'a_b' + 'c' and 'a' + 'b_c' both
          // produced offline_cache_a_b_c. Parse class names really do contain
          // underscores (_User, _Installation), so this collided in practice.
          ParseObjectOffline.cacheNamespace = 'a_b';
          await (ParseObject('c')..objectId = 'fromAB').saveToLocalCache();

          ParseObjectOffline.cacheNamespace = 'a';
          expect(
            await ParseObjectOffline.loadFromLocalCache('b_c', 'fromAB'),
            isNull,
            reason: 'namespace a / class b_c must not see a_b / class c',
          );
          expect(
            await ParseObjectOffline.loadAllFromLocalCache('b_c'),
            isEmpty,
          );

          await ParseObjectOffline.clearLocalCacheForClass('b_c');
          ParseObjectOffline.cacheNamespace = 'a_b';
          await ParseObjectOffline.clearLocalCacheForClass('c');
        },
      );

      test('a namespace with odd characters still round-trips', () async {
        ParseObjectOffline.cacheNamespace = 'user:with/odd%chars';
        await (ParseObject(testClassName)..objectId = 'odd').saveToLocalCache();
        final back = await ParseObjectOffline.loadFromLocalCache(
          testClassName,
          'odd',
        );
        expect(back, isNotNull);
        await ParseObjectOffline.clearLocalCacheForClass(testClassName);
      });
    });
  });
}
