import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import '../../../test_utils.dart';

void main() {
  group('Relation', () {
    setUpAll(() async {
      await initializeParse();
    });

    late ParseObject dietPlansObject;
    late MockParseClient client;

    late ParseUser user1;
    late ParseUser user2;

    setUp(() {
      client = MockParseClient();

      user1 = ParseUser.forQuery()..objectId = 'user1';
      user2 = ParseUser.forQuery()..objectId = 'user2';

      dietPlansObject = ParseObject('Diet_Plans', client: client);
    });

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

    test('getParent() should rerun the parent of the relation', () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      final parent = relation.getParent();

      // assert
      expect(parent, dietPlansObject);
    });

    test('getKey() should rerun the relation key', () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      final relationKey = relation.getKey();

      // assert
      expect(relationKey, equals('someRelationKey'));
    });

    test(
        'getTargetClass() should rerun null if the relation target class not known yet',
        () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      final targetClass = relation.targetClass;

      // assert
      expect(targetClass, isNull);
    });

    test(
        'getTargetClass() should rerun the target class for the relation if '
        'the user adds an object from the relation', () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      relation.add(ParseObject('someClassNameAsTargetClass'));
      final targetClass = relation.targetClass;

      // assert
      expect(targetClass, equals('someClassNameAsTargetClass'));
    });

    test(
        'getTargetClass() should rerun the target class for the relation if '
        'the user removes an object from the relation', () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      relation.remove(ParseObject('someClassNameAsTargetClass'));
      final targetClass = relation.targetClass;

      // assert
      expect(targetClass, equals('someClassNameAsTargetClass'));
    });

    test(
        'getTargetClass() should return the target class for a relation when'
        ' the object is received from the server', () {
      // arrange
      dietPlansObject.fromJson({
        "someRelationKey": {
          "__type": "Relation",
          "className": "someClassNameAsTargetClass"
        }
      }); // assume this from the server

      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      final targetClass = relation.targetClass;

      // assert
      expect(targetClass, equals('someClassNameAsTargetClass'));
    });

    test('getQuery() should throw exception if the parent objectId is null ',
        () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');

      // assert
      expect(() => relation.getQuery(), throwsA(isA<ParseRelationException>()));
    });

    test(
        'getQuery() should return QueryBuilder utilizing the '
        'redirectClassNameForKey feature if the target class is null ', () {
      // arrange
      dietPlansObject.objectId = "someParentID";
      final relation = dietPlansObject.getRelation('someRelationKey');

      // act
      final query = relation.getQuery();

      // assert
      String expectedQuery =
          r'where={"$relatedTo":{"object":{"__type":"Pointer","className":'
          r'"Diet_Plans","objectId":"someParentID"},"key":"someRelationKey"}}'
          r'&redirectClassNameForKey=someRelationKey';

      expect(query.buildQuery(), equals(expectedQuery));
    });

    test('getQuery() should return QueryBuilder with relatedTo constraint', () {
      // arrange
      dietPlansObject.objectId = "someParentID";
      final relation = dietPlansObject.getRelation('someRelationKey');
      relation.setTargetClass = 'someTargetClass';

      // act
      final query = relation.getQuery();

      // assert
      String expectedQuery =
          r'where={"$relatedTo":{"object":{"__type":"Pointer","className":'
          r'"Diet_Plans","objectId":"someParentID"},"key":"someRelationKey"}}';

      expect(query.buildQuery(), equals(expectedQuery));
    });

    test(
        'should throw an exception when trying to modify the target class if it is not null',
        () {
      // arrange
      final relation = dietPlansObject.getRelation('someRelationKey');
      relation.add(ParseObject('someClassNameAsTargetClass'));

      // assert
      expect(
        () => relation.setTargetClass = "someOtherTargetClass",
        throwsA(isA<ParseRelationException>()),
      );
    });

    test(
        'When calling clearUnsavedChanges() the Relation should be reverted back'
        ' to its original state before any modifications were made', () {
      // arrange

      dietPlansObject.addRelation('someRelationKey', [user1, user1]);

      // act
      dietPlansObject.clearUnsavedChanges();

      // assert
      final valueForApiReqAfterClearUnSaved =
          dietPlansObject.toJson(forApiRQ: true);

      expect(valueForApiReqAfterClearUnSaved.isEmpty, isTrue);

      final relationValueForApiReq =
          dietPlansObject.getRelation('someRelationKey').toJson();
      expect(relationValueForApiReq.isEmpty, isTrue);
    });

    test(
        'The Relation value and the value for api request should be identical '
        'before and after the save() failed to save the object', () async {
      // arrange
      when(client.post(
        any,
        options: anyNamed("options"),
        data: anyNamed("data"),
      )).thenThrow(Exception('error'));

      dietPlansObject.addRelation('someRelationKey', [user1, user1]);

      final valueForApiReqBeforeErrorSave =
          dietPlansObject.toJson(forApiRQ: true);

      final relationInternalStateBeforeErrorSave =
          dietPlansObject.getRelation('someRelationKey').toJson(full: true);

      // act
      await dietPlansObject.save();

      // assert
      final valueForApiReqAfterErrorSave =
          dietPlansObject.toJson(forApiRQ: true);
      expect(
        DeepCollectionEquality().equals(
          valueForApiReqAfterErrorSave,
          valueForApiReqBeforeErrorSave,
        ),
        isTrue,
      );

      final relationInternalStateAfterErrorSave =
          dietPlansObject.getRelation('someRelationKey').toJson(full: true);

      expect(
        DeepCollectionEquality().equals(
          relationInternalStateBeforeErrorSave,
          relationInternalStateAfterErrorSave,
        ),
        isTrue,
      );
    });

    test(
        'After the save() function runs successfully for an API request, '
        'the ParseRelation internal value for API request should be empty',
        () async {
      // arrange

      // batch arrange
      const resultFromServerForBatch = [
        {
          "success": {
            keyVarObjectId: 'YAfSAWwXbL',
            keyVarCreatedAt: "2023-03-10T12:23:45.678Z",
          }
        }
      ];

      final batchData = jsonEncode(
        {
          "requests": [
            {
              'method': 'PUT',
              'path':
                  '$keyEndPointClasses${user1.parseClassName}/${user1.objectId}',
              'body': user1.toJson(forApiRQ: true),
            }
          ]
        },
      );

      final batchPath = Uri.parse('$serverUrl/batch').toString();

      when(client.post(
        batchPath,
        options: anyNamed("options"),
        data: batchData,
      )).thenAnswer(
        (_) async {
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServerForBatch),
          );
        },
      );

      // post arrange
      const resultFromServer = {
        keyVarObjectId: "DLde4rYA8C",
        keyVarCreatedAt: "2023-02-26T00:20:37.187Z"
      };

      final postPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();

      when(client.post(
        postPath,
        options: anyNamed("options"),
        data: anyNamed("data"),
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      dietPlansObject.addRelation('someRelationKey', [user1]);

      // act
      await dietPlansObject.save();

      // assert
      final relationValueForApiReq =
          dietPlansObject.getRelation('someRelationKey').toJson();
      expect(relationValueForApiReq.isEmpty, isTrue);
    });

    test(
        'If a Relation operation is performed during the save() function, the result'
        ' of the operation should be present in the internal state of the '
        'ParseRelation as a value that has not been saved. The data that has '
        'been saved should not be in value for API request', () async {
      // arrange

      // batch arrange
      const resultFromServerForBatch = [
        {
          "success": {
            keyVarUpdatedAt: "2023-03-10T12:23:45.678Z",
          }
        }
      ];

      final batchData = jsonEncode(
        {
          "requests": [
            {
              'method': 'PUT',
              'path':
                  '$keyEndPointClasses${user1.parseClassName}/${user1.objectId}',
              'body': user1.toJson(forApiRQ: true),
            }
          ]
        },
      );

      final batchPath = Uri.parse('$serverUrl/batch').toString();

      when(client.post(
        batchPath,
        options: anyNamed("options"),
        data: batchData,
      )).thenAnswer(
        (_) async {
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServerForBatch),
          );
        },
      );

      // post arrange
      const resultFromServer = {
        keyVarObjectId: "DLde4rYA8C",
        keyVarCreatedAt: "2023-02-26T00:20:37.187Z"
      };

      final postPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();

      when(client.post(
        postPath,
        options: anyNamed("options"),
        data: anyNamed("data"),
      )).thenAnswer(
        (_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          );
        },
      );

      dietPlansObject.addRelation('someRelationKey', [user1]);

      // act
      dietPlansObject.save();

      // async gap, this could be anything in the app like a click of a button
      await Future.delayed(Duration.zero);

      // Then suddenly the user adds a object to the relation
      dietPlansObject.addRelation('someRelationKey', [user2]);

      // Await the save function to be done
      await Future.delayed(Duration(milliseconds: 150));

      // assert
      final relationValueForApiReq =
          dietPlansObject.getRelation('someRelationKey').toJson();

      final expectedValueAfterSave = {
        '__op': 'AddRelation',
        'objects': parseEncode([user2])
      };

      expect(
        DeepCollectionEquality().equals(
          relationValueForApiReq,
          expectedValueAfterSave,
        ),
        isTrue,
      );
    });

    test(
        'ParseRelation value for api request should be identical '
        'before and after the save() failed to save the object', () async {
      // arrange

      // batch arrange
      const resultFromServerForBatch = [
        {
          "success": {
            keyVarUpdatedAt: "2023-03-10T12:23:45.678Z",
          }
        }
      ];

      final batchData = jsonEncode(
        {
          "requests": [
            {
              'method': 'PUT',
              'path':
                  '$keyEndPointClasses${user1.parseClassName}/${user1.objectId}',
              'body': user1.toJson(forApiRQ: true),
            }
          ]
        },
      );

      final batchPath = Uri.parse('$serverUrl/batch').toString();

      when(client.post(
        batchPath,
        options: anyNamed("options"),
        data: batchData,
      )).thenAnswer(
        (_) async {
          return ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServerForBatch),
          );
        },
      );

      // post arrange
      final postPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();

      when(client.post(
        postPath,
        options: anyNamed("options"),
        data: anyNamed("data"),
      )).thenThrow(Exception('error'));

      dietPlansObject.addRelation('someRelationKey', [user1]);

      final relationValueForApiReqBeforeErrorSave =
          dietPlansObject.getRelation('someRelationKey').toJson();

      // act
      await dietPlansObject.save();

      // assert
      final relationValueForApiReqAfterErrorSave =
          dietPlansObject.getRelation('someRelationKey').toJson();

      expect(
          DeepCollectionEquality().equals(
            relationValueForApiReqBeforeErrorSave,
            relationValueForApiReqAfterErrorSave,
          ),
          isTrue);
    });

    test(
        'The Relation internal state should be identical before and after '
        'storing it in data store', () async {
      // arrange
      dietPlansObject.objectId = "someId";

      final ParseRelation relation =
          dietPlansObject.getRelation('someRelationKey');
      relation.remove(ParseObject('someClassName'));

      final toJsonBeforePin = relation.toJson(full: true);

      // act
      await dietPlansObject.pin();

      final ParseObject objectFromPin = await dietPlansObject.fromPin('someId');

      // assert
      final toJsonAfterPin =
          objectFromPin.getRelation('someRelationKey').toJson(full: true);

      expect(
        DeepCollectionEquality().equals(toJsonBeforePin, toJsonAfterPin),
        isTrue,
      );
    });

    test(
        'should throw an exception if the user adds/removes a parse object'
        ' with different target class', () {
      // arrange
      final ParseRelation relation =
          dietPlansObject.getRelation('someRelationKey');

      relation.remove(ParseObject('someClassName')..objectId = "123");
      relation.remove(ParseObject('someClassName')..objectId = '456');

      // act
      // assert
      expect(
        () => relation.remove(ParseObject('otherClassName')),
        throwsA(isA<ParseRelationException>()),
      );
    });

    test(
        'If the value for API request is empty in ParseRelation then the'
        ' ParseRelation should not be part of the end map for'
        ' API request of an object', () {
      // arrange

      // this will create and store an empty relation if no relation associated
      // with this key
      dietPlansObject.getRelation('someRelationKey');

      // act

      final valueFroApiRequest = dietPlansObject.toJson(forApiRQ: true);

      // assert
      expect(valueFroApiRequest.isEmpty, isTrue);
    });

    test(
        'Should throw exception when getRelation() called on key'
        ' holds value other than Relation or null', () {
      // arrange
      dietPlansObject.set('someRelationKey', 'some String');

      // act
      getRelation() => dietPlansObject.getRelation('someRelationKey');

      // assert
      expect(() => getRelation(), throwsA(isA<ParseRelationException>()));
    });
  });
}
