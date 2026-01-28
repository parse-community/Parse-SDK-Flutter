# Parse Dashboard Analytics Integration Guide

This guide shows how to implement the analytics endpoints that feed data to the Parse Dashboard Analytics feature.

## Overview

The Parse Dashboard Analytics expects specific endpoints to be available on your Parse Server or middleware layer. These endpoints provide real-time metrics about your application usage, user engagement, and system performance.

## Required Analytics Endpoints

Based on the dashboard's analytics implementation, here are the endpoints you need to implement:

### 1. Analytics Overview Endpoints

The analytics overview requires these audience and billing metrics:

```javascript
// Base URL pattern: /apps/{appSlug}/analytics_content_audience?at={timestamp}&audienceType={type}

// Audience Types:
- daily_users           // Active users in the last 24 hours
- weekly_users          // Active users in the last 7 days  
- monthly_users         // Active users in the last 30 days
- total_users           // Total registered users
- daily_installations   // Active installations in the last 24 hours
- weekly_installations  // Active installations in the last 7 days
- monthly_installations // Active installations in the last 30 days
- total_installations   // Total installations
```

```javascript
// Billing endpoints:
/apps/{appSlug}/billing_file_storage     // File storage usage in GB
/apps/{appSlug}/billing_database_storage // Database storage usage in GB  
/apps/{appSlug}/billing_data_transfer    // Data transfer usage in TB
```

### 2. Analytics Time Series Endpoint

```javascript
// URL: /apps/{appSlug}/analytics?{query_parameters}
// Supports various event types and time series data
```

### 3. Analytics Retention Endpoint

```javascript
// URL: /apps/{appSlug}/analytics_retention?at={timestamp}
// Returns user retention data
```

### 4. Slow Queries Endpoint

```javascript
// URL: /apps/{appSlug}/slow_queries?{parameters}
// Returns performance metrics for slow database queries
```

## Implementation Example

Here's how to implement these endpoints in your Parse Server or Express middleware:

### Express Middleware Implementation

