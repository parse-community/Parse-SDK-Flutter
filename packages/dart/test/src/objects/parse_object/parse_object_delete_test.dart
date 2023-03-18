import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

import '../../../parse_query_test.mocks.dart';
import 'parse_object_test.dart';

void main() {
  group('delete()', () {
    late MockParseClient client;

    late ParseObject dietPlansObject;

    setUp(() async {
      client = MockParseClient();

      await initializeParse();

      dietPlansObject = ParseObject("Diet_Plans", client: client);
    });

    test(
        'delete() should delete object form the server and all the object '
        'data/state should be the same after the deletion', () async {
      // arrange
      dietPlansObject.objectId = "cmWCmCAyQQ";

      dietPlansObject.set('Fat', 15);

      final dietPlansObjectDataBeforeDeletion =
          dietPlansObject.toJson(full: true);

      final deletePath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      final resultFromServer = {};

      when(client.delete(
        deletePath,
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      // act
      final response = await dietPlansObject.delete();

      // assert

      expect(response.success, isTrue);

      expect(response.count, equals(1));

      expect(response.error, isNull);

      expect(response.results, isNotNull);

      expect(response.results, isA<List<ParseObject?>>());

      expect(response.results!.isNotEmpty, isTrue);

      final objectFromResponse = response.results!.first;

      expect(objectFromResponse, isA<ParseObject>());

      expect(identical(objectFromResponse, dietPlansObject), isTrue);

      final dietPlansObjectDataAfterDeletion =
          (objectFromResponse as ParseObject).toJson(full: true);

      expect(
        jsonEncode(dietPlansObjectDataAfterDeletion),
        equals(jsonEncode(dietPlansObjectDataBeforeDeletion)),
      );

      verify(client.delete(
        deletePath,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test('delete() should return error', () async {
      // arrange
      dietPlansObject.objectId = "cmWCmCAyQQ";

      dietPlansObject.set('Fat', 15);

      final dietPlansObjectDataBeforeDeletion =
          dietPlansObject.toJson(full: true);

      final deletePath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/${dietPlansObject.objectId}',
      ).toString();

      final error = Exception('error');

      when(client.delete(
        deletePath,
      )).thenThrow(error);

      // act
      final response = await dietPlansObject.delete();

      // assert
      expect(response.success, isFalse);

      expect(response.result, isNull);

      expect(response.count, isZero);

      expect(response.results, isNull);

      expect(response.error, isNotNull);

      expect(response.error!.exception, equals(error));

      expect(response.error!.code, equals(ParseError.otherCause));

      final dietPlansObjectDataAfterDeletion =
          dietPlansObject.toJson(full: true);

      expect(
        jsonEncode(dietPlansObjectDataAfterDeletion),
        equals(jsonEncode(dietPlansObjectDataBeforeDeletion)),
      );

      verify(client.delete(
        deletePath,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'delete(id: id) should delete object form the server and all the object '
        'data/state should be the same after the deletion using id parameter',
        () async {
      // arrange
      const id = "cmWCmCAyQQ";

      dietPlansObject.set('Fat', 15);

      final dietPlansObjectDataBeforeDeletion =
          dietPlansObject.toJson(full: true);

      final deletePath = Uri.parse(
        '$serverUrl$keyEndPointClasses${dietPlansObject.parseClassName}/$id',
      ).toString();

      final resultFromServer = {};

      when(client.delete(
        deletePath,
      )).thenAnswer(
        (_) async => ParseNetworkResponse(
          statusCode: 200,
          data: jsonEncode(resultFromServer),
        ),
      );

      // act
      final response = await dietPlansObject.delete(id: id);

      // assert

      expect(response.success, isTrue);

      expect(response.count, equals(1));

      expect(response.error, isNull);

      expect(response.results, isNotNull);

      expect(response.results, isA<List<ParseObject?>>());

      expect(response.results!.isNotEmpty, isTrue);

      final objectFromResponse = response.results!.first;

      expect(objectFromResponse, isA<ParseObject>());

      expect(identical(objectFromResponse, dietPlansObject), isTrue);

      final dietPlansObjectDataAfterDeletion =
          (objectFromResponse as ParseObject).toJson(full: true);

      expect(
        jsonEncode(dietPlansObjectDataAfterDeletion),
        equals(jsonEncode(dietPlansObjectDataBeforeDeletion)),
      );

      verify(client.delete(
        deletePath,
      )).called(1);

      verifyNoMoreInteractions(client);
    });

    test(
        'delete() should throw Exception if both objectId and id parameter '
        'is null or empty', () async {
      // arrange
      dietPlansObject.objectId = null;
      String? id;

      // assert
      expect(
        () async => await dietPlansObject.delete(id: id),
        throwsA(isA<Exception>()),
        reason: 'both objectId and id are null',
      );

      dietPlansObject.objectId = '';
      id = '';
      expect(
        () async => await dietPlansObject.delete(id: id),
        throwsA(isA<Exception>()),
        reason: 'both objectId and id are empty',
      );

      verifyZeroInteractions(client);
    });
  });
}
