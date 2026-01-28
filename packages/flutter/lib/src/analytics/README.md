# Parse Dashboard Analytics Integration

This Flutter package provides analytics collection and dashboard integration for the Parse Dashboard Analytics feature.

## Features

- **User Analytics**: Track total, daily, weekly, and monthly active users
- **Installation Analytics**: Monitor app installations and active installations
- **Custom Event Tracking**: Track custom events with properties
- **Time Series Data**: Generate charts and graphs for dashboard visualization
- **User Retention**: Calculate user retention metrics (day 1, 7, and 30)
- **Local Caching**: Efficient caching to reduce server load
- **Dashboard Endpoints**: Ready-to-use endpoints for Parse Dashboard integration

## Usage

### Basic Setup

```dart
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

// Initialize Parse (existing setup)
await Parse().initialize(
  'your_app_id',
  'https://your-parse-server.com/parse',
  clientKey: 'your_client_key',
);

// Start collecting analytics
final analytics = ParseAnalytics.instance;

// Track custom events
await analytics.trackEvent('user_login', properties: {
  'platform': 'mobile',
  'version': '1.0.0',
});

await analytics.trackEvent('level_completed', properties: {
  'level': 5,
  'score': 1500,
  'duration': 120,
});
```

### Getting Analytics Data

```dart
// Get user analytics
final userAnalytics = await analytics.getUserAnalytics();
print('Total users: ${userAnalytics['total_users']}');
print('Daily active users: ${userAnalytics['daily_users']}');

// Get installation analytics
final installationAnalytics = await analytics.getInstallationAnalytics();
print('Total installations: ${installationAnalytics['total_installations']}');

// Get time series data for charts
final timeSeriesData = await analytics.getTimeSeriesData(
  metricType: 'active_users',
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
  stride: 'day',
);

// Get user retention metrics
final retention = await analytics.getUserRetention();
print('Day 1 retention: ${retention['day1']}');
print('Day 7 retention: ${retention['day7']}');
print('Day 30 retention: ${retention['day30']}');
```

### Dashboard Integration

The package provides endpoints that can be integrated with your Parse Server or middleware to feed data to the Parse Dashboard Analytics feature.

#### Express.js Integration Example

```javascript
const express = require('express');
const app = express();

// Import your Parse SDK Flutter analytics (this would be called via FFI or similar)
// For now, this is a conceptual example

app.get('/apps/:appSlug/analytics_content_audience', async (req, res) => {
  const { audienceType, at } = req.query;
  
  // Call Flutter analytics method (implement bridge as needed)
  const result = await callFlutterAnalytics('handleAudienceRequest', {
    audienceType,
    timestamp: at ? parseInt(at) : null
  });
  
  res.json(result);
});

app.get('/apps/:appSlug/billing_file_storage', async (req, res) => {
  const result = await callFlutterAnalytics('handleFileStorageRequest');
  res.json(result);
});

app.get('/apps/:appSlug/billing_database_storage', async (req, res) => {
  const result = await callFlutterAnalytics('handleDatabaseStorageRequest');
  res.json(result);
});

app.get('/apps/:appSlug/billing_data_transfer', async (req, res) => {
  const result = await callFlutterAnalytics('handleDataTransferRequest');
  res.json(result);
});

app.get('/apps/:appSlug/analytics', async (req, res) => {
  const { endpoint, audienceType, stride, from, to } = req.query;
  
  const result = await callFlutterAnalytics('handleAnalyticsRequest', {
    endpoint,
    audienceType,
    stride: stride || 'day',
    from: from ? parseInt(from) : null,
    to: to ? parseInt(to) : null
  });
  
  res.json(result);
});

app.get('/apps/:appSlug/analytics_retention', async (req, res) => {
  const { at } = req.query;
  
  const result = await callFlutterAnalytics('handleRetentionRequest', {
    timestamp: at ? parseInt(at) : null
  });
  
  res.json(result);
});

app.get('/apps/:appSlug/slow_queries', async (req, res) => {
  const { className, os, version, from, to } = req.query;
  
  const result = await callFlutterAnalytics('handleSlowQueriesRequest', {
    className,
    os,
    version,
    from: from ? parseInt(from) : null,
    to: to ? parseInt(to) : null
  });
  
  res.json(result);
});

app.listen(3000, () => {
  console.log('Analytics server running on port 3000');
});
```

