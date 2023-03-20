import 'package:collection/collection.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../test_utils.dart';

void main() {
  group('Relation add/edit/remove', () {
    late ParseObject dietPlansObject;

    late ParseUser user1;
    late ParseUser user2;

    setUp(() async {
      await initializeParse();

      user1 = ParseUser.forQuery()..objectId = 'user1';
      user2 = ParseUser.forQuery()..objectId = 'user2';

      const resultFromServer = {
        "objectId": "O6BHlwV48Z",
        "Name": "new name",
        "Description": "Low fat diet.",
        "Fat": 65,
        "createdAt": "2023-02-26T13:23:03.073Z",
        "updatedAt": "2023-03-01T03:38:16.390Z",
        "usersRelation": {"__type": "Relation", "className": "_User"}
      };

      dietPlansObject = ParseObject('Diet_Plans')..fromJson(resultFromServer);
    });

    test(
      'getRelation(): the targetClass should be _User',
      () {
        // act
        final usersRelation = dietPlansObject.getRelation('usersRelation');

        // assert
        expect(
          usersRelation.getTargetClass,
          equals(keyClassUser),
          reason: 'the target class should be _User',
        );
      },
    );

    test('addRelation(): the relation should hold two objects ', () {
      // act
      dietPlansObject.addRelation('usersRelation', [user1, user2]);

      // assert
      final toJsonAfterAddRelation = dietPlansObject.toJson(forApiRQ: true);

      const expectedToJson = {
        "usersRelation": {
          "__op": "AddRelation",
          "objects": [
            {"__type": "Pointer", "className": "_User", "objectId": "user1"},
            {
              "__type": "Pointer",
              "className": "_User",
              "objectId": "user2",
            }
          ]
        }
      };

      expect(
        DeepCollectionEquality().equals(
          expectedToJson,
          toJsonAfterAddRelation,
        ),
        isTrue,
      );
    });

    test(
      'calling getRelation after adding Relation should return ParseRelation',
      () {
        // arrange
        dietPlansObject.addRelation('usersRelation', [user1, user2]);

        // assert
        expect(
          () => dietPlansObject.getRelation('usersRelation'),
          returnsNormally,
        );
      },
      skip: 'getRelation() will throw Unhandled exception:'
          'type _Map<String, dynamic> is not a subtype '
          'of type ParseRelation<ParseObject>? in type cast. see the issue #696',
    );

    test(
      'calling getRelation after removing Relation should return ParseRelation',
      () {
        // arrange
        dietPlansObject.removeRelation('usersRelation', [user1, user2]);

        // assert
        expect(
          () => dietPlansObject.getRelation('usersRelation'),
          returnsNormally,
        );
      },
      skip: 'getRelation() will throw Unhandled exception:'
          'type _Map<String, dynamic> is not a subtype '
          'of type ParseRelation<ParseObject>? in type cast. see the issue #696',
    );

    test('addRelation() operation should not be mergeable with any other', () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.addRelation,
      );
    });

    test('removeRelation() operation should not be mergeable with any other',
        () {
      testUnmergeableOperationShouldThrow(
        parseObject: dietPlansObject,
        testingOn: dietPlansObject.removeRelation,
      );
    });
  });
}
