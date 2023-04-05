import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('full encode', () {
    test('should return the expected json encode ', () async {
      // arrange
      final dietPlansObject = ParseObject("Diet_Plans");
      final plan = ParseObject("plan")..set('somePlanKey', 'some value');
      dietPlansObject.set('pointer_val', plan);
      dietPlansObject.set('int_val', 2);
      dietPlansObject.set('string_val', 'some String');
      dietPlansObject.set('double_val', 2.5);
      dietPlansObject.setIncrement('int_val', 2);
      dietPlansObject.setDecrement('double_val', 2);
      dietPlansObject.set('array_1_val', [1, 2, 3]);
      dietPlansObject.set('array_2_val', [1, 2, 3]);
      dietPlansObject.set('array_3_val', [1, 2, 3]);
      dietPlansObject.setAdd('array_1_val', 3);
      dietPlansObject.setAddUnique('array_2_val', 3);
      dietPlansObject.setAddUnique('array_2_val', 4);
      dietPlansObject.setRemove('array_3_val', 3);
      final relation = dietPlansObject.getRelation('relation_val');
      relation.add(ParseObject('object_in_relation2')..objectId = 'GDIJPWW');

      // act
      final encodeResult = parseEncode(dietPlansObject, full: true);

      // assert

      const expectedValue = {
        "className": "Diet_Plans",
        "pointer_val": {"className": "plan", "somePlanKey": "some value"},
        "int_val": {
          "className": "ParseIncrementOperation",
          "__op": "Increment",
          "amount": 2.0,
          "estimatedValue": 4
        },
        "string_val": "some String",
        "double_val": {
          "className": "ParseIncrementOperation",
          "__op": "Increment",
          "amount": -2.0,
          "estimatedValue": 0.5
        },
        "array_1_val": {
          "className": "ParseArray",
          "estimatedArray": [1, 2, 3, 3],
          "savedArray": [],
          "lastPreformedOperation": null
        },
        "array_2_val": {
          "className": "ParseArray",
          "estimatedArray": [1, 2, 3, 4],
          "savedArray": [],
          "lastPreformedOperation": null
        },
        "array_3_val": {
          "className": "ParseArray",
          "estimatedArray": [1, 2],
          "savedArray": [],
          "lastPreformedOperation": null
        },
        "relation_val": {
          "className": "ParseRelation",
          "targetClass": "object_in_relation2",
          "key": "relation_val",
          "objects": [
            {"className": "object_in_relation2", "objectId": "GDIJPWW"}
          ],
          "lastPreformedOperation": {
            "__op": "AddRelation",
            "objects": [
              {"className": "object_in_relation2", "objectId": "GDIJPWW"}
            ],
            "valueForAPIRequest": [
              {"className": "object_in_relation2", "objectId": "GDIJPWW"}
            ]
          }
        }
      };

      expect(jsonEncode(encodeResult), equals(jsonEncode(expectedValue)));
    });
  });
}
