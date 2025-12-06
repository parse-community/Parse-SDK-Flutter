# Parse Dashboard Analytics Integration

This guide shows how to integrate Parse Dashboard Analytics into your Flutter app using the Parse SDK Flutter package.

## Features

The Parse Analytics integration provides:

- **User Analytics**: Total users, daily/weekly/monthly active users
- **Installation Analytics**: Device installation tracking and analytics
- **Event Tracking**: Custom event logging with real-time streaming
- **Time Series Data**: Historical data for charts and graphs
- **User Retention**: Cohort analysis and retention metrics
- **Dashboard Integration**: Ready-to-use endpoints for Parse Dashboard
- **Offline Support**: Local event caching for reliable data collection

## Quick Start

### 1. Initialize Analytics

```dart
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Parse SDK
  await Parse().initialize(
    'YOUR_APP_ID',
    'https://your-parse-server.com/parse',
    masterKey: 'YOUR_MASTER_KEY',
    debug: true,
  );
  
  // Initialize Analytics
  await ParseAnalytics.initialize();
  
  runApp(MyApp());
}
```

### 2. Track Events

```dart
// Track simple events
await ParseAnalytics.trackEvent('app_opened');
await ParseAnalytics.trackEvent('button_clicked');

// Track events with parameters
await ParseAnalytics.trackEvent('purchase_completed', {
  'product_id': 'premium_subscription',
  'price': 9.99,
  'currency': 'USD',
});

// Track user journey events
await ParseAnalytics.trackEvent('user_onboarding_step', {
  'step': 'profile_creation',
  'completed': true,
  'time_taken': 45, // seconds
});
```

### 3. Get Analytics Data

```dart
// Get user analytics
final userAnalytics = await ParseAnalytics.getUserAnalytics();
print('Total users: ${userAnalytics['total_users']}');
print('Daily active users: ${userAnalytics['daily_users']}');

// Get installation analytics
final installationAnalytics = await ParseAnalytics.getInstallationAnalytics();
print('Total installations: ${installationAnalytics['total_installations']}');

// Get time series data for charts
final timeSeriesData = await ParseAnalytics.getTimeSeriesData(
  metric: 'users',
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
  interval: 'day',
);

// Get user retention metrics
final retention = await ParseAnalytics.getUserRetention();
print('Day 1 retention: ${(retention['day1']! * 100).toStringAsFixed(1)}%');
print('Day 7 retention: ${(retention['day7']! * 100).toStringAsFixed(1)}%');
print('Day 30 retention: ${(retention['day30']! * 100).toStringAsFixed(1)}%');
```

### 4. Real-time Event Streaming

```dart
class AnalyticsWidget extends StatefulWidget {
  @override
  _AnalyticsWidgetState createState() => _AnalyticsWidgetState();
}

class _AnalyticsWidgetState extends State<AnalyticsWidget> {
  late StreamSubscription _subscription;
  List<Map<String, dynamic>> _recentEvents = [];

  @override
  void initState() {
    super.initState();
    
    // Listen to real-time analytics events
    _subscription = ParseAnalytics.eventsStream?.listen((event) {
      setState(() {
        _recentEvents.insert(0, event);
        if (_recentEvents.length > 10) {
          _recentEvents.removeLast();
        }
      });
    }) ?? const Stream.empty().listen(null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            ParseAnalytics.trackEvent('button_pressed', {
              'timestamp': DateTime.now().toIso8601String(),
            });
          },
          child: Text('Track Event'),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentEvents.length,
            itemBuilder: (context, index) {
              final event = _recentEvents[index];
              return ListTile(
                title: Text(event['event_name']),
                subtitle: Text('${event['parameters']}'),
                trailing: Text(
                  DateTime.fromMillisecondsSinceEpoch(event['timestamp'])
                      .toLocal()
                      .toString()
                      .substring(11, 19),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## Dashboard Integration

### Parse Dashboard Configuration

Add these endpoints to your Parse Dashboard configuration:

```javascript
// dashboard-config.js
const dashboardConfig = {
  "apps": [
    {
      "serverURL": "http://localhost:1337/parse",
      "appId": "YOUR_APP_ID",
      "masterKey": "YOUR_MASTER_KEY",
      "appName": "Your App Name",
      "analytics": {
        "enabled": true,
        "endpoint": "http://localhost:3001" // Your analytics server
      }
    }
  ],
  "users": [
    {
      "user": "admin",
      "pass": "password"
    }
  ],
  "useEncryptedPasswords": true
};

