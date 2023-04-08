import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:mockito/mockito.dart';
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

    test(
        'When calling clearUnsavedChanges() the number should be reverted back'
        ' to its original state before any modifications were made', () {
      // arrange
      dietPlansObject.fromJson({
        'myNumber': 5,
        "objectId": "someId"
      }); // assume this coming from the server

      dietPlansObject.setIncrement('myNumber', 5);

      // act
      dietPlansObject.clearUnsavedChanges();

      // assert
      final number = dietPlansObject.get<num>('myNumber');

      expect(number, equals(5));
    });

    test(
        'The number internal state should be identical '
        'before and after storing it in data store', () async {
      // arrange
      dietPlansObject.fromJson({
        'myNumber': 5,
        "objectId": "someId"
      }); // assume this coming from the server

      dietPlansObject.setIncrement('myNumber', 5);

      final numberBeforePin = dietPlansObject.get<num>('myNumber');
      final toJsonBeforePin = dietPlansObject.toJson(forApiRQ: true);

      // act
      await dietPlansObject.pin();

      final objectFromPin = await dietPlansObject.fromPin('someId');

      // assert
      final numberAfterPin = objectFromPin.get<num>('myNumber');
      final toJsonAfterPin = objectFromPin.toJson(forApiRQ: true);

      expect(numberBeforePin, equals(numberAfterPin));

      expect(
        DeepCollectionEquality().equals(toJsonBeforePin, toJsonAfterPin),
        isTrue,
      );
    });

    test(
      'If an Increment/Decrement operation is performed during the save() '
      'function, the result of the operation should be present in the internal '
      'state of the ParseNumber as a value that has not been saved. The data '
      'that has been saved should be moved to the saved state',
      () async {
        // arrange
        const resultFromServer = {
          keyVarObjectId: "DLde4rYA8C",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z"
        };

        when(client.post(
          any,
          options: anyNamed("options"),
          data: anyNamed('data'),
        )).thenAnswer(
          (_) async {
            await Future.delayed(Duration(milliseconds: 100));
            return ParseNetworkResponse(
              statusCode: 200,
              data: jsonEncode(resultFromServer),
            );
          },
        );

        dietPlansObject.setIncrement('myNumber', 1);

        final numberBeforeSave = dietPlansObject.get<num>('myNumber');
        final valueForApiReqBeforeSave = dietPlansObject.toJson(forApiRQ: true);

        // act
        dietPlansObject.save();

        // async gap, this could be anything in the app like a click of a button
        await Future.delayed(Duration.zero);

        // Then suddenly the user increment the value
        dietPlansObject.setIncrement('myNumber', 3);

        // Await the save function to be done
        await Future.delayed(Duration(milliseconds: 150));

        // assert
        expect(numberBeforeSave, equals(1));

        final numberAfterSave = dietPlansObject.get<num>('myNumber');
        expect(numberAfterSave, equals(4));

        const expectedValueForApiReqBeforeSave = {
          "myNumber": {"__op": "Increment", "amount": 1}
        };
        expect(
          DeepCollectionEquality().equals(
            valueForApiReqBeforeSave,
            expectedValueForApiReqBeforeSave,
          ),
          isTrue,
        );

        final valueForApiReqAfterSave = dietPlansObject.toJson(forApiRQ: true);
        const expectedValueForApiReqAfterSave = {
          "myNumber": {"__op": "Increment", "amount": 3}
        };
        expect(
          DeepCollectionEquality().equals(
            valueForApiReqAfterSave,
            expectedValueForApiReqAfterSave,
          ),
          isTrue,
        );
      },
    );

    test(
        'The number value and the number value for api request should be identical '
        'before and after the save() failed to save the object', () {
      // arrange

      when(client.post(
        any,
        options: anyNamed("options"),
        data: anyNamed("data"),
      )).thenThrow(Exception('error'));

      dietPlansObject.setIncrement('myNumber', 1);

      final valueForApiReqBeforeErrorSave =
          dietPlansObject.toJson(forApiRQ: true);

      // act
      dietPlansObject.save();

      // assert
      final numberValue = dietPlansObject.get<num>('myNumber');

      expect(numberValue, equals(1));

      final valueForApiReqAfterErrorSave =
          dietPlansObject.toJson(forApiRQ: true);
      expect(
        DeepCollectionEquality().equals(
          valueForApiReqAfterErrorSave,
          valueForApiReqBeforeErrorSave,
        ),
        isTrue,
      );
    });
  });
}
