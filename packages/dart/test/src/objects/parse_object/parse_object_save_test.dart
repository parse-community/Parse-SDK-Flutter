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
            "createdAt": planCreatedAtFromServer,
            "objectId": planObjectIdFromServer
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
  });
}