module.exports = dashboardConfig;
```

### Server Implementation

Use the provided example server (`example_server.js`) or integrate the endpoints into your existing server:

```bash
# Copy the example server
cp lib/src/analytics/example_server.js ./analytics-server.js

# Install dependencies
npm install express parse cors

# Configure your credentials
export PARSE_APP_ID="YOUR_APP_ID"
export PARSE_MASTER_KEY="YOUR_MASTER_KEY"
export PARSE_SERVER_URL="http://localhost:1337/parse"

# Run the server
node analytics-server.js
```

### Custom Server Integration

If you have an existing server, you can use the endpoint handlers:

```dart
// For Dart Shelf
import 'package:shelf/shelf.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Response handleAnalyticsRequest(Request request) async {
  final audienceType = request.url.queryParameters['audienceType'];
  
  if (audienceType != null) {
    final result = await ParseAnalyticsEndpoints.handleAudienceRequest(audienceType);
    return Response.ok(json.encode(result));
  }
  
  return Response.badRequest();
}
```

## Advanced Usage

### Custom Event Classes

```dart
class UserEvent {
  final String userId;
  final String action;
  final Map<String, dynamic> context;
  
  UserEvent({required this.userId, required this.action, this.context = const {}});
  
  Future<void> track() async {
    await ParseAnalytics.trackEvent('user_$action', {
      'user_id': userId,
      'action': action,
      ...context,
    });
  }
}

// Usage
final loginEvent = UserEvent(
  userId: 'user_123',
  action: 'login',
  context: {'method': 'email', 'device': 'mobile'},
);
await loginEvent.track();
```

### Analytics Dashboard Widget

```dart
class AnalyticsDashboard extends StatefulWidget {
  @override
  _AnalyticsDashboardState createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  Map<String, dynamic>? userStats;
  Map<String, dynamic>? installationStats;
  Map<String, double>? retentionStats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final results = await Future.wait([
        ParseAnalytics.getUserAnalytics(),
        ParseAnalytics.getInstallationAnalytics(),
        ParseAnalytics.getUserRetention(),
      ]);

