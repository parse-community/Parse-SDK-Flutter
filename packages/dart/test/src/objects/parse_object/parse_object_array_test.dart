import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('Array', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    const keyArray = 'array';

    setUp(() {
      client = MockParseClient();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
      'adding values using setAdd() and then calling get(keyArray) '
      'should return Instance of Iterable that contains all the added values ',
      () {
        // act
        dietPlansObject.setAdd(keyArray, 1);
        dietPlansObject.setAdd(keyArray, 2);
        dietPlansObject.setAdd(keyArray, 1);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(array, [1, 2, 1]),
          isTrue,
        );
      },
    );

    test('setAdd() operation should not be mergeable with any other'
        'operation other than setAddAll()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setAdd,
        excludeMergeableOperations: [dietPlansObject.setAddAll],
      );
    });

    test(
      'adding values using setAddAll() and then calling get(keyArray) '
      'should return Instance of Iterable that contains all the added values',
      () {
        // act
        dietPlansObject.setAddAll(keyArray, [1, 2, 1]);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(array, [1, 2, 1]),
          isTrue,
        );
      },
    );

    test('setAddAll() operation should not be mergeable with any other'
        'operation other than setAdd()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setAddAll,
        excludeMergeableOperations: [dietPlansObject.setAdd],
      );
    });

    test('adding values using setAddUnique() and then calling get(keyArray) '
        'should return Instance of Iterable that contains all the added values'
        ' with out any duplication in the values', () {
      // act
      dietPlansObject.setAddUnique(keyArray, 1);
      dietPlansObject.setAddUnique(keyArray, 2);
      dietPlansObject.setAddUnique(keyArray, 1);
      dietPlansObject.setAddUnique(keyArray, 3);
      dietPlansObject.setAddUnique(keyArray, 1);
      dietPlansObject.setAddUnique(keyArray, 4);

      // assert
      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(
        DeepCollectionEquality.unordered().equals(array, [1, 2, 3, 4]),
        isTrue,
      );
    });

    test('setAddUnique() operation should not be mergeable with any other'
        'operation other than setAddAllUnique()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setAddUnique,
        excludeMergeableOperations: [dietPlansObject.setAddAllUnique],
      );
    });

    test('adding values using setAddAllUnique() and then calling get(keyArray) '
        'should return Instance of Iterable that contains all the added values'
        ' with out any duplication in the values', () {
      // act
      dietPlansObject.setAddAllUnique(keyArray, [1, 2, 1, 3, 1, 4, 1]);

      // assert
      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(
        DeepCollectionEquality.unordered().equals(array, [1, 2, 3, 4]),
        isTrue,
      );
    });

    test('setAddAllUnique() operation should not be mergeable with any other'
        'operation other than setAddUnique()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setAddAllUnique,
        excludeMergeableOperations: [dietPlansObject.setAddUnique],
      );
    });

    test(
      'removing values using setRemove() and then calling get(keyArray) '
      'should return Instance of Iterable that NOT contains the removed values',
      () {
        // arrange
        const resultFromServer = {
          "objectId": "O6BHlwV48Z",
          "createdAt": "2023-02-26T13:23:03.073Z",
          "updatedAt": "2023-03-01T03:38:16.390Z",
          keyArray: [1, 2, 3, 4],
        };

        dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

        // act
        dietPlansObject.setRemove(keyArray, 4);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(array, [1, 2, 3]),
          isTrue,
        );
      },
    );

    test(
      'removing values using setRemoveAll() and then calling get(keyArray) '
      'should return Instance of Iterable that NOT contains the removed values',
      () {
        // arrange
        const resultFromServer = {
          "objectId": "O6BHlwV48Z",
          "createdAt": "2023-02-26T13:23:03.073Z",
          "updatedAt": "2023-03-01T03:38:16.390Z",
          keyArray: [1, 2, 3, 4],
        };

        dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

        // act
        dietPlansObject.setRemoveAll(keyArray, [3, 4]);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(array, [1, 2]),
          isTrue,
        );
      },
    );

    test('the array should not been affected by removing non existent '
        'values using setRemove()', () {
      // arrange
      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        keyArray: [1, 2, 3, 4],
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

      // act
      dietPlansObject.setRemove(keyArray, 15);
      dietPlansObject.setRemove(keyArray, 16);

      // assert
      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(
        DeepCollectionEquality.unordered().equals(array, [1, 2, 3, 4]),
        isTrue,
      );
    });

    test('the array should not been affected by removing non existent '
        'values using setRemoveAll()', () {
      // arrange
      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        keyArray: [1, 2, 3, 4],
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

      // act
      dietPlansObject.setRemoveAll(keyArray, [15, 16]);

      // assert
      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(
        DeepCollectionEquality.unordered().equals(array, [1, 2, 3, 4]),
        isTrue,
      );
    });

    test('adding to an array and then removing from it should result in error '
        'the user can not add and remove in the same time', () {
      // act
      dietPlansObject.setAdd(keyArray, 1);
      dietPlansObject.setAdd(keyArray, 2);

      // assert
      expect(
        () => dietPlansObject.setRemove(keyArray, 2),
        throwsA(isA<ParseOperationException>()),
      );

      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(DeepCollectionEquality.unordered().equals(array, [1, 2]), isTrue);
    });

    test('removing from an array and then adding to it should result in error '
        'the user can not remove and add in the same time', () {
      // arrange
      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        keyArray: [1, 2, 3, 4],
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);

      // act
      dietPlansObject.setRemove(keyArray, 4);
      dietPlansObject.setRemove(keyArray, 3);

      // assert
      expect(
        () => dietPlansObject.setAdd(keyArray, 5),
        throwsA(isA<ParseOperationException>()),
      );

      final array = dietPlansObject.get(keyArray);

      expect(array, isA<Iterable>());

      expect(DeepCollectionEquality.unordered().equals(array, [1, 2]), isTrue);
    });

    test('setRemove() operation should not be mergeable with any other'
        'operation other than setRemoveAll()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setRemove,
        excludeMergeableOperations: [dietPlansObject.setRemoveAll],
      );
    });

    test('setRemoveAll() operation should not be mergeable with any other'
        'operation other than setRemove()', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.setRemoveAll,
        excludeMergeableOperations: [dietPlansObject.setRemove],
      );
    });

    test(
      'Array should be in setMode when using "set" to add an array to the parse object '
      'and any operation on the array should not create any conflict with the previous operation',
      () {
        // arrange
        void operations() {
          // act
          dietPlansObject.set(keyArray, [1, 2]);
          dietPlansObject.setAdd(keyArray, 3);
          dietPlansObject.setAddUnique(keyArray, 3);
          dietPlansObject.setAddUnique(keyArray, 4);
          dietPlansObject.setRemove(keyArray, 1);
        }

        // assert
        expect(() => operations(), returnsNormally);
      },
    );

    test('The array internal state should be identical before and after '
        'storing it in data store', () async {
      // arrange
      dietPlansObject.objectId = "someId";

      dietPlansObject.set(keyArray, [1, 2]);
      dietPlansObject.setAdd(keyArray, 3);
      dietPlansObject.setAddUnique(keyArray, 3);
      dietPlansObject.setAddUnique(keyArray, 4);
      dietPlansObject.setRemove(keyArray, 1);

      final listBeforePin = dietPlansObject.get<List>(keyArray);
      final toJsonBeforePin = dietPlansObject.toJson(forApiRQ: true);

      // act
      await dietPlansObject.pin();

      final objectFromPin = await dietPlansObject.fromPin('someId');

      // assert
      final listAfterPin = objectFromPin.get<List>(keyArray);
      final toJsonAfterPin = objectFromPin.toJson(forApiRQ: true);

      expect(
        DeepCollectionEquality().equals(listBeforePin, listAfterPin),
        isTrue,
      );

      expect(
        DeepCollectionEquality().equals(toJsonBeforePin, toJsonAfterPin),
        isTrue,
      );
    });

    test('The saved modified array internal state should be identical '
        'before and after storing it in data store', () async {
      // arrange
      dietPlansObject.fromJson({
        keyArray: [1, 2],
        "objectId": "someId",
      }); // assume this coming from the server

      dietPlansObject.setAddUnique(keyArray, 3);

      final listBeforePin = dietPlansObject.get<List>(keyArray);
      final toJsonBeforePin = dietPlansObject.toJson(forApiRQ: true);

      // act
      await dietPlansObject.pin();

      final objectFromPin = await dietPlansObject.fromPin('someId');

      // assert
      final listAfterPin = objectFromPin.get<List>(keyArray);
      final toJsonAfterPin = objectFromPin.toJson(forApiRQ: true);

      expect(
        DeepCollectionEquality().equals(listBeforePin, listAfterPin),
        isTrue,
      );

      expect(
        DeepCollectionEquality().equals(toJsonBeforePin, toJsonAfterPin),
        isTrue,
      );
    });

    test(
      'The saved array should not be in setMode. i.e. any conflicting operation'
      ' should not be allowed and throw an exception',
      () {
        // arrange
        dietPlansObject.fromJson({
          keyArray: [1, 2],
          "objectId": "someId",
        }); // assume this coming from the server

        // act
        dietPlansObject.setAdd(keyArray, 3);

        // assert
        op() => dietPlansObject.setRemove(keyArray, 3);

        expect(() => op(), throwsA(isA<ParseOperationException>()));
      },
    );

    test(
      'After the save() function runs successfully for an API request, '
      'the ParseArray internal value for API request should be empty',
      () async {
        // arrange
        const resultFromServer = {
          keyVarObjectId: "DLde4rYA8C",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z",
        };

        when(
          client.post(
            any,
            options: anyNamed("options"),
            data: anyNamed('data'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 500));
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          );
        });

        dietPlansObject.setAddAll(keyArray, [1, 2, 3]);

        final valueForApiReqBeforeSave = dietPlansObject.toJson(forApiRQ: true);

        final listValueBeforeSave = dietPlansObject.get(keyArray);

        // act
        await dietPlansObject.save();

        // assert
        final valueForApiReqAfterSave = dietPlansObject.toJson(forApiRQ: true);
        final listValueAfterSave = dietPlansObject.get(keyArray);

        final expectedValueForApiReqBeforeSave = {
          keyArray: {
            "__op": "Add",
            "objects": [1, 2, 3],
          },
        };

        expect(
          DeepCollectionEquality().equals(
            valueForApiReqBeforeSave,
            expectedValueForApiReqBeforeSave,
          ),
          isTrue,
        );

        expect(
          DeepCollectionEquality().equals(
            listValueBeforeSave,
            listValueAfterSave,
          ),
          isTrue,
        );

        expect(valueForApiReqAfterSave.isEmpty, isTrue);
      },
    );

    test(
      'If an Add operation is performed during the save() function, the result'
      ' of the operation should be present in the internal state of the '
      'ParseArray as a value that has not been saved. The data that has '
      'been saved should be moved to the saved state',
      () async {
        // arrange
        const resultFromServer = {
          keyVarObjectId: "DLde4rYA8C",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z",
        };

        when(
          client.post(
            any,
            options: anyNamed("options"),
            data: anyNamed('data'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          );
        });

        dietPlansObject.setAdd(keyArray, 1);
        dietPlansObject.setAdd(keyArray, 2);

        final listBeforeSave = dietPlansObject.get(keyArray);
        final valueForApiReqBeforeSave = dietPlansObject.toJson(forApiRQ: true);

        // act
        dietPlansObject.save();

        // async gap, this could be anything in the app like a click of a button
        await Future.delayed(Duration.zero);

        // Then suddenly the user added a value to the list
        dietPlansObject.setAdd(keyArray, 3);
        dietPlansObject.setAdd(keyArray, 4);

        // Await the save function to be done
        await Future.delayed(Duration(milliseconds: 150));

        // assert
        expect(DeepCollectionEquality().equals(listBeforeSave, [1, 2]), isTrue);

        final listAfterSave = dietPlansObject.get(keyArray);
        expect(
          DeepCollectionEquality().equals(listAfterSave, [1, 2, 3, 4]),
          isTrue,
        );

        const expectedValueForApiReqBeforeSave = {
          keyArray: {
            "__op": "Add",
            "objects": [1, 2],
          },
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
          keyArray: {
            "__op": "Add",
            "objects": [3, 4],
          },
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
      'If an Remove operation is performed during the save() function, the result'
      ' of the operation should be present in the internal state of the '
      'ParseArray as a value that has not been saved. The data that has '
      'been saved should be moved to the saved state',
      () async {
        // arrange
        const resultFromServer = {
          keyVarObjectId: "DLde4rYA8C",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z",
        };

        when(
          client.post(
            any,
            options: anyNamed("options"),
            data: anyNamed('data'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          );
        });

        dietPlansObject.fromJson({
          keyArray: [1, 2, 3, 4],
        });

        final listBeforeSave = dietPlansObject.get(keyArray);
        final valueForApiReqBeforeSave = dietPlansObject.toJson(forApiRQ: true);

        // act
        dietPlansObject.save();

        // async gap, this could be anything in the app like a click of a button
        await Future.delayed(Duration.zero);

        // Then suddenly the user remove a value from the list
        dietPlansObject.setRemoveAll(keyArray, [3, 4]);

        // Await the save function to be done
        await Future.delayed(Duration(milliseconds: 150));

        // assert
        expect(listBeforeSave, orderedEquals([1, 2, 3, 4]));

        final listAfterSave = dietPlansObject.get(keyArray);
        expect(listAfterSave, orderedEquals([1, 2]));

        expect(valueForApiReqBeforeSave.isEmpty, isTrue);

        final valueForApiReqAfterSave = dietPlansObject.toJson(forApiRQ: true);
        const expectedValueForApiReqAfterSave = {
          keyArray: {
            "__op": "Remove",
            "objects": [3, 4],
          },
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

    test('When calling clearUnsavedChanges() the array should be reverted back'
        ' to its original state before any modifications were made', () {
      // arrange
      dietPlansObject.fromJson({
        keyArray: [1, 2],
        "objectId": "someId",
      }); // assume this coming from the server

      dietPlansObject.setAdd(keyArray, 3);

      // act
      dietPlansObject.clearUnsavedChanges();

      // assert
      final listValue = dietPlansObject.get(keyArray);

      expect(listValue, orderedEquals([1, 2]));
    });

    test('Arrays should not be cleared when calling clearUnsavedChanges() '
        'after receiving response from fetch/query (issue #1038)', () async {
      // arrange - First, save an object with an array to create a _ParseArray
      dietPlansObject.setAdd(keyArray, 1);
      dietPlansObject.setAdd(keyArray, 2);

      when(
        client.post(any, options: anyNamed("options"), data: anyNamed('data')),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode({
            "objectId": "Mn1iJTkWTE",
            "createdAt": "2023-03-05T00:25:31.466Z",
          }),
        ),
      );

      await dietPlansObject
          .save(); // This creates the _ParseArray and calls onSaving/onSaved

      // Now set up a mock fetch response that returns updated array data
      final getPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      const resultsFromServer = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            keyArray: [
              1,
              2,
              3,
            ], // Server now has an updated array with one more item
            "createdAt": "2023-03-05T00:25:31.466Z",
            "updatedAt": "2023-03-05T00:25:31.466Z",
          },
        ],
      };

      when(
        client.get(
          getPath,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        ),
      ).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultsFromServer),
        ),
      );

      // act - Fetch the object from server to get the updated array
      // This simulates the scenario from issue #1038 where after fetching/querying
      // an object (e.g., via getUpdatedUser() or fetch()), calling clearUnsavedChanges()
      // would incorrectly clear the arrays.
      ParseObject fetchedObject = await dietPlansObject.fetch();

      // Verify array is populated correctly from the fetch response
      expect(fetchedObject.get(keyArray), orderedEquals([1, 2, 3]));

      // Now clear unsaved changes - this should NOT clear the arrays
      // Before the fix (PR #1039), this would set arrays to empty
      fetchedObject.clearUnsavedChanges();

      // assert - Arrays should still have their values from the server
      final listValue = fetchedObject.get(keyArray);
      expect(listValue, orderedEquals([1, 2, 3]));
    });

    test('The list value and the value for api request should be identical '
        'before and after the save() failed to save the object', () async {
      // arrange

      when(
        client.post(any, options: anyNamed("options"), data: anyNamed("data")),
      ).thenThrow(Exception('error'));

      dietPlansObject.setAddAll(keyArray, [1, 2]);

      final valueForApiReqBeforeErrorSave = dietPlansObject.toJson(
        forApiRQ: true,
      );

      // act
      await dietPlansObject.save();

      // assert
      final listValue = dietPlansObject.get(keyArray);

      expect(listValue, orderedEquals([1, 2]));

      final valueForApiReqAfterErrorSave = dietPlansObject.toJson(
        forApiRQ: true,
      );

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
