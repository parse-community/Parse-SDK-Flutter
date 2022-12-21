import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  test(
      'should return expectedResult json when json has Nested map and list data.',
      () async {
    // arrange
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

    ParseObject parseObject2 = ParseObject("objectId2");
    parseObject2.objectId = "objectId2";

    // List and Map
    parseObject2
        .setAdd("dataParseObjectList", ["ListText1", "ListText2", "ListText3"]);
    parseObject2.setAdd("dataParseObjectMap", {
      'KeyTestMap1': 'ValueTestMap1',
      'KeyTestMap2': 'ValueTestMap2',
      'KeyTestMap3': 'ValueTestMap3',
    });

    // parseObject2 inside parseObject1
    ParseObject parseObject1 = ParseObject("parseObject1");
    parseObject1.objectId = "objectId1";
    parseObject1.setAdd("dataParseObject2", parseObject2);

    // desired output
    String expectedResult =
        "{className: parseObject1, objectId: objectId1, dataParseObject2: {__op: Add, objects: [{className: objectId2, objectId: objectId2, dataParseObjectList: {__op: Add, objects: [[ListText1, ListText2, ListText3]]}, dataParseObjectMap: {__op: Add, objects: [{KeyTestMap1: ValueTestMap1, KeyTestMap2: ValueTestMap2, KeyTestMap3: ValueTestMap3}]}}]}}";

    // act
    dynamic actualResult = parseEncode(parseObject1, full: true);

    //assert
    expect(actualResult.toString(), expectedResult);
  });
}
