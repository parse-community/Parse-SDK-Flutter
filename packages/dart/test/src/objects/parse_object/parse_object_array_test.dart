@Skip('get(keyArray) will return _Map<String, dynamic>'
    'which is the wrong type. it should be any subtype of Iterable'
    'see the issue #834')
// TODO: remove the skip when the issue fixed

import 'package:collection/collection.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';
import 'test_utils.dart';

void main() {
  group(
    'Array',
    () {
      late MockParseClient client;

      late ParseObject dietPlansObject;

      const keyArray = 'array';

      setUp(() async {
        client = MockParseClient();

        await initializeParse();

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
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 1],
          ),
          isTrue,
        );
      });

      test(
          'setAdd() operation should not be mergeable with any other'
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
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 1],
          ),
          isTrue,
        );
      });

      test(
          'setAddAll() operation should not be mergeable with any other'
          'operation other than setAdd()', () {
        testUnmergeableOperationShouldThrow(
          parseObject: dietPlansObject,
          testingOn: dietPlansObject.setAddAll,
          excludeMergeableOperations: [dietPlansObject.setAdd],
        );
      });

      test(
          'adding values using setAddUnique() and then calling get(keyArray) '
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
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 3, 4],
          ),
          isTrue,
        );
      });

      test(
          'setAddUnique() operation should not be mergeable with any other'
          'operation other than setAddAllUnique()', () {
        testUnmergeableOperationShouldThrow(
          parseObject: dietPlansObject,
          testingOn: dietPlansObject.setAddUnique,
          excludeMergeableOperations: [dietPlansObject.setAddAllUnique],
        );
      });

      test(
          'adding values using setAddAllUnique() and then calling get(keyArray) '
          'should return Instance of Iterable that contains all the added values'
          ' with out any duplication in the values', () {
        // act
        dietPlansObject.setAddAllUnique(keyArray, [1, 2, 1, 3, 1, 4, 1]);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 3, 4],
          ),
          isTrue,
        );
      });

      test(
          'setAddAllUnique() operation should not be mergeable with any other'
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

        dietPlansObject = ParseObject('Diet_Plans')
          ..fromJson(
            resultFromServer,
          );

        // act
        dietPlansObject.setRemove(keyArray, 4);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 3],
          ),
          isTrue,
        );
      });

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

        dietPlansObject = ParseObject('Diet_Plans')
          ..fromJson(
            resultFromServer,
          );

        // act
        dietPlansObject.setRemoveAll(keyArray, [3, 4]);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2],
          ),
          isTrue,
        );
      });

      test(
          'the array should not been affected by removing non existent '
          'values using setRemove()', () {
        // arrange
        const resultFromServer = {
          "objectId": "O6BHlwV48Z",
          "createdAt": "2023-02-26T13:23:03.073Z",
          "updatedAt": "2023-03-01T03:38:16.390Z",
          keyArray: [1, 2, 3, 4],
        };

        dietPlansObject = ParseObject('Diet_Plans')
          ..fromJson(
            resultFromServer,
          );

        // act
        dietPlansObject.setRemove(keyArray, 15);
        dietPlansObject.setRemove(keyArray, 16);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 3, 4],
          ),
          isTrue,
        );
      });

      test(
          'the array should not been affected by removing non existent '
          'values using setRemoveAll()', () {
        // arrange
        const resultFromServer = {
          "objectId": "O6BHlwV48Z",
          "createdAt": "2023-02-26T13:23:03.073Z",
          "updatedAt": "2023-03-01T03:38:16.390Z",
          keyArray: [1, 2, 3, 4],
        };

        dietPlansObject = ParseObject('Diet_Plans')
          ..fromJson(
            resultFromServer,
          );

        // act
        dietPlansObject.setRemoveAll(keyArray, [15, 16]);

        // assert
        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2, 3, 4],
          ),
          isTrue,
        );
      });

      test(
          'adding to an array and then removing from it should result in error '
          'the user can not add and remove in the same time', () {
        // act
        dietPlansObject.setAdd(keyArray, 1);
        dietPlansObject.setAdd(keyArray, 2);

        // assert
        expect(
          () => dietPlansObject.setRemove(keyArray, 2),
          throwsA(isA<String>()),
        );

        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2],
          ),
          isTrue,
        );
      });

      test(
          'removing from an array and then adding to it should result in error '
          'the user can not remove and add in the same time', () {
        // arrange
        const resultFromServer = {
          "objectId": "O6BHlwV48Z",
          "createdAt": "2023-02-26T13:23:03.073Z",
          "updatedAt": "2023-03-01T03:38:16.390Z",
          keyArray: [1, 2, 3, 4],
        };

        dietPlansObject = ParseObject('Diet_Plans')
          ..fromJson(
            resultFromServer,
          );

        // act
        dietPlansObject.setRemove(keyArray, 4);
        dietPlansObject.setRemove(keyArray, 3);

        // assert
        expect(
          () => dietPlansObject.setAdd(keyArray, 5),
          throwsA(isA<String>()),
        );

        final array = dietPlansObject.get(keyArray);

        expect(array, isA<Iterable>());

        expect(
          DeepCollectionEquality.unordered().equals(
            array,
            [1, 2],
          ),
          isTrue,
        );
      });

      test(
          'setRemove() operation should not be mergeable with any other'
          'operation other than setRemoveAll()', () {
        testUnmergeableOperationShouldThrow(
          parseObject: dietPlansObject,
          testingOn: dietPlansObject.setRemove,
          excludeMergeableOperations: [dietPlansObject.setRemoveAll],
        );
      });

      test(
          'setRemoveAll() operation should not be mergeable with any other'
          'operation other than setRemove()', () {
        testUnmergeableOperationShouldThrow(
          parseObject: dietPlansObject,
          testingOn: dietPlansObject.setRemoveAll,
          excludeMergeableOperations: [dietPlansObject.setRemove],
        );
      });
    },
  );
}
