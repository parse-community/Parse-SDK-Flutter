import 'dart:convert';

import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('Relation', () {
    test('addRelation', () async {
      // arrange
      await Parse().initialize(
        'appId', 'https://test.parse.com',
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

      var parentObj = {
        "objectId": "mGGxAy3eek",
        "relationKey": {"__type": "Relation", "className": "relationKey"}
      };

      Map<String, dynamic> map = json.decode(jsonEncode(parentObj));
      final ParseObject parent = ParseObject.clone("ParentClass").fromJson(map);

      final ParseObject child1 = ParseObject("ChildClass");
      child1.objectId = "child1";
      final ParseObject child2 = ParseObject("ChildClass");
      child2.objectId = "child2";
      ParseRelation parseRelation =
          ParseRelation(parent: parent, key: "relationKey");
      parent.addRelation("relationKey", parseRelation, [child1, child2]);

      // desired output
      var expectedResult = {
        "relationKey": {
          "__op": "AddRelation",
          "objects": [
            {
              "__type": "Pointer",
              "className": "ChildClass",
              "objectId": "child1"
            },
            {
              "__type": "Pointer",
              "className": "ChildClass",
              "objectId": "child2"
            }
          ]
        }
      };

      var act = parent.toJson(forApiRQ: true);
      expect(act, expectedResult);
    });
  });
  test('removeRelation', () async {
    // arrange
    await Parse().initialize(
      'appId', 'https://test.parse.com',
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

    var parentObj = {
      "objectId": "mGGxAy3eek",
      "relationKey": {"__type": "Relation", "className": "relationKey"}
    };

    Map<String, dynamic> map = json.decode(jsonEncode(parentObj));
    final ParseObject parent = ParseObject.clone("ParentClass").fromJson(map);
    final ParseObject child1 = ParseObject("ChildClass");
    child1.objectId = "child1";
    parent.removeRelation("relationKey",
        ParseRelation(parent: parent, key: "relationKey"), [child1]);

    // desired output
    var expectedResult = {
      "relationKey": {
        "__op": "RemoveRelation",
        "objects": [
          {"__type": "Pointer", "className": "ChildClass", "objectId": "child1"}
        ]
      }
    };
    var act = parent.toJson(forApiRQ: true);
    expect(act, expectedResult);
  });
}
