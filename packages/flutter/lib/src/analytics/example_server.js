// Example analytics server implementation for Parse Dashboard integration
// This demonstrates how to create analytics endpoints that feed data to Parse Dashboard

const express = require('express');
const Parse = require('parse/node');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Parse Server connection
Parse.initialize("YOUR_APP_ID", "YOUR_JAVASCRIPT_KEY", "YOUR_MASTER_KEY");
Parse.serverURL = 'http://localhost:1337/parse';

// Helper function to get date ranges
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
    console.log(`Analytics audience request: ${audienceType}`);
    
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
    // Mock implementation - replace with actual file storage calculation
    res.json({ 
      total: 0.5, // 500MB in GB
      limit: 100,
      units: 'GB'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/apps/:appSlug/billing_database_storage', async (req, res) => {
  try {
    // Mock implementation - replace with actual database size calculation
    res.json({
      total: 0.1, // 100MB in GB
      limit: 20,
      units: 'GB'
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/apps/:appSlug/billing_data_transfer', async (req, res) => {
  try {
    // Mock implementation - replace with actual data transfer calculation
    res.json({
      total: 0.001, // 1GB in TB
      limit: 1,
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
    console.log(`Analytics time series request: ${endpoint}, ${audienceType}, ${stride}`);
    
    const startTime = from ? new Date(parseInt(from) * 1000) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const endTime = to ? new Date(parseInt(to) * 1000) : new Date();
    
    // Generate time series data based on the query
    const requested_data = await generateTimeSeriesData({
      endpoint,
      audienceType, 
      stride,
      from: startTime,
      to: endTime
    });
    
    res.json({ requested_data });
  } catch (error) {
    console.error('Analytics time series error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Analytics Retention Endpoint  
app.get('/apps/:appSlug/analytics_retention', async (req, res) => {
  try {
    const { at } = req.query;
    const timestamp = at ? new Date(parseInt(at) * 1000) : new Date();
    console.log(`Analytics retention request: ${timestamp}`);
    
    // Calculate user retention metrics
    const retention = await calculateUserRetention(timestamp);
    
    res.json(retention);
  } catch (error) {
    console.error('Analytics retention error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Slow Queries Endpoint
app.get('/apps/:appSlug/slow_queries', async (req, res) => {
  try {
    const { className, os, version, from, to } = req.query;
    console.log(`Slow queries request: ${className}, ${os}, ${version}`);
    
    // Mock implementation - replace with actual slow query analysis
    const result = [
      {
        className: className || '_User',
        query: '{"username": {"$regex": ".*"}}',
        duration: 1200,
        count: 5,
        timestamp: new Date().toISOString()
      }
    ];
    
    res.json({ result });
  } catch (error) {
    console.error('Slow queries error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Helper function to generate time series data
async function generateTimeSeriesData(options) {
  const { endpoint, audienceType, stride, from, to } = options;
  
  const data = [];
  const interval = stride === 'day' ? 24 * 60 * 60 * 1000 : 60 * 60 * 1000;
  const current = new Date(from);
  
  while (current <= to) {
    let value = 0;
    const nextPeriod = new Date(current.getTime() + interval);
    
    try {
      switch (endpoint) {
        case 'audience':
          // Get actual user count for this time period
          value = await new Parse.Query(Parse.User)
            .greaterThanOrEqualTo('updatedAt', current)
            .lessThan('updatedAt', nextPeriod)
            .count({ useMasterKey: true });
          break;
          
        case 'installations':
          // Get actual installation count for this time period
          value = await new Parse.Query('_Installation')
            .greaterThanOrEqualTo('updatedAt', current)
            .lessThan('updatedAt', nextPeriod)
            .count({ useMasterKey: true });
          break;
          
        case 'api_request':
          // Mock API request data - replace with actual tracking
          value = Math.floor(Math.random() * 1000) + 100;
          break;
          
        case 'push':
          // Mock push notification data - replace with actual tracking
          value = Math.floor(Math.random() * 50) + 10;
          break;
          
        default:
          value = Math.floor(Math.random() * 100);
      }
    } catch (error) {
      console.error(`Error getting data for ${endpoint}:`, error);
      value = 0;
    }
    
    data.push([current.getTime(), value]);
    current.setTime(current.getTime() + interval);
  }
  
  return data;
}

// Helper function to calculate user retention
async function calculateUserRetention(timestamp) {
  try {
    const cohortStart = new Date(timestamp);
    const cohortEnd = new Date(cohortStart.getTime() + 24 * 60 * 60 * 1000);
    
    // Get users who signed up in the cohort period
    const cohortUsers = await new Parse.Query(Parse.User)
      .greaterThanOrEqualTo('createdAt', cohortStart)
      .lessThan('createdAt', cohortEnd)
      .find({ useMasterKey: true });
    
    if (cohortUsers.length === 0) {
      return { day1: 0, day7: 0, day30: 0 };
    }
    
    const cohortUserIds = cohortUsers.map(user => user.id);
    
    // Calculate retention for different periods
    const day1Retention = await calculateRetentionForPeriod(cohortUserIds, cohortStart, 1);
    const day7Retention = await calculateRetentionForPeriod(cohortUserIds, cohortStart, 7);
    const day30Retention = await calculateRetentionForPeriod(cohortUserIds, cohortStart, 30);
    
    return {
      day1: day1Retention,
      day7: day7Retention,
      day30: day30Retention
    };
  } catch (error) {
    console.error('Error calculating retention:', error);
    return { day1: 0, day7: 0, day30: 0 };
  }
}

// Helper function to calculate retention for a specific period
async function calculateRetentionForPeriod(cohortUserIds, cohortStart, days) {
  try {
    const retentionStart = new Date(cohortStart.getTime() + days * 24 * 60 * 60 * 1000);
    const retentionEnd = new Date(retentionStart.getTime() + 24 * 60 * 60 * 1000);
    
    const activeUsers = await new Parse.Query(Parse.User)
      .containedIn('objectId', cohortUserIds)
      .greaterThanOrEqualTo('updatedAt', retentionStart)
      .lessThan('updatedAt', retentionEnd)
      .find({ useMasterKey: true });
    
    return activeUsers.length / cohortUserIds.length;
  } catch (error) {
    console.error(`Error calculating ${days}-day retention:`, error);
    return 0;
  }
}

// Authentication middleware
app.use('/apps/:appSlug/*', (req, res, next) => {
  const masterKey = req.headers['x-parse-master-key'];
  if (!masterKey || masterKey !== 'YOUR_MASTER_KEY') {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`Parse Dashboard Analytics server running on port ${PORT}`);
  console.log(`Dashboard should be configured to use: http://localhost:${PORT}`);
  console.log('\nExample endpoints:');
  console.log(`  GET /apps/your-app/analytics_content_audience?audienceType=total_users`);
  console.log(`  GET /apps/your-app/analytics?endpoint=audience&stride=day&from=1640995200&to=1641081600`);
  console.log(`  GET /apps/your-app/analytics_retention?at=1640995200`);
  console.log(`  GET /apps/your-app/billing_file_storage`);
  console.log(`  GET /apps/your-app/slow_queries`);
});

module.exports = app;
