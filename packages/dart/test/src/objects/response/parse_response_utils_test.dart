import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../test_utils.dart';

void main() {
  group('handleResponse()', () {
    setUp(() async {
      await initializeParse();
    });

    group('when batch', () {
      test(
          'should return a ParseResponse holds a list of created/updated ParseObjects',
          () {
        // arrange
        final object1 = ParseObject("object1");

        final object2 = ParseObject("object2")..objectId = "GYfSRRRXbL";

        final objectsToBatch = [object1, object2];

        const object1ResultFromServerObjectId = "YAfSAWwXbL";
        const object1ResultFromServerCreatedAt = "2023-03-19T00:20:37.187Z";

        const object2ResultFromServerUpdatedAt = "2023-03-19T00:20:37.187Z";

        final resultFromServerForBatch = json.encode(
          [
            {
              "success": {
                keyVarObjectId: object1ResultFromServerObjectId,
                keyVarCreatedAt: object1ResultFromServerCreatedAt,
              }
            },
            {
              "success": {
                keyVarUpdatedAt: object2ResultFromServerUpdatedAt,
              }
            }
          ],
        );

        final result = ParseNetworkResponse(
          data: resultFromServerForBatch,
          statusCode: 200,
        );

        // act
        final response = handleResponse(
          objectsToBatch,
          result,
          ParseApiRQ.batch,
          true,
          'test_batch',
        );

        // assert
        expect(response.success, isTrue);

        expect(response.count, equals(2));

        expect(response.error, isNull);

        final resultsObjectsList = List<ParseObject>.from(response.results!);

        expect(resultsObjectsList.length, equals(2));

        final firstObject = resultsObjectsList[0];
        final secondObject = resultsObjectsList[1];

        expect(firstObject.objectId, equals(object1ResultFromServerObjectId));

        expect(
          firstObject.createdAt!.toIso8601String(),
          equals(object1ResultFromServerCreatedAt),
        );

        expect(
          secondObject.updatedAt!.toIso8601String(),
          equals(object2ResultFromServerUpdatedAt),
        );
      });
    });
  });
}
