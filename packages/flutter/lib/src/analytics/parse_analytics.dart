import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

/// Analytics collection utility for Parse Dashboard integration
///
/// This class provides methods to collect user, installation, and event data
/// that can be fed to Parse Dashboard analytics endpoints.
class ParseAnalytics {
  static StreamController<Map<String, dynamic>>? _eventController;
  static const String _eventsKey = 'parse_analytics_events';

  /// Initialize the analytics system
  static Future<void> initialize() async {
    _eventController ??= StreamController<Map<String, dynamic>>.broadcast();
  }

  /// Get comprehensive user analytics for Parse Dashboard
  static Future<Map<String, dynamic>> getUserAnalytics() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get user count queries using QueryBuilder
      final totalUsersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery());
      final totalUsersResult = await totalUsersQuery.count();
      final totalUsers = totalUsersResult.count;

      final activeUsersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereGreaterThan('updatedAt', weekAgo);
      final activeUsersResult = await activeUsersQuery.count();
      final activeUsers = activeUsersResult.count;

      final dailyUsersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereGreaterThan('updatedAt', yesterday);
      final dailyUsersResult = await dailyUsersQuery.count();
      final dailyUsers = dailyUsersResult.count;

      final weeklyUsersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereGreaterThan('updatedAt', weekAgo);
      final weeklyUsersResult = await weeklyUsersQuery.count();
      final weeklyUsers = weeklyUsersResult.count;

      final monthlyUsersQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereGreaterThan('updatedAt', monthAgo);
      final monthlyUsersResult = await monthlyUsersQuery.count();
      final monthlyUsers = monthlyUsersResult.count;

      return {
        'timestamp': now.millisecondsSinceEpoch,
        'total_users': totalUsers,
        'active_users': activeUsers,
        'daily_users': dailyUsers,
        'weekly_users': weeklyUsers,
        'monthly_users': monthlyUsers,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user analytics: $e');
      }
      return {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'total_users': 0,
        'active_users': 0,
        'daily_users': 0,
        'weekly_users': 0,
        'monthly_users': 0,
      };
    }
  }

  /// Get installation analytics for Parse Dashboard
  static Future<Map<String, dynamic>> getInstallationAnalytics() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get installation count queries
      final totalInstallationsQuery = QueryBuilder<ParseInstallation>(
        ParseInstallation.forQuery(),
      );
      final totalInstallationsResult = await totalInstallationsQuery.count();
      final totalInstallations = totalInstallationsResult.count;

      final activeInstallationsQuery = QueryBuilder<ParseInstallation>(
        ParseInstallation.forQuery(),
      )..whereGreaterThan('updatedAt', weekAgo);
      final activeInstallationsResult = await activeInstallationsQuery.count();
      final activeInstallations = activeInstallationsResult.count;

      final dailyInstallationsQuery = QueryBuilder<ParseInstallation>(
        ParseInstallation.forQuery(),
      )..whereGreaterThan('updatedAt', yesterday);
      final dailyInstallationsResult = await dailyInstallationsQuery.count();
      final dailyInstallations = dailyInstallationsResult.count;

      final weeklyInstallationsQuery = QueryBuilder<ParseInstallation>(
        ParseInstallation.forQuery(),
      )..whereGreaterThan('updatedAt', weekAgo);
      final weeklyInstallationsResult = await weeklyInstallationsQuery.count();
      final weeklyInstallations = weeklyInstallationsResult.count;

      final monthlyInstallationsQuery = QueryBuilder<ParseInstallation>(
        ParseInstallation.forQuery(),
      )..whereGreaterThan('updatedAt', monthAgo);
      final monthlyInstallationsResult = await monthlyInstallationsQuery
          .count();
      final monthlyInstallations = monthlyInstallationsResult.count;

      return {
        'timestamp': now.millisecondsSinceEpoch,
        'total_installations': totalInstallations,
        'active_installations': activeInstallations,
        'daily_installations': dailyInstallations,
        'weekly_installations': weeklyInstallations,
        'monthly_installations': monthlyInstallations,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting installation analytics: $e');
      }
      return {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'total_installations': 0,
        'active_installations': 0,
        'daily_installations': 0,
        'weekly_installations': 0,
        'monthly_installations': 0,
      };
    }
  }

  /// Track custom events for analytics
  static Future<void> trackEvent(
    String eventName, [
    Map<String, dynamic>? parameters,
  ]) async {
    try {
      await initialize();

      final currentUser = await ParseUser.currentUser();
      final currentInstallation = await ParseInstallation.currentInstallation();

      final event = {
        'event_name': eventName,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user_id': currentUser?.objectId,
        'installation_id': currentInstallation.objectId,
      };

      // Add to stream for real-time tracking
      _eventController?.add(event);

      // Store locally for later upload
      await _storeEventLocally(event);

      if (kDebugMode) {
        print('Analytics event tracked: $eventName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking event: $e');
      }
    }
  }

  /// Get time series data for Parse Dashboard charts
  static Future<List<List<num>>> getTimeSeriesData({
    required String metric,
    required DateTime startDate,
    required DateTime endDate,
    String interval = 'day',
  }) async {
    try {
      final data = <List<num>>[];
      final intervalDuration = interval == 'hour'
          ? const Duration(hours: 1)
          : const Duration(days: 1);

      DateTime current = startDate;
      while (current.isBefore(endDate)) {
        final next = current.add(intervalDuration);
        int value = 0;

        switch (metric) {
          case 'users':
            final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
              ..whereGreaterThan('updatedAt', current)
              ..whereLessThan('updatedAt', next);
            final result = await query.count();
            value = result.count;
            break;

          case 'installations':
            final query =
                QueryBuilder<ParseInstallation>(ParseInstallation.forQuery())
                  ..whereGreaterThan('updatedAt', current)
                  ..whereLessThan('updatedAt', next);
            final result = await query.count();
            value = result.count;
            break;
        }

        data.add([current.millisecondsSinceEpoch, value]);
        current = next;
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting time series data: $e');
      }
      return [];
    }
  }

  /// Calculate user retention metrics
  static Future<Map<String, double>> getUserRetention({
    DateTime? cohortDate,
  }) async {
    try {
      final cohort =
          cohortDate ?? DateTime.now().subtract(const Duration(days: 30));
      final cohortEnd = cohort.add(const Duration(days: 1));

      // Get users who signed up in the cohort period
      final cohortQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereGreaterThan('createdAt', cohort)
        ..whereLessThan('createdAt', cohortEnd);

      final cohortUsers = await cohortQuery.find();
      if (cohortUsers.isEmpty) {
        return {'day1': 0.0, 'day7': 0.0, 'day30': 0.0};
      }

      final cohortUserIds = cohortUsers.map((user) => user.objectId!).toList();

      // Calculate retention
      final day1Retention = await _calculateRetention(cohortUserIds, cohort, 1);
      final day7Retention = await _calculateRetention(cohortUserIds, cohort, 7);
      final day30Retention = await _calculateRetention(
        cohortUserIds,
        cohort,
        30,
      );

      return {
        'day1': day1Retention,
        'day7': day7Retention,
        'day30': day30Retention,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating user retention: $e');
      }
      return {'day1': 0.0, 'day7': 0.0, 'day30': 0.0};
    }
  }

  /// Get stream of real-time analytics events
  static Stream<Map<String, dynamic>>? get eventsStream =>
      _eventController?.stream;

  /// Store event locally for offline support
  static Future<void> _storeEventLocally(Map<String, dynamic> event) async {
    try {
      final coreStore = ParseCoreData().getStore();
      final existingEvents = await coreStore.getStringList(_eventsKey) ?? [];

      existingEvents.add(jsonEncode(event));

      // Keep only last 1000 events
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }

      await coreStore.setStringList(_eventsKey, existingEvents);
    } catch (e) {
      if (kDebugMode) {
        print('Error storing event locally: $e');
      }
    }
  }

  /// Get locally stored events
  static Future<List<Map<String, dynamic>>> getStoredEvents() async {
    try {
      final coreStore = ParseCoreData().getStore();
      final eventStrings = await coreStore.getStringList(_eventsKey) ?? [];

      return eventStrings
          .map((eventString) {
            try {
              return jsonDecode(eventString) as Map<String, dynamic>;
            } catch (e) {
              if (kDebugMode) {
                print('Error parsing stored event: $e');
              }
              return <String, dynamic>{};
            }
          })
          .where((event) => event.isNotEmpty)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting stored events: $e');
      }
      return [];
    }
  }

  /// Clear locally stored events
  static Future<void> clearStoredEvents() async {
    try {
      final coreStore = ParseCoreData().getStore();
      await coreStore.remove(_eventsKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing stored events: $e');
      }
    }
  }

  /// Calculate retention for a specific period
  static Future<double> _calculateRetention(
    List<String> cohortUserIds,
    DateTime cohortStart,
    int days,
  ) async {
    try {
      if (cohortUserIds.isEmpty) return 0.0;

      final retentionDate = cohortStart.add(Duration(days: days));
      final retentionEnd = retentionDate.add(const Duration(days: 1));

      final retentionQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..whereContainedIn('objectId', cohortUserIds)
        ..whereGreaterThan('updatedAt', retentionDate)
        ..whereLessThan('updatedAt', retentionEnd);

      final activeUsers = await retentionQuery.find();

      return activeUsers.length / cohortUserIds.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating retention for day $days: $e');
      }
      return 0.0;
    }
  }

  /// Dispose resources
  static void dispose() {
    _eventController?.close();
    _eventController = null;
  }
}

/// Event model for analytics
class AnalyticsEventData {
  final String eventName;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? userId;
  final String? installationId;

  AnalyticsEventData({
    required this.eventName,
    this.parameters = const {},
    DateTime? timestamp,
    this.userId,
    this.installationId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'event_name': eventName,
    'parameters': parameters,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'user_id': userId,
    'installation_id': installationId,
  };

  factory AnalyticsEventData.fromJson(Map<String, dynamic> json) =>
      AnalyticsEventData(
        eventName: json['event_name'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] as int,
        ),
        userId: json['user_id'] as String?,
        installationId: json['installation_id'] as String?,
      );
}

/* // Initialize analytics
await ParseAnalytics.initialize();

// Track events
await ParseAnalytics.trackEvent('app_opened');
await ParseAnalytics.trackEvent('purchase', {'amount': 9.99});

// Get analytics data
final userStats = await ParseAnalytics.getUserAnalytics();
final retention = await ParseAnalytics.getUserRetention();

// Real-time event streaming
ParseAnalytics.eventsStream?.listen((event) {
  print('New event: ${event['event_name']}');
});*/
