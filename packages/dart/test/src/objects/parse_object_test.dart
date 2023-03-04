import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../parse_query_test.mocks.dart';

@GenerateMocks([ParseClient])
void main() {
  group('parseObject', () {
    late MockParseClient client;
    setUp(() async {
      client = MockParseClient();

      await Parse().initialize(
        'appId',
        'https://example.com',
        debug: true,
        // to prevent automatic detection
        fileDirectory: 'someDirectory',
        // to prevent automatic detection
        appName: 'appName',
        // to prevent automatic detection
        appPackageName: 'somePackageName',
        // to prevent automatic detection
        appVersion: 'someAppVersion',
      );
    });

    test('should return expectedIncludeResult json when use fetch', () async {
      // arrange
      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      var desiredOutput = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            "phone": "+12025550463",
            "createdAt": "2022-09-04T13:35:20.883Z",
            "updatedAt": "2022-11-14T10:55:56.202Z",
            "img": {
              "objectId": "8nGrLj3Mvk",
              "size": "67663",
              "mime": "image/jpg",
              "file": {
                "__type": "File",
                "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
                "url":
                    "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
              },
              "createdAt": "2022-11-14T10:55:56.025Z",
              "updatedAt": "2022-11-14T10:55:56.025Z",
              "__type": "Object",
              "className": "MyFile",
            },
          }
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      ParseObject parseObject = await myUserObject.fetch(include: ["img"]);

      var objectDesiredOutput = {
        "className": "MyFile",
        "objectId": "8nGrLj3Mvk",
        "createdAt": "2022-11-14T10:55:56.025Z",
        "updatedAt": "2022-11-14T10:55:56.025Z",
        "size": "67663",
        "mime": "image/jpg",
        "file": {
          "__type": "File",
          "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
          "url":
              "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
        },
      };
      var objectJsonDesiredOutput = jsonEncode(objectDesiredOutput);

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(
          jsonEncode(
              parseEncode(parseObject.get<ParseObject>('img'), full: true)),
          objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.query), 'include=img');
    });

    test('should return expectedIncludeResult json when use getObject',
        () async {
      // arrange
      ParseObject myUserObject = ParseObject("MyUser", client: client);
      myUserObject.objectId = "Mn1iJTkWTE";

      var desiredOutput = {
        "results": [
          {
            "objectId": "Mn1iJTkWTE",
            "phone": "+12025550463",
            "createdAt": "2022-09-04T13:35:20.883Z",
            "updatedAt": "2022-11-14T10:55:56.202Z",
            "img": {
              "objectId": "8nGrLj3Mvk",
              "size": "67663",
              "mime": "image/jpg",
              "file": {
                "__type": "File",
                "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
                "url":
                    "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
              },
              "createdAt": "2022-11-14T10:55:56.025Z",
              "updatedAt": "2022-11-14T10:55:56.025Z",
              "__type": "Object",
              "className": "MyFile",
            },
          }
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      ParseResponse response =
          await myUserObject.getObject("Mn1iJTkWTE", include: ["img"]);

      ParseObject parseObject = response.results?.first;

      var objectDesiredOutput = {
        "className": "MyFile",
        "objectId": "8nGrLj3Mvk",
        "createdAt": "2022-11-14T10:55:56.025Z",
        "updatedAt": "2022-11-14T10:55:56.025Z",
        "size": "67663",
        "mime": "image/jpg",
        "file": {
          "__type": "File",
          "name": "dc7320ee9146ee19aed8997722fd4e3c.bin",
          "url":
              "http://ip:port/api/files/myapp/dc7320ee9146ee19aed8997722fd4e3c.bin",
        },
      };
      var objectJsonDesiredOutput = jsonEncode(objectDesiredOutput);

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(
          jsonEncode(
              parseEncode(parseObject.get<ParseObject>('img'), full: true)),
          objectJsonDesiredOutput);
      expect(parseObject['img'].objectId, "8nGrLj3Mvk");

      expect(Uri.decodeComponent(result.query), 'include=img');
    });

    group('getAll()', () {
      late ParseObject dietPlansObject;

      setUp(() {
        dietPlansObject = ParseObject("Diet_Plans", client: client);
      });

      test('getAll() should return all objects', () async {
        // arrange

        var desiredOutput = {
          "results": [
            {
              "objectId": "lHJEkg7kxm",
              "Name": "Textbook",
              "Description":
                  "For an active lifestyle and a straight forward macro plan, we suggest this plan.",
              "Fat": 25,
              "Carbs": 50,
              "Protein": 25,
              "Status": false,
              "user": {
                "__type": "Pointer",
                "className": "_User",
                "objectId": "cmWCmCAyQQ"
              },
              "createdAt": "2023-02-24T15:39:44.800Z",
              "updatedAt": "2023-02-24T22:28:17.867Z",
              "location": {
                "__type": "GeoPoint",
                "latitude": 50,
                "longitude": 0
              },
              "anArray": ["3", "4"]
            },
            {
              "objectId": "15NCdmBFBw",
              "Name": "Zone Diet",
              "Description":
                  "Popular with CrossFit users. Zone Diet targets similar macros.",
              "Fat": 30,
              "Carbs": 40,
              "Protein": 30,
              "Status": true,
              "user": {
                "__type": "Pointer",
                "className": "_User",
                "objectId": "cmWCmCAyQQ"
              },
              "createdAt": "2023-02-24T15:44:17.781Z",
              "updatedAt": "2023-02-24T22:28:45.446Z",
              "location": {
                "__type": "GeoPoint",
                "latitude": 10,
                "longitude": 20
              },
              "anArray": ["1", "2"],
              "afile": {
                "__type": "File",
                "name": "33b6acb416c0mmer-wallpapers.png",
                "url":
                    "https://parsefiles.back4app.com/gyBkQBRSapgwfxB/cers.png"
              }
            }
          ]
        };

        when(client.get(
          any,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).thenAnswer((_) async => ParseNetworkResponse(
              statusCode: 200,
              data: jsonEncode(desiredOutput),
            ));

        // act
        ParseResponse response = await dietPlansObject.getAll();

        // assert
        List<ParseObject> listParseObject = List<ParseObject>.from(
          response.results!,
        );

        expect(response.results?.first, isA<ParseObject>());

        expect(
          listParseObject.length,
          equals(desiredOutput["results"]!.length),
        );

        verify(client.get(
          captureAny,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).called(1);

        verifyNoMoreInteractions(client);
      });

      test('getAll() should return error', () async {
        // arrange

        final error = Exception('error');

        when(client.get(
          any,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).thenThrow(error);

        // act
        ParseResponse response = await dietPlansObject.getAll();

        // assert

        expect(response.results, isNull);
        expect(response.error, isNotNull);
        expect(response.error!.exception, equals(error));
        expect(response.error!.code, equals(-1));

        verify(client.get(
          captureAny,
          options: anyNamed("options"),
          onReceiveProgress: anyNamed("onReceiveProgress"),
        )).called(1);

        verifyNoMoreInteractions(client);
      });
    });

    group('create()', () {
      late ParseObject dietPlansObject;

      setUp(() {
        final user = ParseObject(keyClassUser)..objectId = "ELR124r8C";
        dietPlansObject = ParseObject("Diet_Plans", client: client);
        dietPlansObject
          ..set('Name', 'value')
          ..set('Fat', 15)
          ..set('user', user)
          ..set("location", ParseGeoPoint(latitude: 10, longitude: 10));
      });

      test(
          'create() should create new object on the server, return the created '
          'object in ParseResponse results and update the calling object '
          'with the new data (objectId,createdAt). i.e: mutate the object state',
          () async {
        // arrange

        final resultFromServer = {
          keyVarObjectId: "DLde4rYA8C",
          keyVarCreatedAt: "2023-02-26T00:20:37.187Z"
        };
        final postData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));

        when(client.post(
          any,
          options: anyNamed("options"),
          data: postData,
        )).thenAnswer(
          (realInvocation) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          ),
        );

        // act
        ParseResponse response = await dietPlansObject.create();

        // assert
        final resultList = response.results;

        expect(resultList, isNotNull);
        expect(resultList!.first, isNotNull);
        expect(resultList.first, isA<ParseObject>());

        final parseObject = (resultList.first as ParseObject);

        expect(
          parseObject.createdAt!.toIso8601String(),
          equals(resultFromServer[keyVarCreatedAt]),
        );
        expect(
          dietPlansObject.createdAt!.toIso8601String(),
          equals(resultFromServer[keyVarCreatedAt]),
        );

        expect(
          parseObject.objectId,
          equals(resultFromServer[keyVarObjectId]),
        );
        expect(
          dietPlansObject.objectId,
          equals(resultFromServer[keyVarObjectId]),
        );

        // the calling object (dietPlansObject) will be identical to the object
        // in the ParseResponse results
        expect(
          identical(dietPlansObject, parseObject),
          isTrue,
        );

        verify(client.post(
          captureAny,
          options: anyNamed("options"),
          data: postData,
        )).called(1);

        verifyNoMoreInteractions(client);
      });

      test('create() should return error', () async {
        // arrange

        final postData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));
        final error = Exception('error');
        when(client.post(
          any,
          options: anyNamed("options"),
          data: postData,
        )).thenThrow(error);

        // act
        ParseResponse response = await dietPlansObject.create();

        // assert

        expect(response.results, isNull);
        expect(response.error, isNotNull);
        expect(response.error!.exception, equals(error));
        expect(response.error!.code, equals(-1));
        expect(dietPlansObject.objectId, isNull);
        expect(dietPlansObject.createdAt, isNull);

        verify(client.post(
          captureAny,
          options: anyNamed("options"),
          data: postData,
        )).called(1);

        verifyNoMoreInteractions(client);
      });
    });

    group('update()', () {
      const keyName = 'Name';
      const keyFat = 'Fat';

      final newNameValue = 'new Name';
      final newFatValue = 56;

      late ParseObject dietPlansObject;

      setUp(() {
        dietPlansObject = ParseObject("Diet_Plans", client: client);
        dietPlansObject
          ..objectId = "DLde4rYA8C"
          ..set(keyName, newNameValue)
          ..set(keyFat, newFatValue);
      });

      test(
          'update() should update an object on the server, return the updated '
          'object in ParseResponse results and update the calling object '
          'with the new data (updatedAt).'
          'i.e: mutate the object state to reflect the new update', () async {
        // arrange

        final resultFromServer = {
          keyVarUpdatedAt: "2023-02-26T13:25:27.865Z",
        };

        final putData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));

        when(client.put(
          any,
          options: anyNamed("options"),
          data: putData,
        )).thenAnswer(
          (realInvocation) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          ),
        );

        // act
        ParseResponse response = await dietPlansObject.update();

        // assert
        final resultList = response.results;

        expect(resultList, isNotNull);
        expect(resultList!.first, isNotNull);
        expect(resultList.first, isA<ParseObject>());

        final parseObjectFromRes = (resultList.first as ParseObject);

        expect(
          parseObjectFromRes.updatedAt!.toIso8601String(),
          equals(resultFromServer[keyVarUpdatedAt]),
        );
        expect(
          dietPlansObject.updatedAt!.toIso8601String(),
          equals(resultFromServer[keyVarUpdatedAt]),
        );

        expect(
          parseObjectFromRes.get(keyName),
          equals(newNameValue),
        );
        expect(
          parseObjectFromRes.get(keyFat),
          equals(newFatValue),
        );

        // the calling object (dietPlansObject) will be identical to the object
        // in the ParseResponse results
        expect(
          identical(dietPlansObject, parseObjectFromRes),
          isTrue,
        );

        verify(client.put(
          captureAny,
          options: anyNamed("options"),
          data: putData,
        )).called(1);

        verifyNoMoreInteractions(client);
      });

      test(
          'update() should return error and the updated values should remain the same',
          () async {
        // arrange

        final putData = jsonEncode(dietPlansObject.toJson(forApiRQ: true));
        final error = Exception('error');
        when(client.put(
          any,
          options: anyNamed("options"),
          data: putData,
        )).thenThrow(error);

        // act
        ParseResponse response = await dietPlansObject.update();

        // assert

        expect(response.results, isNull);
        expect(response.error, isNotNull);
        expect(response.error!.exception, equals(error));
        expect(response.error!.code, equals(ParseError.otherCause));

        // even if the update failed, the updated values should remain the same
        expect(dietPlansObject.get(keyName), equals(newNameValue));
        expect(dietPlansObject.get(keyFat), equals(newFatValue));

        verify(client.put(
          captureAny,
          options: anyNamed("options"),
          data: putData,
        )).called(1);

        verifyNoMoreInteractions(client);
      });

      test('should throw AssertionError if objectId is null', () {
        dietPlansObject.objectId = null;

        expect(
          () async => await dietPlansObject.update(),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw AssertionError if objectId is empty', () {
        dietPlansObject.objectId = '';

        expect(
          () async => await dietPlansObject.update(),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    //TODO: add tesets for the save() function
    // group('save()', () {});

    group(
      'Relation',
      () {
        late ParseObject dietPlansObject;

        late ParseUser user1;
        late ParseUser user2;

        setUp(() {
          user1 = ParseUser.forQuery()..objectId = 'user1';
          user2 = ParseUser.forQuery()..objectId = 'user2';

          final resultFromServer = {
            "objectId": "O6BHlwV48Z",
            "Name": "new name",
            "Description": "Low fat diet.",
            "Fat": 65,
            "createdAt": "2023-02-26T13:23:03.073Z",
            "updatedAt": "2023-03-01T03:38:16.390Z",
            "usersRelation": {"__type": "Relation", "className": "_User"}
          };

          dietPlansObject = ParseObject('Diet_Plans')
            ..fromJson(resultFromServer);
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
          // arrange

          // act
          dietPlansObject.addRelation('usersRelation', [user1, user2]);

          // assert
          final toJsonAfterAddRelation = dietPlansObject.toJson(forApiRQ: true);

          final expectedToJson = {
            "usersRelation": {
              "__op": "AddRelation",
              "objects": [
                {
                  "__type": "Pointer",
                  "className": "_User",
                  "objectId": "user1"
                },
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

        test('addRelation() operation should not be mergeable with any other',
            () {
          testUnmergeableOperationShouldThrow(
            parseObject: dietPlansObject,
            testingOn: dietPlansObject.addRelation,
          );
        });

        test(
            'removeRelation() operation should not be mergeable with any other',
            () {
          testUnmergeableOperationShouldThrow(
            parseObject: dietPlansObject,
            testingOn: dietPlansObject.removeRelation,
          );
        });
      },
    );

    group(
      'Array',
      () {
        const keyArray = 'array';

        late ParseObject dietPlansObject;

        setUp(() {
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
          final resultFromServer = {
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
          final resultFromServer = {
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
          final resultFromServer = {
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
          final resultFromServer = {
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
          final resultFromServer = {
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
      skip: 'get(keyArray) will return _Map<String, dynamic>'
          'which is the wrong type. it should be any subtype of Iterable'
          'see the issue #834',
    );

    group(
      'Increment/Decrement',
      () {
        const keyFat = 'fat';

        late ParseObject dietPlansObject;

        setUp(() {
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
          final resultFromServer = {
            "objectId": "O6BHlwV48Z",
            "createdAt": "2023-02-26T13:23:03.073Z",
            "updatedAt": "2023-03-01T03:38:16.390Z",
            keyFat: 2.5,
          };

          dietPlansObject = ParseObject('Diet_Plans')
            ..fromJson(resultFromServer);

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
          skip: 'see #843',
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
          final resultFromServer = {
            "objectId": "O6BHlwV48Z",
            "createdAt": "2023-02-26T13:23:03.073Z",
            "updatedAt": "2023-03-01T03:38:16.390Z",
            keyFat: 3.5,
          };

          dietPlansObject = ParseObject('Diet_Plans')
            ..fromJson(resultFromServer);

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
          skip: 'see #843',
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
      },
      skip: 'get(key) will return _Map<String, dynamic>'
          'which is the wrong type. it should be any subtype of num'
          'see the issue #842',
    );

    group('unset()', () {
      const keyFat = 'fat';

      late ParseObject dietPlansObject;

      setUp(() {
        dietPlansObject = ParseObject("Diet_Plans", client: client);
      });

      test('unset() should unset a value from ParseObject locally', () async {
        // arrange
        dietPlansObject.set(keyFat, 2);

        // act
        final ParseResponse parseResponse =
            await dietPlansObject.unset(keyFat, offlineOnly: true);

        // assert
        expect(parseResponse.success, isTrue);

        expect(dietPlansObject.get(keyFat), isNull);

        verifyNever(client.put(
          captureAny,
          options: anyNamed("options"),
          data: anyNamed('data'),
        ));

        verifyZeroInteractions(client);
      });

      test('unset() should unset a value from ParseObject locally on online',
          () async {
        // arrange
        dietPlansObject.set(keyFat, 2);
        dietPlansObject.objectId = "O6BHlwV48Z";

        final String putData = '{"$keyFat":{"__op":"Delete"}}';
        final resultFromServer = {
          keyVarUpdatedAt: "2023-03-04T03:34:35.076Z",
        };
        when(client.put(
          any,
          options: anyNamed("options"),
          data: putData,
        )).thenAnswer(
          (realInvocation) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServer),
          ),
        );

        // act
        final ParseResponse parseResponse = await dietPlansObject.unset(keyFat);

        // assert
        expect(parseResponse.success, isTrue);

        expect(dietPlansObject.get(keyFat), isNull);

        verify(client.put(
          captureAny,
          options: anyNamed("options"),
          data: putData,
        )).called(1);

        verifyNoMoreInteractions(client);
      });

      test(
          'If objectId is null, unset() should unset a value from ParseObject '
          'locally and not make any call to the server and return success Response',
          () async {
        // arrange
        dietPlansObject.set(keyFat, 2);

        // act
        final ParseResponse parseResponse = await dietPlansObject.unset(keyFat);

        // assert
        expect(parseResponse.success, isFalse);

        expect(dietPlansObject.get(keyFat), isNull);

        verifyNever(client.put(
          captureAny,
          options: anyNamed("options"),
          data: anyNamed('data'),
        ));

        verifyZeroInteractions(client);
      });
    });
  });
}

/// If an unmergeable operation [testingOn] is attempted after an operation,
/// it should result in an exception being thrown. in context of the same key.
///
/// So for example you can call setAdd after setAddAll on the same key, because
/// the values can be merged together. but calling setAdd after setIncrement
/// will throw an error because you can not increment a value and then add a
/// value to it like a list, it is not a list in the first place to be able
/// to add to it.
///
///
/// if a certain operation cannot be merged or combined with other operations
/// in a particular context, then an exception should be thrown to alert
/// the developer that the operation cannot be performed.
///
/// List of available operations:
/// * setAdd
/// * setAddUnique
/// * setAddAll
/// * setAddAllUnique
/// * setRemove
/// * setRemoveAll
/// * setIncrement
/// * setDecrement
/// * addRelation
/// * removeRelation
///
/// e.g.
/// ```dart
///    testUnmergeableOperationShouldThrow(
///      parseObject: dietPlansObject,
///      testingOn: dietPlansObject.setDecrement,
///      excludeMergeableOperations: [dietPlansObject.setIncrement],
///   );
/// ```
void testUnmergeableOperationShouldThrow({
  required ParseObject parseObject,
  required Function testingOn,
  List<Function> excludeMergeableOperations = const [],
}) {
  String testingOnKey = 'key';

  final Map<Function, List> operationsFuncRefWithArgs = {
    parseObject.setAdd: [
      testingOnKey,
      1,
    ],
    parseObject.setAddUnique: [
      testingOnKey,
      1,
    ],
    parseObject.setAddAll: [
      testingOnKey,
      [1, 2],
    ],
    parseObject.setAddAllUnique: [
      testingOnKey,
      [1, 2],
    ],
    parseObject.setRemove: [
      testingOnKey,
      1,
    ],
    parseObject.setRemoveAll: [
      testingOnKey,
      [1, 2]
    ],
    parseObject.setIncrement: [
      testingOnKey,
      1,
    ],
    parseObject.setDecrement: [
      testingOnKey,
      1,
    ],
    parseObject.addRelation: [
      testingOnKey,
      [ParseObject('class')]
    ],
    parseObject.removeRelation: [
      testingOnKey,
      [ParseObject('class')]
    ],
  };

  final testingOnValue = operationsFuncRefWithArgs.remove(testingOn);

  for (final functionExclude in excludeMergeableOperations) {
    operationsFuncRefWithArgs.remove(functionExclude);
  }

  for (final operation in operationsFuncRefWithArgs.entries) {
    parseObject.unset(testingOnKey, offlineOnly: true);

    final functionRef = operation.key;
    final positionalArguments = operation.value;

    Function.apply(functionRef, positionalArguments);

    expect(
      () => Function.apply(testingOn, testingOnValue),
      throwsA(isA<String>()),
      reason: 'Can not call $testingOn after $functionRef',
    );
  }
}
