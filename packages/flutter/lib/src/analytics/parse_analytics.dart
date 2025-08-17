import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

/// Analytics collection utility for Parse Dashboard integration
/// 
/// This class provides methods to collect user, installation, and event data
/// that can be fed to Parse Dashboard analytics endpoints.
class ParseAnalytics {
  static ParseAnalytics? _instance;
  static ParseAnalytics get instance => _instance ??= ParseAnalytics._();
  
  ParseAnalytics._();
  
  final Map<String, dynamic> _cachedMetrics = {};
  final StreamController<AnalyticsEvent> _eventController = 
      StreamController<AnalyticsEvent>.broadcast();
  
  /// Stream of analytics events
  Stream<AnalyticsEvent> get eventStream => _eventController.stream;
  
  /// Track a custom analytics event
  Future<void> trackEvent(String eventName, {
    Map<String, dynamic>? properties,
    String? userId,
    String? installationId,
  }) async {
    try {
      final event = AnalyticsEvent(
        eventName: eventName,
        properties: properties ?? {},
        userId: userId,
        installationId: installationId,
        timestamp: DateTime.now(),
      );
      
      // Store event locally for dashboard consumption
      await _storeEvent(event);
      
      // Emit to stream for real-time tracking
      _eventController.add(event);
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics trackEvent error: $error');
      }
    }
  }
  
  /// Get user analytics overview
  Future<Map<String, int>> getUserAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Get total users  
      final totalUsersQuery = QueryBuilder.name('_User');
      final totalUsers = await totalUsersQuery.count();
      
      // Get active users (updated in date range)
      final activeUsersQuery = QueryBuilder.name('_User')
        ..whereGreaterThanOrEqualTo('updatedAt', start)
        ..whereLessThanOrEqualTo('updatedAt', end);
      final activeUsers = await activeUsersQuery.count();
      
      // Get daily active users (last 24 hours)
      final dailyStart = DateTime.now().subtract(const Duration(hours: 24));
      final dailyUsersQuery = QueryBuilder.name('_User')
        ..whereGreaterThanOrEqualTo('updatedAt', dailyStart);
      final dailyUsers = await dailyUsersQuery.count();
      
      // Get weekly active users (last 7 days)
      final weeklyStart = DateTime.now().subtract(const Duration(days: 7));
      final weeklyUsersQuery = QueryBuilder.name('_User')
        ..whereGreaterThanOrEqualTo('updatedAt', weeklyStart);
      final weeklyUsers = await weeklyUsersQuery.count();
      
      // Get monthly active users (last 30 days)
      final monthlyStart = DateTime.now().subtract(const Duration(days: 30));
      final monthlyUsersQuery = QueryBuilder.name('_User')
        ..whereGreaterThanOrEqualTo('updatedAt', monthlyStart);
      final monthlyUsers = await monthlyUsersQuery.count();
      
      final analytics = {
        'total_users': totalUsers.count ?? 0,
        'active_users': activeUsers.count ?? 0,
        'daily_users': dailyUsers.count ?? 0,
        'weekly_users': weeklyUsers.count ?? 0,
        'monthly_users': monthlyUsers.count ?? 0,
      };
      
      // Cache for dashboard
      _cachedMetrics['user_analytics'] = analytics;
      _cachedMetrics['user_analytics_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      return analytics;
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics getUserAnalytics error: $error');
      }
      return {};
    }
  }
  
  /// Get installation analytics overview
  Future<Map<String, int>> getInstallationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      // Get total installations
      final totalQuery = QueryBuilder.name('_Installation')
        ..setLimit(0);
      final totalInstallations = await totalQuery.count();
      
      // Get active installations (updated in date range)
      final activeQuery = QueryBuilder.name('_Installation')
        ..whereGreaterThanOrEqualTo('updatedAt', start)
        ..whereLessThanOrEqualTo('updatedAt', end)
        ..setLimit(0);
      final activeInstallations = await activeQuery.count();
      
      // Get daily installations
      final dailyStart = DateTime.now().subtract(const Duration(hours: 24));
      final dailyQuery = QueryBuilder.name('_Installation')
        ..whereGreaterThanOrEqualTo('updatedAt', dailyStart)
        ..setLimit(0);
      final dailyInstallations = await dailyQuery.count();
      
      // Get weekly installations
      final weeklyStart = DateTime.now().subtract(const Duration(days: 7));
      final weeklyQuery = QueryBuilder.name('_Installation')
        ..whereGreaterThanOrEqualTo('updatedAt', weeklyStart)
        ..setLimit(0);
      final weeklyInstallations = await weeklyQuery.count();
      
      // Get monthly installations
      final monthlyStart = DateTime.now().subtract(const Duration(days: 30));
      final monthlyQuery = QueryBuilder.name('_Installation')
        ..whereGreaterThanOrEqualTo('updatedAt', monthlyStart)
        ..setLimit(0);
      final monthlyInstallations = await monthlyQuery.count();
      
      final analytics = {
        'total_installations': totalInstallations.count ?? 0,
        'active_installations': activeInstallations.count ?? 0,
        'daily_installations': dailyInstallations.count ?? 0,
        'weekly_installations': weeklyInstallations.count ?? 0,
        'monthly_installations': monthlyInstallations.count ?? 0,
      };
      
      // Cache for dashboard
      _cachedMetrics['installation_analytics'] = analytics;
      _cachedMetrics['installation_analytics_timestamp'] = DateTime.now().millisecondsSinceEpoch;
      
      return analytics;
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics getInstallationAnalytics error: $error');
      }
      return {};
    }
  }
  
  /// Get time series data for dashboard charts
  Future<List<List<dynamic>>> getTimeSeriesData({
    required String metricType,
    required DateTime startDate,
    required DateTime endDate,
    String stride = 'day',
  }) async {
    try {
      final data = <List<dynamic>>[];
      final interval = stride == 'day' 
          ? const Duration(days: 1)
          : const Duration(hours: 1);
      
      DateTime current = startDate;
      while (current.isBefore(endDate)) {
        final nextPeriod = current.add(interval);
        
        int value = 0;
        switch (metricType) {
          case 'active_users':
            final query = QueryBuilder.name('_User')
              ..whereGreaterThanOrEqualTo('updatedAt', current)
              ..whereLessThanOrEqualTo('updatedAt', nextPeriod);
            final result = await query.count();
            value = result.count ?? 0;
            break;
            
          case 'installations':
            final query = QueryBuilder.name('_Installation')
              ..whereGreaterThanOrEqualTo('updatedAt', current)
              ..whereLessThanOrEqualTo('updatedAt', nextPeriod)
              ..setLimit(0);
            final result = await query.count();
            value = result.count ?? 0;
            break;
            
          case 'custom_events':
            // Count custom events from stored analytics events
            value = await _getCustomEventCount(current, nextPeriod);
            break;
        }
        
        data.add([current.millisecondsSinceEpoch, value]);
        current = nextPeriod;
      }
      
      return data;
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics getTimeSeriesData error: $error');
      }
      return [];
    }
  }
  
  /// Get user retention metrics
  Future<Map<String, double>> getUserRetention({DateTime? cohortDate}) async {
    try {
      final cohort = cohortDate ?? DateTime.now().subtract(const Duration(days: 30));
      
      // Get users from the cohort period
      final cohortQuery = QueryBuilder.name('_User')
        ..whereGreaterThanOrEqualTo('createdAt', cohort)
        ..whereLessThanOrEqualTo('createdAt', cohort.add(const Duration(days: 1)));
      final cohortUsersResponse = await cohortQuery.query();
      
      if (!cohortUsersResponse.success || cohortUsersResponse.results == null || cohortUsersResponse.results!.isEmpty) {
        return {'day1': 0.0, 'day7': 0.0, 'day30': 0.0};
      }
      
      final cohortUsers = cohortUsersResponse.results!;
      final cohortUserIds = cohortUsers.map((user) => user.objectId!).toList();
      
      // Calculate retention for day 1, 7, and 30
      final day1Retention = await _calculateRetention(cohortUserIds, cohort, 1);
      final day7Retention = await _calculateRetention(cohortUserIds, cohort, 7);
      final day30Retention = await _calculateRetention(cohortUserIds, cohort, 30);
      
      return {
        'day1': day1Retention,
        'day7': day7Retention,
        'day30': day30Retention,
      };
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics getUserRetention error: $error');
      }
      return {'day1': 0.0, 'day7': 0.0, 'day30': 0.0};
    }
  }
  
  /// Get cached metrics for dashboard endpoints
  Map<String, dynamic> getCachedMetrics(String key) {
    return _cachedMetrics[key] ?? {};
  }
  
  /// Check if cached data is still valid (within 5 minutes)
  bool isCacheValid(String key) {
    final timestamp = _cachedMetrics['${key}_timestamp'];
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheTime).inMinutes < 5;
  }
  
  /// Store analytics event to local storage
  Future<void> _storeEvent(AnalyticsEvent event) async {
    try {
      final coreStore = await CoreStore.getInstance();
      final eventsKey = 'analytics_events';
      
      // Get existing events
      final existingEvents = await coreStore.getStringList(eventsKey) ?? [];
      
      // Add new event
      existingEvents.add(jsonEncode(event.toJson()));
      
      // Keep only last 1000 events to prevent storage bloat
      if (existingEvents.length > 1000) {
        existingEvents.removeRange(0, existingEvents.length - 1000);
      }
      
      // Store back
      await coreStore.setStringList(eventsKey, existingEvents);
      
    } catch (error) {
      if (kDebugMode) {
        print('ParseAnalytics _storeEvent error: $error');
      }
    }
  }
  
  /// Get count of custom events in time range
  Future<int> _getCustomEventCount(DateTime start, DateTime end) async {
    try {
      final coreStore = await CoreStore.getInstance();
      final eventsKey = 'analytics_events';
      final eventStrings = await coreStore.getStringList(eventsKey) ?? [];
      
      int count = 0;
      for (final eventString in eventStrings) {
        try {
          final eventJson = jsonDecode(eventString);
          final eventTime = DateTime.parse(eventJson['timestamp']);
          
          if (eventTime.isAfter(start) && eventTime.isBefore(end)) {
            count++;
          }
        } catch (e) {
          // Skip invalid event data
          continue;
        }
      }
      
      return count;
    } catch (error) {
      return 0;
    }
  }
  
  /// Calculate retention rate for a cohort of users
  Future<double> _calculateRetention(
    List<String> cohortUserIds,
    DateTime cohortDate,
    int days,
  ) async {
    try {
      final retentionDate = cohortDate.add(Duration(days: days));
      final nextDay = retentionDate.add(const Duration(days: 1));
      
      // Find users who were active on the retention date
      final activeQuery = QueryBuilder.name('_User')
        ..whereContainedIn('objectId', cohortUserIds)
        ..whereGreaterThanOrEqualTo('updatedAt', retentionDate)
        ..whereLessThanOrEqualTo('updatedAt', nextDay);
      
      final activeResponse = await activeQuery.query();
      
      if (!activeResponse.success || activeResponse.results == null) {
        return 0.0;
      }
      
      return activeResponse.results!.length / cohortUserIds.length;
      
    } catch (error) {
      return 0.0;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _eventController.close();
  }
}

/// Represents an analytics event
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> properties;
  final String? userId;
  final String? installationId;
  final DateTime timestamp;
  
  AnalyticsEvent({
    required this.eventName,
    required this.properties,
    this.userId,
    this.installationId,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'eventName': eventName,
    'properties': properties,
    'userId': userId,
    'installationId': installationId,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    eventName: json['eventName'],
    properties: Map<String, dynamic>.from(json['properties']),
    userId: json['userId'],
    installationId: json['installationId'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}/// Represents an analytics event
class AnalyticsEvent {
  final String eventName;
  final Map<String, dynamic> properties;
  final String? userId;
  final String? installationId;
  final DateTime timestamp;
  
  AnalyticsEvent({
    required this.eventName,
    required this.properties,
    this.userId,
    this.installationId,
    required this.timestamp,
  });
  
  Map<String, dynamic> toJson() => {
    'eventName': eventName,
    'properties': properties,
    'userId': userId,
    'installationId': installationId,
    'timestamp': timestamp.toIso8601String(),
  };
  
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) => AnalyticsEvent(
    eventName: json['eventName'],
    properties: Map<String, dynamic>.from(json['properties']),
    userId: json['userId'],
    installationId: json['installationId'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
