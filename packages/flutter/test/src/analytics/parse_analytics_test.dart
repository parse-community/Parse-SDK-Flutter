import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, String>{});
    await Parse().initialize(
      'appId',
      'serverUrl',
      clientKey: 'clientKey',
      appName: 'testApp',
      appPackageName: 'com.test.app',
      appVersion: '1.0.0',
      fileDirectory: 'testDirectory',
      debug: true,
    );
  });

  group('ParseAnalytics', () {
    setUp(() async {
      await ParseAnalytics.initialize();
    });

    tearDown(() {
      ParseAnalytics.dispose();
    });

    group('initialize', () {
      test('should initialize without throwing', () async {
        // Act & Assert - should not throw
        await expectLater(ParseAnalytics.initialize(), completes);
      });

      test('should be idempotent - multiple calls should not throw', () async {
        // Act & Assert
        await ParseAnalytics.initialize();
        await ParseAnalytics.initialize();
        await ParseAnalytics.initialize();
        // No exception means success
      });
    });

    group('trackEvent', () {
      test('should track event without parameters', () async {
        // Act & Assert - should not throw
        await expectLater(ParseAnalytics.trackEvent('test_event'), completes);
      });

      test('should track event with parameters', () async {
        // Act & Assert - should not throw
        await expectLater(
          ParseAnalytics.trackEvent('test_event_with_params', {
            'param1': 'value1',
            'param2': 42,
            'param3': true,
          }),
          completes,
        );
      });

      test('should handle empty event name', () async {
        // Act & Assert - should not throw
        await expectLater(ParseAnalytics.trackEvent(''), completes);
      });
    });

    group('eventsStream', () {
      test('should provide events stream after initialize', () async {
        // Arrange
        await ParseAnalytics.initialize();

        // Act
        final stream = ParseAnalytics.eventsStream;

        // Assert
        expect(stream, isNotNull);
        expect(stream, isA<Stream<Map<String, dynamic>>>());
      });
    });

    group('getStoredEvents', () {
      test('should return stored events as list', () async {
        // Track an event first
        await ParseAnalytics.trackEvent('stored_event_test');

        // Act
        final events = await ParseAnalytics.getStoredEvents();

        // Assert
        expect(events, isA<List<Map<String, dynamic>>>());
      });
    });

    group('clearStoredEvents', () {
      test('should clear all stored events', () async {
        // Arrange - store some events
        await ParseAnalytics.trackEvent('event_to_clear_1');
        await ParseAnalytics.trackEvent('event_to_clear_2');

        // Act
        await ParseAnalytics.clearStoredEvents();

        // Assert
        final events = await ParseAnalytics.getStoredEvents();
        expect(events, isEmpty);
      });
    });

    group('dispose', () {
      test('should dispose resources without throwing', () {
        // Act & Assert - should not throw (dispose is synchronous void)
        expect(() => ParseAnalytics.dispose(), returnsNormally);

        // Re-initialize for other tests
        ParseAnalytics.initialize();
      });
    });
  });

  group('AnalyticsEventData', () {
    test('should create with required eventName', () {
      // Act
      final event = AnalyticsEventData(eventName: 'test_event');

      // Assert
      expect(event.eventName, equals('test_event'));
      expect(event.parameters, isEmpty);
      expect(event.timestamp, isNotNull);
    });

    test('should create with all parameters', () {
      // Arrange
      final timestamp = DateTime.now();
      final params = {'key': 'value'};

      // Act
      final event = AnalyticsEventData(
        eventName: 'full_event',
        parameters: params,
        timestamp: timestamp,
        userId: 'user123',
        installationId: 'install456',
      );

      // Assert
      expect(event.eventName, equals('full_event'));
      expect(event.parameters, equals(params));
      expect(event.timestamp, equals(timestamp));
      expect(event.userId, equals('user123'));
      expect(event.installationId, equals('install456'));
    });

    test('should serialize to JSON', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 1, 12, 0, 0);
      final event = AnalyticsEventData(
        eventName: 'json_event',
        parameters: {'amount': 9.99},
        timestamp: timestamp,
        userId: 'user1',
        installationId: 'install1',
      );

      // Act
      final json = event.toJson();

      // Assert
      expect(json['event_name'], equals('json_event'));
      expect(json['parameters'], equals({'amount': 9.99}));
      expect(json['timestamp'], equals(timestamp.millisecondsSinceEpoch));
      expect(json['user_id'], equals('user1'));
      expect(json['installation_id'], equals('install1'));
    });

    test('should deserialize from JSON', () {
      // Arrange
      final timestamp = DateTime(2025, 1, 1, 12, 0, 0);
      final json = {
        'event_name': 'parsed_event',
        'parameters': {'key': 'value'},
        'timestamp': timestamp.millisecondsSinceEpoch,
        'user_id': 'user2',
        'installation_id': 'install2',
      };

      // Act
      final event = AnalyticsEventData.fromJson(json);

      // Assert
      expect(event.eventName, equals('parsed_event'));
      expect(event.parameters, equals({'key': 'value'}));
      expect(
        event.timestamp.millisecondsSinceEpoch,
        equals(timestamp.millisecondsSinceEpoch),
      );
      expect(event.userId, equals('user2'));
      expect(event.installationId, equals('install2'));
    });

    test('should handle null parameters in fromJson', () {
      // Arrange
      final json = {
        'event_name': 'minimal_event',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Act
      final event = AnalyticsEventData.fromJson(json);

      // Assert
      expect(event.eventName, equals('minimal_event'));
      expect(event.parameters, isEmpty);
      expect(event.userId, isNull);
      expect(event.installationId, isNull);
    });
  });
}
