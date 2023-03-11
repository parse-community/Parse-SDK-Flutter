import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  group('save()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
        'save should store an object online. but store its children objects first '
        'then store the parent object. the children should be stored using batch request '
        'and the parent using normal request ', () async {
      // arrange
      final planObject = ParseObject('Plans')..set('PlanName', 'plan name');

      dietPlansObject.set('Plan', planObject);

      dietPlansObject.set('Fat', 15);

      // batch arrange
      const planObjectIdFromServer = "YAfSAWwXbL";
      const planCreatedAtFromServer = "2023-03-10T12:23:45.678Z";

      const resultFromServerForBatch = [
        {
          "success": {
            keyVarCreatedAt: planCreatedAtFromServer,
            keyVarObjectId: planObjectIdFromServer
          }
        }
      ];

      // parse server batch syntax
      // see https://docs.parseplatform.org/rest/guide/#batch-operations
      final batchData = jsonEncode(
        {
          "requests": [
            // object to be saved in batch
            {
              'method': 'POST',
              'path': '$keyEndPointClasses${planObject.parseClassName}',
              'body': planObject.toJson(forApiRQ: true),
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
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServerForBatch),
        ),
      );

      // post arrange

      final postPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
      ).toString();

      const dietPlansObjectIdFromServer = "BBERrYA8C";
      const dietPlansCreatedAtFromServer = "2023-02-26T00:20:37.187Z";

      const resultFromServer = {
        keyVarObjectId: dietPlansObjectIdFromServer,
        keyVarCreatedAt: dietPlansCreatedAtFromServer,
      };

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

      // act
      final response = await dietPlansObject.save();

      // assert
      expect(response.success, isTrue);

      expect(response.error, isNull);

      expect(response.count, equals(1));

      final resultList = response.results;

      expect(resultList, isNotNull);

      expect(resultList!.length, equals(1));

      expect(resultList, isA<List<ParseObject?>>());

      final savedDietPlansObject = (resultList.first as ParseObject);

      // the calling object (dietPlansObject) will be identical to the object
      // in the ParseResponse results
      expect(
        identical(dietPlansObject, savedDietPlansObject),
        isTrue,
      );

      expect(dietPlansObject.objectId, equals(dietPlansObjectIdFromServer));

      expect(planObject.objectId, equals(planObjectIdFromServer));

      expect(
        dietPlansObject.createdAt!.toIso8601String(),
        equals(dietPlansCreatedAtFromServer),
      );

      expect(
        planObject.createdAt!.toIso8601String(),
        equals(planCreatedAtFromServer),
      );

      verify(client.post(
        batchPath,
        options: anyNamed("options"),
        data: batchData,
      )).called(1);

      verify(client.post(
        postPath,
        options: anyNamed("options"),
        data: anyNamed('data'),
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'should return unsuccessful response if there is a unbreakable '
        'cycle between two or more unsaved objects', () async {
      // arrange
      final planObject = ParseObject('Plans');

      // create a cycle of unsaved objects depends on each other
      planObject.set('dietPlan', dietPlansObject);
      dietPlansObject.set('Plan', planObject);

      // act
      // TODO: should this throw an error about an unbreakable cycle between two or more unsaved objects?
      final response = await dietPlansObject.save();

      // assert
      expect(response.success, isFalse);

      verifyZeroInteractions(client);
    });

    test(
        'save should updated an object online and store and updated any object '
        'added via relation ', () async {
      // arrange
      dietPlansObject.objectId = "NNAfSGGHHbL";

      final planObjectToCreate = ParseObject('Plans')
        ..set('PlanName', 'plan 1');

      final planObjectToUpdate = ParseObject('Plans')
        ..objectId = "EEWAfSdXbL"
        ..set('PlanName', 'plan 2');

      dietPlansObject.addRelation(
        'relatedPlans',
        [planObjectToCreate, planObjectToUpdate],
      );

      dietPlansObject.set('Fat', 15);

      // batch arrange
      const planToCreateObjectIdFromServer = "YAfSAWwXbL";
      const planToCreateCreatedAtFromServer = "2023-03-10T12:23:45.678Z";

      const planToUpdateUpdatedAtFromServer = "2023-03-11T13:25:27.865Z";

      const resultFromServerForBatch = [
        {
          "success": {
            keyVarCreatedAt: planToCreateCreatedAtFromServer,
            keyVarObjectId: planToCreateObjectIdFromServer
          }
        },
        {
          "success": {
            keyVarUpdatedAt: planToUpdateUpdatedAtFromServer,
          }
        }
      ];

      final batchData = jsonEncode(
        {
          "requests": [
            {
              'method': 'POST',
              'path': '$keyEndPointClasses${planObjectToCreate.parseClassName}',
              'body': planObjectToCreate.toJson(forApiRQ: true),
            },
            {
              'method': 'PUT',
              'path':
                  '$keyEndPointClasses${planObjectToUpdate.parseClassName}/${planObjectToUpdate.objectId}',
              'body': planObjectToUpdate.toJson(forApiRQ: true),
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
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServerForBatch),
        ),
      );
      print(batchData);

      // PUT arrange
      final putPath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      const dietPlansUpdatedAtFromServer = "2023-02-26T00:20:37.187Z";
      const resultFromServer = {
        keyVarUpdatedAt: dietPlansUpdatedAtFromServer,
      };

      when(client.put(
        putPath,
        data: anyNamed("data"),
        options: anyNamed("options"),
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      // act
      final response = await dietPlansObject.save();

      // assert
      expect(response.success, isTrue);

      expect(response.error, isNull);

      expect(response.count, equals(1));

      final resultList = response.results;

      expect(resultList, isNotNull);

      expect(resultList!.length, equals(1));

      expect(resultList, isA<List<ParseObject?>>());

      final savedDietPlansObject = (resultList.first as ParseObject);

      // the calling object (dietPlansObject) will be identical to the object
      // in the ParseResponse results
      expect(
        identical(dietPlansObject, savedDietPlansObject),
        isTrue,
      );

      expect(
        dietPlansObject.updatedAt!.toIso8601String(),
        equals(dietPlansUpdatedAtFromServer),
      );

      expect(
        planObjectToCreate.createdAt!.toIso8601String(),
        equals(planToCreateCreatedAtFromServer),
      );

      expect(
        planObjectToCreate.objectId,
        equals(planToCreateObjectIdFromServer),
      );

      expect(
        planObjectToUpdate.updatedAt!.toIso8601String(),
        equals(planToUpdateUpdatedAtFromServer),
      );

      verify(client.post(
        batchPath,
        options: anyNamed("options"),
        data: batchData,
      )).called(1);

      verify(client.put(
        putPath,
        options: anyNamed("options"),
        data: anyNamed('data'),
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
      'should not save the calling object in case of any subObject(included) '
      'fail while trying to saving it, and the save() should return the response '
      'from the saving object batch',
      () async {
        // arrange
        final planObject1 = ParseObject('Plans')..set('PlanName', 'plan 1');
        final planObject2 = ParseObject('Plans')..set('PlanName', 'plan 2');

        dietPlansObject.set('Plan1', planObject1);
        dietPlansObject.set('Plan2', planObject2);

        dietPlansObject.set('Fat', 15);

        // batch arrange

        const resultFromServerForBatch = [
          {
            "success": {
              keyVarObjectId: "YAfSAWwXbL",
              keyVarCreatedAt: "2023-03-10T12:23:45.678Z",
            }
          },
          {
            "error": {
              "code": ParseError.internalServerError,
              "error": "internal server error",
            }
          }
        ];

        final batchData = jsonEncode(
          {
            "requests": [
              {
                'method': 'POST',
                'path': '$keyEndPointClasses${planObject1.parseClassName}',
                'body': planObject1.toJson(forApiRQ: true),
              },
              {
                'method': 'POST',
                'path': '$keyEndPointClasses${planObject2.parseClassName}',
                'body': planObject2.toJson(forApiRQ: true),
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
          (_) async => ParseNetworkResponse(
            statusCode: 200,
            data: jsonEncode(resultFromServerForBatch),
          ),
        );

        // post arrange

        final postPath = Uri.parse(
          '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}',
        ).toString();

        // act

        // this response is from saving the children and not from saving the
        // actual object (dietPlansObject) duo to error while saving one of
        // the children, so the response form the batch function will be returned
        final response = await dietPlansObject.save();

        // assert
        expect(response.success, isFalse);

        // the error will be the results list
        expect(response.error, isNull);

        expect(response.count, equals(2));

        final resultList = response.results;

        expect(resultList, isNotNull);

        expect(
          resultList!.length,
          equals(2),
          reason:
              'should be the same number of children sent suing batch request',
        );

        expect(resultList, isA<List<Object?>>());

        final firstResponse = resultList[0];

        expect(firstResponse, isA<ParseObject>());

        expect(identical(firstResponse, planObject1), isTrue);

        var objectCreatedResponseFromServer =
            resultFromServerForBatch[0]['success']!;

        expect(
          planObject1.objectId,
          equals(objectCreatedResponseFromServer[keyVarObjectId]),
        );

        expect(
          planObject1.createdAt!.toIso8601String(),
          equals(objectCreatedResponseFromServer[keyVarCreatedAt]),
        );

        final secondResponse = resultList[1];
        var errorResponseFromServer = resultFromServerForBatch[1]['error']!;

        expect(secondResponse, isA<ParseError>());

        // to promote the secondResponse var to ParseError
        (secondResponse as ParseError);

        expect(
          secondResponse.code,
          equals(errorResponseFromServer['code']),
        );

        expect(
          secondResponse.message,
          equals(errorResponseFromServer['error']),
        );

        expect(
          dietPlansObject.objectId,
          isNull,
          reason: 'dietPlansObject should not be saved',
        );

        verify(client.post(
          batchPath,
          options: anyNamed("options"),
          data: batchData,
        )).called(1);

        verifyNever(client.post(
          postPath,
          options: anyNamed("options"),
          data: anyNamed('data'),
        ));

        verifyNoMoreInteractions(client);
      },
      skip: 'see # and #',
    );
  });
}