#### Pure Dart Server Integration (Shelf)

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

final router = Router();
final analyticsEndpoints = ParseAnalyticsEndpoints.instance;

router.get('/apps/<appSlug>/analytics_content_audience', (Request request, String appSlug) async {
  final audienceType = request.url.queryParameters['audienceType'] ?? '';
  final timestampStr = request.url.queryParameters['at'];
  final timestamp = timestampStr != null ? int.tryParse(timestampStr) : null;
  
  final result = await analyticsEndpoints.handleAudienceRequest(
    audienceType: audienceType,
    timestamp: timestamp,
  );
  
  return Response.ok(
    jsonEncode(result),
    headers: {'content-type': 'application/json'},
  );
});

router.get('/apps/<appSlug>/billing_file_storage', (Request request, String appSlug) async {
  final result = await analyticsEndpoints.handleFileStorageRequest();
  return Response.ok(
    jsonEncode(result),
    headers: {'content-type': 'application/json'},
  );
});

router.get('/apps/<appSlug>/analytics', (Request request, String appSlug) async {
  final params = request.url.queryParameters;
  final result = await analyticsEndpoints.handleAnalyticsRequest(
    endpoint: params['endpoint'] ?? '',
    audienceType: params['audienceType'],
    stride: params['stride'] ?? 'day',
    from: params['from'] != null ? int.tryParse(params['from']!) : null,
    to: params['to'] != null ? int.tryParse(params['to']!) : null,
  );
  
  return Response.ok(
    jsonEncode(result),
    headers: {'content-type': 'application/json'},
  );
});

// Add other endpoints...

void main() async {
  final server = await serve(router, 'localhost', 3000);
  print('Analytics server running on http://localhost:3000');
}
```

### Dashboard Configuration

Configure your Parse Dashboard to connect to your analytics endpoints:

```json
{
  "apps": [
    {
      "serverURL": "http://localhost:1337/parse",
      "appId": "YOUR_APP_ID",
      "masterKey": "YOUR_MASTER_KEY",
      "appName": "Your App Name",
      "analytics": true
    }
  ],
  "analyticsURL": "http://localhost:3000"
}
```

## API Reference

### ParseAnalytics

#### Methods

- `trackEvent(String eventName, {Map<String, dynamic>? properties, String? userId, String? installationId})` - Track a custom event
- `getUserAnalytics({DateTime? startDate, DateTime? endDate})` - Get user analytics overview
- `getInstallationAnalytics({DateTime? startDate, DateTime? endDate})` - Get installation analytics overview
- `getTimeSeriesData({required String metricType, required DateTime startDate, required DateTime endDate, String stride = 'day'})` - Get time series data for charts
- `getUserRetention({DateTime? cohortDate})` - Get user retention metrics
- `getCachedMetrics(String key)` - Get cached analytics data
- `isCacheValid(String key)` - Check if cached data is still valid

### ParseAnalyticsEndpoints

#### Methods

- `handleAudienceRequest({required String audienceType, int? timestamp})` - Handle audience analytics requests
- `handleFileStorageRequest()` - Handle file storage billing requests
- `handleDatabaseStorageRequest()` - Handle database storage billing requests
- `handleDataTransferRequest()` - Handle data transfer billing requests
- `handleAnalyticsRequest({required String endpoint, String? audienceType, String stride = 'day', int? from, int? to})` - Handle time series analytics requests
- `handleRetentionRequest({int? timestamp})` - Handle retention analytics requests
- `handleSlowQueriesRequest({String? className, String? os, String? version, int? from, int? to})` - Handle slow queries requests

## Supported Audience Types

- `total_users` - Total registered users
- `daily_users` - Active users in the last 24 hours
- `weekly_users` - Active users in the last 7 days
- `monthly_users` - Active users in the last 30 days
- `total_installations` - Total app installations
- `daily_installations` - Active installations in the last 24 hours
- `weekly_installations` - Active installations in the last 7 days
- `monthly_installations` - Active installations in the last 30 days

## Supported Metric Types

- `active_users` - User activity over time
- `installations` - Installation activity over time
- `custom_events` - Custom event counts over time

## Requirements

- Flutter SDK
- Parse Server SDK for Dart
- A running Parse Server instance
- Parse Dashboard (for viewing analytics)

## License

This package follows the same license as the Parse SDK Flutter package.