      setState(() {
        userStats = results[0] as Map<String, dynamic>;
        installationStats = results[1] as Map<String, dynamic>;
        retentionStats = results[2] as Map<String, double>;
        loading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Analytics', style: Theme.of(context).textTheme.headlineSmall),
          _buildStatsCard('Total Users', userStats?['total_users']),
          _buildStatsCard('Daily Active', userStats?['daily_users']),
          _buildStatsCard('Weekly Active', userStats?['weekly_users']),
          
          SizedBox(height: 20),
          
          Text('Installation Analytics', style: Theme.of(context).textTheme.headlineSmall),
          _buildStatsCard('Total Installations', installationStats?['total_installations']),
          _buildStatsCard('Daily Installations', installationStats?['daily_installations']),
          
          SizedBox(height: 20),
          
          Text('User Retention', style: Theme.of(context).textTheme.headlineSmall),
          _buildStatsCard('Day 1', '${((retentionStats?['day1'] ?? 0) * 100).toStringAsFixed(1)}%'),
          _buildStatsCard('Day 7', '${((retentionStats?['day7'] ?? 0) * 100).toStringAsFixed(1)}%'),
          _buildStatsCard('Day 30', '${((retentionStats?['day30'] ?? 0) * 100).toStringAsFixed(1)}%'),
          
          SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: Text('Refresh Analytics'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String label, dynamic value) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value?.toString() ?? '0',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
```

### Offline Event Management

```dart
class OfflineAnalyticsManager {
  static Future<void> uploadStoredEvents() async {
    try {
      final storedEvents = await ParseAnalytics.getStoredEvents();
      
      if (storedEvents.isEmpty) {
        print('No stored events to upload');
        return;
      }
      
      print('Uploading ${storedEvents.length} stored events...');
      
      // Upload events to your server or process them
      for (final event in storedEvents) {
        // Process each event
        await _processEvent(event);
      }
      
      // Clear stored events after successful upload
      await ParseAnalytics.clearStoredEvents();
      print('Successfully uploaded and cleared stored events');
      
    } catch (e) {
      print('Error uploading stored events: $e');
    }
  }
  
  static Future<void> _processEvent(Map<String, dynamic> event) async {
    // Implement your event processing logic here
    // This could be sending to an external analytics service,
    // logging to a file, or any other processing you need
    
    await Future.delayed(Duration(milliseconds: 100)); // Simulate processing
  }
}

// Usage in your app lifecycle
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Upload stored events when app starts
    OfflineAnalyticsManager.uploadStoredEvents();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ParseAnalytics.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App resumed, upload any stored events
      OfflineAnalyticsManager.uploadStoredEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parse Analytics Demo',
      home: AnalyticsDashboard(),
    );
  }
}
```

## API Reference

### ParseAnalytics Methods

#### Static Methods

- `initialize()` - Initialize the analytics system
- `getUserAnalytics()` - Get comprehensive user analytics
- `getInstallationAnalytics()` - Get installation analytics
- `trackEvent(String eventName, [Map<String, dynamic>? parameters])` - Track custom events
- `getTimeSeriesData({required String metric, required DateTime startDate, required DateTime endDate, String interval = 'day'})` - Get time series data
- `getUserRetention({DateTime? cohortDate})` - Calculate user retention metrics
- `getStoredEvents()` - Get locally stored events
- `clearStoredEvents()` - Clear locally stored events
- `dispose()` - Dispose resources

#### Properties

- `eventsStream` - Stream of real-time analytics events

### ParseAnalyticsEndpoints Methods

#### Static Methods

- `handleAudienceRequest(String audienceType)` - Handle audience analytics requests
- `handleAnalyticsRequest({required String endpoint, required DateTime startDate, required DateTime endDate, String interval = 'day'})` - Handle analytics time series requests
- `handleRetentionRequest({DateTime? cohortDate})` - Handle user retention requests
- `handleBillingStorageRequest()` - Handle billing storage requests
- `handleBillingDatabaseRequest()` - Handle billing database requests
- `handleBillingDataTransferRequest()` - Handle billing data transfer requests
- `handleSlowQueriesRequest({String? className, String? os, String? version, DateTime? from, DateTime? to})` - Handle slow queries requests

## Troubleshooting

### Common Issues

1. **Events not tracking**: Ensure `ParseAnalytics.initialize()` is called before tracking events
2. **Dashboard not showing data**: Verify your analytics server is running and accessible
3. **Compilation errors**: Make sure you're using the latest version of the Parse SDK Flutter
4. **Missing data**: Check that your Parse Server has the required user and installation data

### Debug Mode

Enable debug mode to see detailed logging:

```dart
await Parse().initialize(
  'YOUR_APP_ID',
  'https://your-parse-server.com/parse',
  debug: true, // Enable debug mode
);
```

### Performance Considerations

- Events are cached locally and uploaded in batches
- Analytics queries are optimized for performance
- Consider implementing rate limiting for high-frequency events
- Use background processing for large analytics operations

## Contributing

If you find issues or want to contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This integration follows the same license as the Parse SDK Flutter package.
