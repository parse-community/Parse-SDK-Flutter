import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' show ClientException;
import 'package:parse_server_sdk/parse_server_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('buildParseResponseWithException', () {
    test('parses DioException with JSON body', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/'),
        data: json.encode({'error': 'some error', 'code': '123'}),
        statusCode: 400,
        statusMessage: 'Bad Request',
      );

      final dioException = DioException(
        requestOptions: response.requestOptions,
        response: response,
      );

      final result = buildParseResponseWithException(dioException);

      expect(result.error, isNotNull);
      expect(result.error!.message, 'some error');
      expect(result.error!.code, 123);
      expect(result.error!.exception, dioException);
    });

    test('uses statusMessage and statusCode when body is not JSON', () {
      final response = Response(
        requestOptions: RequestOptions(path: '/'),
        data: 'Not a JSON body',
        statusCode: 404,
        statusMessage: 'Not Found',
      );

      final dioException = DioException(
        requestOptions: response.requestOptions,
        response: response,
      );

      final result = buildParseResponseWithException(dioException);

      expect(result.error, isNotNull);
      expect(result.error!.message, 'Not Found');
      expect(result.error!.code, 404);
      expect(result.error!.exception, dioException);
    });

    test('handles http ClientException', () {
      final clientEx = ClientException('no network');

      final result = buildParseResponseWithException(clientEx);

      expect(result.error, isNotNull);
      expect(result.error!.message, 'no network');
      expect(result.error!.exception, clientEx);
    });

    test('handles generic Exception', () {
      final ex = Exception('generic');

      final result = buildParseResponseWithException(ex);

      expect(result.error, isNotNull);
      expect(result.error!.message, ex.toString());
      expect(result.error!.exception, ex);
    });
  });
}
