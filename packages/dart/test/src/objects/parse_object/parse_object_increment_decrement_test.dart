import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  group('Increment/Decrement', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    const keyFat = 'fat';

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
        'Incrementing values using setIncrement() and then calling get(key) '
        'should return Instance of num that hold the result of incrementing '
        'the value by the amount parameter', () {
      // arrange
      dietPlansObject.set(keyFat, 0);

      // act
      dietPlansObject.setIncrement(keyFat, 1);
      dietPlansObject.setIncrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(3.5));
    });

    test(
        'Incrementing not existing values should be handled by assuming'
        'that the default value is 0 and operate on it', () {
      // act
      dietPlansObject.setIncrement(keyFat, 1);
      dietPlansObject.setIncrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(3.5));
    });

    test(
        'Incrementing should work with already present values decoded from API',
        () {
      // arrange
      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        keyFat: 2.5,
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

      // act
      dietPlansObject.setIncrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(5));
    });
    test(
      'setIncrement() should account for pervasively set value',
      () {
        // arrange
        dietPlansObject.set(keyFat, 5);

        // act
        dietPlansObject.setIncrement(keyFat, 2.5);

        // assert
        final fatValue = dietPlansObject.get(keyFat);

        expect(fatValue, isA<num>());

        expect(fatValue, equals(7.5));
      },
    );

    test(
        'setIncrement() operation should not be mergeable with any other'
        'operation other than setDecrement()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setIncrement,
        excludeMergeableOperations: [dietPlansObject.setDecrement],
      );
    });

    test(
      'the amount that should be added to a value for the API should be incremental'
      ' and independent from the estimated value (the increment operation result)',
      () {
        // arrange
        dietPlansObject.fromJson({keyFat: 10});

        // act
        dietPlansObject.setIncrement(keyFat, 2.5);
        dietPlansObject.setIncrement(keyFat, 2.5);

        // assert
        expect(
          dietPlansObject.toJson(forApiRQ: true)[keyFat]['amount'],
          equals(5.0),
        );

        expect(
          dietPlansObject.get(keyFat),
          equals(15.0),
        );
      },
    );

    test(
        'Decrementing values using setDecrement() and then calling get(key) '
        'should return Instance of num that hold the result of decrementing '
        'the value by the amount parameter', () {
      // arrange
      dietPlansObject.set(keyFat, 0);

      // act
      dietPlansObject.setDecrement(keyFat, 1);
      dietPlansObject.setDecrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(-3.5));
    });

    test(
        'Decrementing not existing values should be handled by assuming'
        'that the default value is 0 and operate on it', () {
      // act
      dietPlansObject.setDecrement(keyFat, 1);
      dietPlansObject.setDecrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(-3.5));
    });

    test(
        'Decrementing should work with already present values decoded from API',
        () {
      // arrange
      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        keyFat: 3.5,
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

      // act
      dietPlansObject.setDecrement(keyFat, 2.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(1));
    });

    test(
      'setDecrement() should account for pervasively set value',
      () {
        // arrange
        dietPlansObject.set(keyFat, 5);

        // act
        dietPlansObject.setDecrement(keyFat, 3);

        // assert
        final fatValue = dietPlansObject.get(keyFat);

        expect(fatValue, isA<num>());

        expect(fatValue, equals(2));
      },
    );

    test(
      'the amount that should be subtracted from a value for the API should be incremental'
      ' and independent from the estimated value (the decrement operation result)',
      () {
        // arrange
        dietPlansObject.fromJson({keyFat: 10});

        // act
        dietPlansObject.setDecrement(keyFat, 2.5);
        dietPlansObject.setDecrement(keyFat, 2.5);

        // assert
        expect(
          dietPlansObject.toJson(forApiRQ: true)[keyFat]['amount'],
          equals(-5.0),
        );

        expect(
          dietPlansObject.get(keyFat),
          equals(5.0),
        );
      },
    );

    test(
        'mixing and matching Decrements and Increments should not cause '
        'any issue', () {
      // act
      dietPlansObject.setDecrement(keyFat, 2.5);

      dietPlansObject.setIncrement(keyFat, 5);

      dietPlansObject.setDecrement(keyFat, 3);

      dietPlansObject.setIncrement(keyFat, 1.5);

      // assert
      final fatValue = dietPlansObject.get(keyFat);

      expect(fatValue, isA<num>());

      expect(fatValue, equals(1));
    });

    test(
        'setDecrement() operation should not be mergeable with any other'
        'operation other than setIncrement()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setDecrement,
        excludeMergeableOperations: [dietPlansObject.setIncrement],
      );
    });
  });
}