```javascript
const express = require('express');
const Parse = require('parse/node');

const app = express();

// Helper function to get app slug from request
function getAppSlug(req) {
  return req.params.appSlug || 'default';
}

// Helper function to calculate date ranges
function getDateRange(type) {
  const now = new Date();
  const ranges = {
    daily: new Date(now - 24 * 60 * 60 * 1000),
    weekly: new Date(now - 7 * 24 * 60 * 60 * 1000),
    monthly: new Date(now - 30 * 24 * 60 * 60 * 1000)
  };
  return ranges[type] || new Date(0);
}

// Analytics Overview - Audience Metrics
app.get('/apps/:appSlug/analytics_content_audience', async (req, res) => {
  try {
    const { audienceType, at } = req.query;
    const appSlug = getAppSlug(req);
    
    let result = { total: 0, content: 0 };
    
    switch (audienceType) {
      case 'total_users':
        const totalUsers = await new Parse.Query(Parse.User).count({ useMasterKey: true });
        result = { total: totalUsers, content: totalUsers };
        break;
        
      case 'daily_users':
        const dailyUsers = await new Parse.Query(Parse.User)
          .greaterThan('updatedAt', getDateRange('daily'))
          .count({ useMasterKey: true });
        result = { total: dailyUsers, content: dailyUsers };
        break;
        
      case 'weekly_users':
        const weeklyUsers = await new Parse.Query(Parse.User)
          .greaterThan('updatedAt', getDateRange('weekly'))
          .count({ useMasterKey: true });
        result = { total: weeklyUsers, content: weeklyUsers };
        break;
        
      case 'monthly_users':
        const monthlyUsers = await new Parse.Query(Parse.User)
          .greaterThan('updatedAt', getDateRange('monthly'))
          .count({ useMasterKey: true });
        result = { total: monthlyUsers, content: monthlyUsers };
        break;
        
      case 'total_installations':
        const totalInstallations = await new Parse.Query('_Installation')
          .count({ useMasterKey: true });
        result = { total: totalInstallations, content: totalInstallations };
        break;
        
      case 'daily_installations':
        const dailyInstallations = await new Parse.Query('_Installation')
          .greaterThan('updatedAt', getDateRange('daily'))
          .count({ useMasterKey: true });
        result = { total: dailyInstallations, content: dailyInstallations };
        break;
        
      case 'weekly_installations':
        const weeklyInstallations = await new Parse.Query('_Installation')
          .greaterThan('updatedAt', getDateRange('weekly'))
          .count({ useMasterKey: true });
        result = { total: weeklyInstallations, content: weeklyInstallations };
        break;
        
      case 'monthly_installations':
        const monthlyInstallations = await new Parse.Query('_Installation')
          .greaterThan('updatedAt', getDateRange('monthly'))
          .count({ useMasterKey: true });
        result = { total: monthlyInstallations, content: monthlyInstallations };
        break;
        
      default:
        result = { total: 0, content: 0 };
    }
    
    res.json(result);
  } catch (error) {
    console.error('Analytics audience error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Billing Metrics Endpoints
app.get('/apps/:appSlug/billing_file_storage', async (req, res) => {
  try {
    // Calculate file storage usage in GB
    // This is a simplified example - implement based on your storage system
    const fileStorageQuery = new Parse.Query('_File');
    const files = await fileStorageQuery.find({ useMasterKey: true });
    
    let totalSize = 0;
    for (const file of files) {
      // Estimate file sizes - you may need to track this separately
      totalSize += file.get('size') || 0;
    }
    
    const sizeInGB = totalSize / (1024 * 1024 * 1024);
    res.json({ 
      total: Math.round(sizeInGB * 100) / 100,
      limit: 100, // Your storage limit
      units: 'GB'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/apps/:appSlug/billing_database_storage', async (req, res) => {
  try {
    // Calculate database storage - this is platform-specific
    // For MongoDB, you might query db.stats()
    // This is a mock implementation
    const dbSize = await estimateDatabaseSize();
    const sizeInGB = dbSize / (1024 * 1024 * 1024);
    
    res.json({
      total: Math.round(sizeInGB * 100) / 100,
      limit: 20, // Your database limit
      units: 'GB'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/apps/:appSlug/billing_data_transfer', async (req, res) => {
  try {
    // Calculate data transfer - you'd need to track this in your middleware
    // This is a mock implementation
    res.json({
      total: 0.05, // Example: 50MB in TB
      limit: 1, // 1TB limit
      units: 'TB'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Analytics Time Series Endpoint
app.get('/apps/:appSlug/analytics', async (req, res) => {
  try {
    const { endpoint, audienceType, stride, from, to } = req.query;
    
    // Generate time series data based on the query
    const requested_data = await generateTimeSeriesData({
      endpoint,
      audienceType, 
      stride,
      from: from ? new Date(parseInt(from) * 1000) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
      to: to ? new Date(parseInt(to) * 1000) : new Date()
    });
    
    res.json({ requested_data });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Analytics Retention Endpoint  
app.get('/apps/:appSlug/analytics_retention', async (req, res) => {
  try {
    const { at } = req.query;
    const timestamp = at ? new Date(parseInt(at) * 1000) : new Date();
    
    // Calculate user retention metrics
    const retention = await calculateUserRetention(timestamp);
    
    res.json(retention);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Slow Queries Endpoint
app.get('/apps/:appSlug/slow_queries', async (req, res) => {
  try {
    const { className, os, version, from, to } = req.query;
    
    // Return slow query analytics
    // This would typically come from your Parse Server logs or monitoring
    const result = [];
    
    res.json({ result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Helper Functions
async function estimateDatabaseSize() {
  // Implement based on your database
  // For MongoDB: db.stats().dataSize
  // For PostgreSQL: pg_database_size()
  return 1024 * 1024 * 50; // Mock: 50MB
}

async function generateTimeSeriesData(options) {
  const { endpoint, audienceType, stride, from, to } = options;
  
  // Generate mock time series data
  const data = [];
  const current = new Date(from);
  const interval = stride === 'day' ? 24 * 60 * 60 * 1000 : 60 * 60 * 1000;
  
  while (current <= to) {
    let value = 0;
    
    switch (endpoint) {
      case 'audience':
        value = Math.floor(Math.random() * 1000) + 500; // Mock active users
        break;
      case 'api_request':
        value = Math.floor(Math.random() * 5000) + 1000; // Mock API requests
        break;
      case 'push':
        value = Math.floor(Math.random() * 100) + 10; // Mock push notifications
        break;
      default:
        value = Math.floor(Math.random() * 100);
    }
    
    data.push([current.getTime(), value]);
    current.setTime(current.getTime() + interval);
  }
  
  return data;
}

async function calculateUserRetention(timestamp) {
  // Calculate user retention rates
  // This is a complex calculation based on user activity patterns
  return {
    day1: 0.75,  // 75% return after 1 day
    day7: 0.45,  // 45% return after 7 days  
    day30: 0.25, // 25% return after 30 days
  };
}

module.exports = app;
```

### Parse Server Cloud Code Implementation

You can also implement these as Parse Cloud Functions:

