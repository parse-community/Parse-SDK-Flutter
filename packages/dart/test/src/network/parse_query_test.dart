import 'dart:convert';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../test_utils.dart';
import '../objects/parse_object/parse_object_test.mocks.dart';

@GenerateMocks([ParseClient])
void main() {
  setUpAll(() async {
    await initializeParse();
  });

  group('queryBuilder', () {
    late MockParseClient client;

    setUp(() {
      client = MockParseClient();
    });

    test('whereRelatedTo', () async {
      // arrange
      final QueryBuilder<ParseObject> queryBuilder =
          QueryBuilder<ParseObject>(ParseObject('_User', client: client));
      queryBuilder.whereRelatedTo('likes', 'Post', '8TOXdXf3tz');

      var desiredOutput = {
        "results": [
          {
            "objectId": "eT9muOxBTJ",
            "username": "test",
            "createdAt": "2021-04-23T13:46:06.092Z",
            "updatedAt": "2021-04-23T13:46:23.586Z",
            "ACL": {
              "*": {"read": true},
              "eT9muOxBTJ": {"read": true, "write": true}
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
      ParseResponse response = await queryBuilder.query();

      ParseObject parseObject = response.results?.first;

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      var queryDesiredOutput = {
        "\$relatedTo": {
          "object": {
            "__type": "Pointer",
            "className": "Post",
            "objectId": "8TOXdXf3tz",
          },
          "key": "likes"
        },
      };
      final Uri expectedQuery =
          Uri(query: 'where=${jsonEncode(queryDesiredOutput)}');

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(parseObject.get<String>(keyVarUsername), "test");
      expect(parseObject.objectId, "eT9muOxBTJ");
      expect(parseObject.createdAt, DateTime.parse("2021-04-23T13:46:06.092Z"));
      expect(parseObject.updatedAt, DateTime.parse("2021-04-23T13:46:23.586Z"));

      expect(result.path, '/classes/_User');

      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.or', () async {
      // arrange
      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "Liam");

      var lastName = QueryBuilder<ParseObject>(user)
        ..regEx('lastName', "Johnson");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.or(
        user,
        [firstName, lastName],
      );

      var desiredOutput = {
        "results": [
          {
            "className": "_User",
            "objectId": "fqx5BECOME",
            "createdAt": "2022-10-25T06:04:47.138Z",
            "updatedAt": "2022-10-25T06:05:22.328Z",
            "firstName": "Liam1",
            "lastName": "Johnson1",
          },
          {
            "className": "_User",
            "objectId": "hAtRRYGrUO",
            "createdAt": "2022-01-24T15:53:48.396Z",
            "updatedAt": "2022-01-25T05:52:01.701Z",
            "firstName": "Liam2",
            "lastName": "Johnson2",
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
      var response = await mainQuery.query();

      ParseObject parseObject = response.results?.first;

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      var queryDesiredOutput = {
        "\$or": [
          {
            "firstName": {"\$regex": "Liam"}
          },
          {
            "lastName": {"\$regex": "Johnson"},
          }
        ],
      };
      final Uri expectedQuery =
          Uri(query: 'where=${jsonEncode(queryDesiredOutput)}');

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(parseObject.get<String>("firstName"), "Liam1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      expect(result.path, '/classes/_User');

      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.and', () async {
      // arrange
      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "jak");

      var lastName = QueryBuilder<ParseObject>(user)..regEx('lastName', "jaki");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.and(
        user,
        [firstName, lastName],
      );

      var desiredOutput = {
        "results": [
          {
            "className": "_User",
            "objectId": "fqx5BECOME",
            "createdAt": "2022-10-25T06:04:47.138Z",
            "updatedAt": "2022-10-25T06:05:22.328Z",
            "firstName": "jak1",
            "lastName": "jaki1",
          },
          {
            "className": "_User",
            "objectId": "hAtRRYGrUO",
            "createdAt": "2022-01-24T15:53:48.396Z",
            "updatedAt": "2022-01-25T05:52:01.701Z",
            "firstName": "jak2",
            "lastName": "jaki2",
          },
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      var response = await mainQuery.query();

      ParseObject parseObject = response.results?.first;

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      var queryDesiredOutput = {
        "\$and": [
          {
            "firstName": {"\$regex": "jak"}
          },
          {
            "lastName": {"\$regex": "jaki"},
          }
        ],
      };
      final Uri expectedQuery =
          Uri(query: 'where=${jsonEncode(queryDesiredOutput)}');

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(parseObject.get<String>("firstName"), "jak1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      expect(result.path, '/classes/_User');

      expect(result.query, expectedQuery.query);
    });

    test('QueryBuilder.nor', () async {
      // arrange
      ParseObject user = ParseObject("_User", client: client);
      var firstName = QueryBuilder<ParseObject>(user)
        ..regEx('firstName', "Oliver");

      var lastName = QueryBuilder<ParseObject>(user)
        ..regEx('lastName', "Smith");

      QueryBuilder<ParseObject> mainQuery = QueryBuilder.nor(
        user,
        [firstName, lastName],
      );

      var desiredOutput = {
        "results": [
          {
            "className": "_User",
            "objectId": "fqx5BECOME",
            "createdAt": "2022-10-25T06:04:47.138Z",
            "updatedAt": "2022-10-25T06:05:22.328Z",
            "firstName": "Oliver1",
            "lastName": "Smith1",
          },
          {
            "className": "_User",
            "objectId": "hAtRRYGrUO",
            "createdAt": "2022-01-24T15:53:48.396Z",
            "updatedAt": "2022-01-25T05:52:01.701Z",
            "firstName": "Oliver2",
            "lastName": "Smith2",
          },
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      var response = await mainQuery.query();

      ParseObject parseObject = response.results?.first;

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      var queryDesiredOutput = {
        "\$nor": [
          {
            "firstName": {"\$regex": "Oliver"}
          },
          {
            "lastName": {"\$regex": "Smith"},
          }
        ],
      };
      final Uri expectedQuery =
          Uri(query: 'where=${jsonEncode(queryDesiredOutput)}');

      // assert
      expect(response.results?.first, isA<ParseObject>());

      expect(parseObject.get<String>("firstName"), "Oliver1");
      expect(parseObject.objectId, "fqx5BECOME");
      expect(parseObject.createdAt, DateTime.parse("2022-10-25T06:04:47.138Z"));
      expect(parseObject.updatedAt, DateTime.parse("2022-10-25T06:05:22.328Z"));

      expect(result.path, '/classes/_User');

      expect(result.query, expectedQuery.query);
    });

    test('wherePolygonContains', () async {
      // arrange
      final QueryBuilder<ParseObject> queryBuilder =
          QueryBuilder<ParseObject>(ParseObject('TEST_SCHEMA', client: client));
      double latitude = 84.17724609375;
      double longitude = -53.69670647530323;
      ParseGeoPoint point =
          ParseGeoPoint(latitude: latitude, longitude: longitude);
      queryBuilder.wherePolygonContains("geometry", point);

      var desiredOutput = {
        "results": [
          {
            "objectId": "eT9muOxBTK",
            "createdAt": "2022-07-25T13:46:06.092Z",
            "updatedAt": "2022-07-25T13:46:23.586Z",
            "geometry": {
              "type": "Polygon",
              "coordinates": [
                [
                  [84.17724609375, -53.69670647530323],
                  [83.1884765625, -54.61025498157913],
                  [84.814453125, -55.14120964449505],
                  [85.67138671875, -54.40614309031968],
                  [84.17724609375, -53.69670647530323]
                ]
              ]
            }
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
      ParseResponse response = await queryBuilder.query();
      ParseObject parseObject = response.results?.first;

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      var queryDesiredOutput = {
        "geometry": {
          "\$geoIntersects": {
            "\$point": {
              "__type": "GeoPoint",
              "latitude": latitude,
              "longitude": longitude
            }
          }
        }
      };
      final Uri expectedQuery =
          Uri(query: 'where=${jsonEncode(queryDesiredOutput)}');

      // assert
      expect(response.results?.first, isA<ParseObject>());
      expect(parseObject.objectId, "eT9muOxBTK");
      expect(parseObject.containsKey("geometry"), true);
      expect(result.path, '/classes/TEST_SCHEMA');
      expect(result.query, expectedQuery.query);
    });

    test(
        'The resulting query should include "redirectClassNameForKey" as a query parameter',
        () {
      // arrange
      final queryBuilder = QueryBuilder.name('Diet_Plans');

      // act
      queryBuilder.setRedirectClassNameForKey('Plan');

      // assert
      final query = queryBuilder.buildQuery();

      expect(query, equals('where={}&redirectClassNameForKey=Plan'));
    });

    test('whereMatchesQuery', () async {
      // arrange
      ParseObject object2 = ParseObject("object2");
      final query2 = QueryBuilder<ParseObject>(object2)
        ..includeObject(["avatar"])
        ..whereEqualTo("firstName", "Oliver1");

      ParseObject object1 = ParseObject("object1");
      final query1 = QueryBuilder<ParseObject>(object1)
        ..includeObject(["user"])
        ..whereEqualTo("id", "1122")
        ..whereMatchesQuery("object2", query2);

      ParseObject objectMain = ParseObject("objectMain", client: client);
      final mainQuery = QueryBuilder<ParseObject>(objectMain)
        ..includeObject(["img"])
        ..whereMatchesQuery("object1", query1);

      var desiredOutput = {
        "results": [
          {
            "className": "_User",
            "objectId": "fqx5BECOME",
            "createdAt": "2022-10-25T06:04:47.138Z",
            "updatedAt": "2022-10-25T06:05:22.328Z",
            "firstName": "Oliver1",
            "lastName": "Smith1",
          },
          {
            "className": "_User",
            "objectId": "hAtRRYGrUO",
            "createdAt": "2022-01-24T15:53:48.396Z",
            "updatedAt": "2022-01-25T05:52:01.701Z",
            "firstName": "Oliver2",
            "lastName": "Smith2",
          },
        ]
      };

      when(client.get(
        any,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).thenAnswer((_) async => ParseNetworkResponse(
          statusCode: 200, data: jsonEncode(desiredOutput)));

      // act
      await mainQuery.query();

      final Uri result = Uri.parse(verify(client.get(
        captureAny,
        options: anyNamed("options"),
        onReceiveProgress: anyNamed("onReceiveProgress"),
      )).captured.single);

      // assert
      expect(result.query.contains("%22object2%22,%22%22include%22"), true);
    });

    test('the result query should contains encoded special characters values',
        () {
      // arrange
      final queryBuilder = QueryBuilder.name('Diet_Plans');

      // act
      queryBuilder.whereEqualTo('some-column', 'some+test=test');
      queryBuilder.whereStartsWith('some-other-column', 'pre+fix');
      queryBuilder.whereEndsWith('some-column2', 'end+with');
      queryBuilder.whereNotEqualTo('some-column3', 'not+equal');
      queryBuilder.whereContains('some-column3', 'WW+E');
      queryBuilder.whereContainsWholeWord(
        'some-column3',
        'Programming++',
        orderByScore: false,
      );

      // assert
      final queryString = queryBuilder.buildQuery();
      const encodedPlusChar = '%2B'; // +
      const encodedEqualChar = '%3D'; // =

      expect(queryString, contains(encodedPlusChar));
      expect(queryString, contains(encodedEqualChar));

      final expectedQueryString = StringBuffer();
      expectedQueryString.writeAll([
        'where={',
        '"some-column": "some${encodedPlusChar}test${encodedEqualChar}test",',
        '"some-other-column":{"\$regex": "^pre${encodedPlusChar}fix", "\$options": "i"},',
        '"some-column2":{"\$regex": "end${encodedPlusChar}with\$", "\$options": "i"},',
        '"some-column3":{ "\$ne":"not${encodedPlusChar}equal"},',
        '"some-column3":{"\$regex": "WW${encodedPlusChar}E", "\$options": "i"},',
        '"some-column3":{"\$text":{"\$search":{"\$term": "Programming$encodedPlusChar$encodedPlusChar", "\$caseSensitive": false , "\$diacriticSensitive": false }}}',
        '}',
      ]);

      expect(queryString, equals(expectedQueryString.toString()));
    });
  });
}
