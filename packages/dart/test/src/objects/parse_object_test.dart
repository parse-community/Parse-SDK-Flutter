import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

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
      },
    );
  });
}
