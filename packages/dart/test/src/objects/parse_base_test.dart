import 'package:collection/collection.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../parse_query_test.mocks.dart';
import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('Parse_Base', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() {
      client = MockParseClient();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    group('isDirty', () {
      test('should return true when calling isDirty on modified object', () {
        // array
        dietPlansObject.setAddUnique('arrayKey', 1);
        final isDirtyArray = dietPlansObject.isDirty(key: 'arrayKey');
        expect(isDirtyArray, isTrue);
        dietPlansObject.unset('arrayKey', offlineOnly: true);

        // number
        dietPlansObject.setIncrement('myNumberKey', 2);
        final isDirtyNumber = dietPlansObject.isDirty(key: 'myNumberKey');
        expect(isDirtyNumber, isTrue);
        dietPlansObject.unset('myNumberKey', offlineOnly: true);

        // relation
        dietPlansObject.removeRelation('relationKey', [ParseObject('class')]);
        final isDirtyRelation = dietPlansObject.isDirty(key: 'relationKey');
        expect(isDirtyRelation, isTrue);
        dietPlansObject.unset('relationKey', offlineOnly: true);

        // string
        dietPlansObject.set('stringKey', 'some String');
        final isDirtyString = dietPlansObject.isDirty(key: 'stringKey');
        expect(isDirtyString, isTrue);
        dietPlansObject.unset('stringKey', offlineOnly: true);

        // pointer
        dietPlansObject.set(
          'pointerKey',
          ParseObject('className')..set('someKey', 1),
        );
        final isDirtyPointer = dietPlansObject.isDirty(key: 'pointerKey');
        expect(isDirtyPointer, isTrue);
        dietPlansObject.unset('pointerKey', offlineOnly: true);
      });

      test('should return true when modifying a child(nested) ParseObject', () {
        // arrange
        dietPlansObject.fromJson({
          keyVarObjectId: "dDSAGER1",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z",
          keyVarUpdatedAt: "2023-02-26T00:20:37.187Z",
          "somePointer": {
            "__type": "Object",
            "className": "Plan",
            "name": "plan1",
          },
        });

        // act

        // modifying nested child
        dietPlansObject.get('somePointer').set('name', 'plan222');

        final isDirtyDeepChildrenCheck = dietPlansObject.isDirty();

        // assert
        expect(isDirtyDeepChildrenCheck, isTrue);
      });
    });

    test(
      'should return true for containsValue() if the object contains the value',
      () {
        // arrange
        dietPlansObject.set('someKey', 1);

        // act
        final containsValue = dietPlansObject.containsValue(1);

        // assert
        expect(containsValue, isTrue);
      },
    );

    test(
      'should return true for containsKey() if the object contains the passed key',
      () {
        // arrange
        dietPlansObject.set('someKey', 1);

        // act
        final containsKey = dietPlansObject.containsKey('someKey');

        // assert
        expect(containsKey, isTrue);
      },
    );

    test('test the [] operator', () {
      // arrange
      dietPlansObject['someKey'] = 1;

      // act
      final value = dietPlansObject['someKey'];

      // assert
      expect(value, equals(1));
    });

    test('setACL() should set the ACL for the parse object', () {
      // arrange
      final acl = ParseACL();

      // act
      dietPlansObject.setACL(acl);

      // assert
      expect(dietPlansObject.getACL(), equals(acl));
    });

    test(
      'fromJsonForManualObject() should put all the values in unsaved state',
      () {
        // arrange
        final createdAt = DateTime.now();
        final updatedAt = DateTime.now();
        final manualJsonObject = <String, dynamic>{
          keyVarCreatedAt: createdAt,
          keyVarUpdatedAt: updatedAt,
          "array": [1, 2, 3],
          'number': 2,
        };

        // act
        dietPlansObject.fromJsonForManualObject(manualJsonObject);

        // assert
        expect(dietPlansObject.isDirty(key: 'array'), isTrue);
        expect(dietPlansObject.isDirty(key: 'number'), isTrue);

        expect(dietPlansObject.createdAt, equals(createdAt));
        expect(dietPlansObject.updatedAt, equals(updatedAt));

        final valueForAPiRequest = dietPlansObject.toJson(forApiRQ: true);
        final expectedValueForAPiRequest = {
          "array": [1, 2, 3],
          "number": 2,
        };

        expect(
          DeepCollectionEquality().equals(
            valueForAPiRequest,
            expectedValueForAPiRequest,
          ),
          isTrue,
        );
      },
    );

    group('date parsing', () {
      test('createdAt and updatedAt should handle Map date format', () {
        // Create a parse object and simulate server response with date as Map
        final parseObject = ParseObject('TestClass');

        // This is what the server sometimes returns - date as Map
        parseObject.fromJson({
          'objectId': 'testObjectId',
          'createdAt': {'__type': 'Date', 'iso': '2023-01-01T00:00:00.000Z'},
          'updatedAt': {'__type': 'Date', 'iso': '2023-01-02T00:00:00.000Z'},
        });

        // These should not throw and return DateTime objects
        expect(parseObject.createdAt, isA<DateTime>());
        expect(parseObject.updatedAt, isA<DateTime>());

        expect(parseObject.createdAt?.year, equals(2023));
        expect(parseObject.createdAt?.month, equals(1));
        expect(parseObject.createdAt?.day, equals(1));

        expect(parseObject.updatedAt?.year, equals(2023));
        expect(parseObject.updatedAt?.month, equals(1));
        expect(parseObject.updatedAt?.day, equals(2));
      });

      test('createdAt and updatedAt should handle String date format', () {
        final parseObject = ParseObject('TestClass');

        parseObject.fromJson({
          'objectId': 'testObjectId',
          'createdAt': '2023-01-01T00:00:00.000Z',
          'updatedAt': '2023-01-02T00:00:00.000Z',
        });

        expect(parseObject.createdAt, isA<DateTime>());
        expect(parseObject.updatedAt, isA<DateTime>());

        expect(parseObject.createdAt?.year, equals(2023));
        expect(parseObject.updatedAt?.year, equals(2023));
      });

      test('createdAt and updatedAt should handle DateTime objects', () {
        final createdAt = DateTime(2023, 1, 1);
        final updatedAt = DateTime(2023, 1, 2);

        final parseObject = ParseObject('TestClass');
        parseObject.fromJson({
          'objectId': 'testObjectId',
          'createdAt': createdAt,
          'updatedAt': updatedAt,
        });

        expect(parseObject.createdAt, equals(createdAt));
        expect(parseObject.updatedAt, equals(updatedAt));
      });

      test('toJson should work when date fields are stored as Maps', () {
        final parseObject = ParseObject('TestClass');

        // Simulate server response with date as Map
        parseObject.fromJson({
          'objectId': 'testObjectId',
          'createdAt': {'__type': 'Date', 'iso': '2023-01-01T00:00:00.000Z'},
          'updatedAt': {'__type': 'Date', 'iso': '2023-01-02T00:00:00.000Z'},
        });

        // toJson should work without throwing
        expect(() => parseObject.toJson(full: true), returnsNormally);
        expect(() => parseObject.toString(), returnsNormally);
      });

      test('createdAt and updatedAt should return null for null values', () {
        final parseObject = ParseObject('TestClass');

        parseObject.fromJson({'objectId': 'testObjectId'});

        expect(parseObject.createdAt, isNull);
        expect(parseObject.updatedAt, isNull);
      });
    });
  });
}