```javascript
// In your Parse Server cloud/main.js

Parse.Cloud.define('getAnalyticsOverview', async (request) => {
  const { audienceType, timestamp } = request.params;
  
  switch (audienceType) {
    case 'total_users':
      return await new Parse.Query(Parse.User).count({ useMasterKey: true });
    case 'daily_users':
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
      return await new Parse.Query(Parse.User)
        .greaterThan('updatedAt', yesterday)
        .count({ useMasterKey: true });
    // Add other cases...
  }
});

// Then call from your middleware:
app.get('/apps/:appSlug/analytics_content_audience', async (req, res) => {
  try {
    const result = await Parse.Cloud.run('getAnalyticsOverview', req.query);
    res.json({ total: result, content: result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

## Dashboard Integration

### Configuration

Make sure your Parse Dashboard is configured to connect to your server with analytics endpoints:

```javascript
// parse-dashboard-config.json
{
  "apps": [
    {
      "serverURL": "http://localhost:1337/parse",
      "appId": "YOUR_APP_ID", 
      "masterKey": "YOUR_MASTER_KEY",
      "appName": "Your App Name",
      "analytics": true // Enable analytics features
    }
  ]
}
```

### Testing Analytics

1. Start your Parse Server with analytics endpoints
2. Start Parse Dashboard
3. Navigate to the Analytics section
4. You should see:
   - Overview metrics (users, installations, billing)
   - Time series charts
   - Retention data
   - Performance metrics

## Advanced Features

### Real-time Analytics

For real-time analytics, consider implementing WebSocket connections or Server-Sent Events:

```javascript
// Real-time analytics updates
const EventEmitter = require('events');
const analyticsEmitter = new EventEmitter();

// Emit events when data changes
Parse.Cloud.afterSave(Parse.User, () => {
  analyticsEmitter.emit('userCountChanged');
});

// Stream to dashboard
app.get('/apps/:appSlug/analytics/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    'Connection': 'keep-alive'
  });
  
  analyticsEmitter.on('userCountChanged', () => {
    res.write('data: {"type": "userCountChanged"}\\n\\n');
  });
});
```

### Custom Analytics

You can extend the analytics with custom metrics:

```javascript
// Track custom events
Parse.Cloud.define('trackAnalyticsEvent', async (request) => {
  const { eventName, properties } = request.params;
  
  const AnalyticsEvent = Parse.Object.extend('AnalyticsEvent');
  const event = new AnalyticsEvent();
  event.set('eventName', eventName);
  event.set('properties', properties);
  event.set('timestamp', new Date());
  
  return await event.save(null, { useMasterKey: true });
});

// Query custom analytics
app.get('/apps/:appSlug/analytics/custom/:eventName', async (req, res) => {
  const { eventName } = req.params;
  const { from, to } = req.query;
  
  const query = new Parse.Query('AnalyticsEvent');
  query.equalTo('eventName', eventName);
  
  if (from) query.greaterThan('timestamp', new Date(parseInt(from) * 1000));
  if (to) query.lessThan('timestamp', new Date(parseInt(to) * 1000));
  
  const events = await query.find({ useMasterKey: true });
  res.json({ events: events.length });
});
```

## Security Considerations

1. **Authentication**: Ensure all analytics endpoints require proper authentication
2. **Rate Limiting**: Implement rate limiting to prevent abuse
3. **Data Privacy**: Only expose aggregated data, never individual user information
4. **CORS**: Configure CORS properly for dashboard access

```javascript
// Example security middleware
const rateLimit = require('express-rate-limit');

const analyticsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/apps/:appSlug/analytics*', analyticsLimiter);

// Authentication middleware
app.use('/apps/:appSlug/analytics*', (req, res, next) => {
  const masterKey = req.headers['x-parse-master-key'];
  if (!masterKey || masterKey !== process.env.PARSE_MASTER_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});
```

## Troubleshooting

### Common Issues

1. **No data in dashboard**: Check that endpoints return proper JSON format
2. **CORS errors**: Ensure your server allows requests from dashboard origin
3. **Performance issues**: Implement caching for expensive queries
4. **Authentication failures**: Verify master key headers

### Debug Mode

Enable debug logging to troubleshoot:

```javascript
// Add debug logging
app.use('/apps/:appSlug/analytics*', (req, res, next) => {
  console.log(`Analytics request: ${req.method} ${req.path}`, {
    query: req.query,
    headers: req.headers
  });
  next();
});
```

This comprehensive guide should help you implement the analytics endpoints needed to feed data to your Parse Dashboard Analytics feature!
