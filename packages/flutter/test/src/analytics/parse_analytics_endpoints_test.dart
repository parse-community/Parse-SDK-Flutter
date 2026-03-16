import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, String>{});
    await Parse().initialize(
      'appId',
      'https://test.server.com',
      clientKey: 'clientKey',
      appName: 'testApp',
      appPackageName: 'com.test.app',
      appVersion: '1.0.0',
      fileDirectory: 'testDirectory',
      debug: true,
    );
  });

  group('ParseAnalyticsEndpoints', () {
    group('handleAudienceRequest', () {
      test('should handle total_users request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'total_users',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle daily_users request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'daily_users',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle weekly_users request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'weekly_users',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle monthly_users request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'monthly_users',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle total_installations request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'total_installations',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle daily_installations request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'daily_installations',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle weekly_installations request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'weekly_installations',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should handle monthly_installations request', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'monthly_installations',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('content'), isTrue);
      });

      test('should return zeros for unknown audience type', () async {
        final result = await ParseAnalyticsEndpoints.handleAudienceRequest(
          'unknown_type',
        );

        expect(result['total'], 0);
        expect(result['content'], 0);
      });
    });

    group('handleAnalyticsRequest', () {
      test('should handle audience endpoint', () async {
        final result = await ParseAnalyticsEndpoints.handleAnalyticsRequest(
          endpoint: 'audience',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          interval: 'day',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('requested_data'), isTrue);
      });

      test('should handle installations endpoint', () async {
        final result = await ParseAnalyticsEndpoints.handleAnalyticsRequest(
          endpoint: 'installations',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          interval: 'day',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('requested_data'), isTrue);
      });

      test('should handle custom endpoint', () async {
        final result = await ParseAnalyticsEndpoints.handleAnalyticsRequest(
          endpoint: 'custom_metric',
          startDate: DateTime.now().subtract(const Duration(days: 7)),
          endDate: DateTime.now(),
          interval: 'day',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('requested_data'), isTrue);
      });

      test('should handle hourly interval', () async {
        final result = await ParseAnalyticsEndpoints.handleAnalyticsRequest(
          endpoint: 'audience',
          startDate: DateTime.now().subtract(const Duration(hours: 24)),
          endDate: DateTime.now(),
          interval: 'hour',
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('requested_data'), isTrue);
      });
    });

    group('handleRetentionRequest', () {
      test('should return retention data without cohort date', () async {
        final result = await ParseAnalyticsEndpoints.handleRetentionRequest();

        expect(result, isA<Map<String, double>>());
        expect(result.containsKey('day1'), isTrue);
        expect(result.containsKey('day7'), isTrue);
        expect(result.containsKey('day30'), isTrue);
      });

      test('should return retention data with cohort date', () async {
        final result = await ParseAnalyticsEndpoints.handleRetentionRequest(
          cohortDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        expect(result, isA<Map<String, double>>());
        expect(result.containsKey('day1'), isTrue);
        expect(result.containsKey('day7'), isTrue);
        expect(result.containsKey('day30'), isTrue);
      });
    });

    group('handleBillingStorageRequest', () {
      test('should return storage billing data', () {
        final result = ParseAnalyticsEndpoints.handleBillingStorageRequest();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('limit'), isTrue);
        expect(result.containsKey('units'), isTrue);
        expect(result['units'], 'GB');
      });
    });

    group('handleBillingDatabaseRequest', () {
      test('should return database billing data', () {
        final result = ParseAnalyticsEndpoints.handleBillingDatabaseRequest();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('limit'), isTrue);
        expect(result.containsKey('units'), isTrue);
        expect(result['units'], 'GB');
      });
    });

    group('handleBillingDataTransferRequest', () {
      test('should return data transfer billing data', () {
        final result =
            ParseAnalyticsEndpoints.handleBillingDataTransferRequest();

        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('total'), isTrue);
        expect(result.containsKey('limit'), isTrue);
        expect(result.containsKey('units'), isTrue);
        expect(result['units'], 'TB');
      });
    });

    group('handleSlowQueriesRequest', () {
      test('should return slow queries list without parameters', () {
        final result = ParseAnalyticsEndpoints.handleSlowQueriesRequest();

        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.isNotEmpty, isTrue);
        expect(result.first.containsKey('className'), isTrue);
        expect(result.first.containsKey('query'), isTrue);
        expect(result.first.containsKey('duration'), isTrue);
        expect(result.first.containsKey('count'), isTrue);
        expect(result.first.containsKey('timestamp'), isTrue);
      });

      test('should return slow queries list with className parameter', () {
        final result = ParseAnalyticsEndpoints.handleSlowQueriesRequest(
          className: 'MyCustomClass',
        );

        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.isNotEmpty, isTrue);
        expect(result.first['className'], 'MyCustomClass');
      });

      test('should return slow queries list with all parameters', () {
        final result = ParseAnalyticsEndpoints.handleSlowQueriesRequest(
          className: 'TestClass',
          os: 'iOS',
          version: '1.0.0',
          from: DateTime.now().subtract(const Duration(days: 7)),
          to: DateTime.now(),
        );

        expect(result, isA<List<Map<String, dynamic>>>());
        expect(result.isNotEmpty, isTrue);
      });
    });
  });

  group('getExpressMiddleware', () {
    test('should return middleware code as string', () {
      final middleware = getExpressMiddleware();

      expect(middleware, isA<String>());
      expect(middleware.contains('parseAnalyticsMiddleware'), isTrue);
      expect(middleware.contains('x-parse-master-key'), isTrue);
      expect(middleware.contains('analytics_content_audience'), isTrue);
    });
  });

  group('getDartShelfHandler', () {
    test('should return Dart Shelf handler code as string', () {
      final handler = getDartShelfHandler();

      expect(handler, isA<String>());
      expect(handler.contains('getDartShelfHandler'), isTrue);
      expect(handler.contains('x-parse-master-key'), isTrue);
      expect(handler.contains('analytics_content_audience'), isTrue);
      expect(handler.contains('analytics_retention'), isTrue);
      expect(handler.contains('Response.notFound'), isTrue);
    });

    test('should contain shelf imports', () {
      final handler = getDartShelfHandler();

      expect(handler.contains("import 'dart:convert'"), isTrue);
      expect(handler.contains("import 'package:shelf/shelf.dart'"), isTrue);
    });
  });
}
