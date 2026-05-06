# NRQL Query Patterns for My Zodiac AI

Proven NRQL queries extracted from the production `create-nr-dashboards.py` script.
Read this file when you need reference queries for a specific domain.

## Table of Contents
1. [APM / Backend Performance](#apm--backend-performance)
2. [AI / LLM Intelligence](#ai--llm-intelligence)
3. [Growth & Users](#growth--users)
4. [Mobile (iOS)](#mobile-ios)
5. [Browser / Frontend](#browser--frontend)
6. [Errors & Health](#errors--health)
7. [MongoDB Performance](#mongodb-performance)
8. [SLI/SLO Templates](#slislo-templates)

---

## APM / Backend Performance

```sql
-- Total requests (24h)
SELECT count(*) FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- Error rate
SELECT percentage(count(*), WHERE error IS true) AS 'Error Rate %'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- Average response time
SELECT average(duration) AS 'Avg (s)'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- P95 response time
SELECT percentile(duration, 95) AS 'P95 (s)'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- Request rate over time
SELECT rate(count(*), 1 minute) AS 'req/min'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' TIMESERIES 30 minutes SINCE 7 days ago

-- Response time percentiles over time
SELECT percentile(duration, 50, 95, 99)
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' TIMESERIES 1 hour SINCE 7 days ago

-- Top endpoints by traffic
SELECT count(*), average(duration), percentile(duration, 95),
       percentage(count(*), WHERE error IS true)
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'
FACET request.uri LIMIT 20 SINCE 7 days ago

-- Slowest endpoints
SELECT count(*), average(duration), max(duration), percentile(duration, 95)
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'
FACET request.uri LIMIT 20 SINCE 7 days ago

-- Errors by endpoint
SELECT count(*) FROM Transaction
WHERE appName = 'My_Zodiac_AI_prod' AND error IS true
FACET request.uri LIMIT 15 SINCE 7 days ago
```

## AI / LLM Intelligence

```sql
-- LLM call count
SELECT count(*) FROM LlmChatCompletionSummary
WHERE appName = 'My_Zodiac_AI_prod' SINCE 7 days ago

-- Total tokens used
SELECT sum(`response.usage.total_tokens`) AS 'Tokens'
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod' SINCE 7 days ago

-- Average LLM duration
SELECT average(duration) AS 'Avg ms'
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod' SINCE 7 days ago

-- Average tokens per call
SELECT average(`response.usage.total_tokens`) AS 'Avg Tokens'
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod' SINCE 7 days ago

-- LLM calls per hour (timeseries)
SELECT count(*) FROM LlmChatCompletionSummary
WHERE appName = 'My_Zodiac_AI_prod' TIMESERIES 1 hour SINCE 7 days ago

-- Prompt vs Completion tokens over time
SELECT sum(`response.usage.prompt_tokens`) AS 'Prompt',
       sum(`response.usage.completion_tokens`) AS 'Completion'
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 1 hour SINCE 7 days ago

-- Stats per model
SELECT count(*) AS 'Calls', average(duration) AS 'Avg ms',
       max(duration) AS 'Max ms',
       sum(`response.usage.total_tokens`) AS 'Total Tokens',
       average(`response.usage.prompt_tokens`) AS 'Avg Prompt',
       average(`response.usage.completion_tokens`) AS 'Avg Completion'
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod'
FACET `request.model` SINCE 7 days ago

-- LLM duration percentiles over time
SELECT percentile(duration, 50, 90, 95, 99)
FROM LlmChatCompletionSummary WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 1 hour SINCE 7 days ago
```

## Growth & Users

```sql
-- Registrations (7d)
SELECT count(*) FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod' SINCE 7 days ago

-- Registrations today
SELECT count(*) FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod' SINCE 1 day ago

-- Daily registrations trend
SELECT count(*) AS 'Registrations' FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod' TIMESERIES 1 day SINCE 30 days ago

-- Registrations by method
SELECT count(*) FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod'
FACET capture(data, r'registrationMethod\":\"(?P<method>[^\"]+)') SINCE 30 days ago

-- Registrations by locale
SELECT count(*) FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod'
FACET capture(data, r'locale\":\"(?P<locale>[^\"]+)') SINCE 30 days ago

-- Registrations by tier
SELECT count(*) FROM user_registered
WHERE appName = 'My_Zodiac_AI_prod'
FACET capture(data, r'tier\":\"(?P<tier>[^\"]+)') SINCE 30 days ago
```

## Mobile (iOS)

```sql
-- Mobile sessions
SELECT uniqueCount(sessionId) AS 'Sessions'
FROM MobileSession WHERE appName = 'MZAI_iOS-ios' SINCE 7 days ago

-- Unique devices
SELECT uniqueCount(deviceUuid) AS 'Devices'
FROM Mobile WHERE appName = 'MZAI_iOS-ios' SINCE 7 days ago

-- Sessions per day trend
SELECT uniqueCount(sessionId) AS 'iOS Sessions'
FROM MobileSession WHERE appName = 'MZAI_iOS-ios'
TIMESERIES 1 day SINCE 30 days ago

-- Users by country
SELECT uniqueCount(deviceUuid) AS 'Users'
FROM Mobile WHERE appName = 'MZAI_iOS-ios'
FACET countryCode LIMIT 20 SINCE 7 days ago

-- iOS version distribution
SELECT uniqueCount(deviceUuid) FROM Mobile
WHERE appName = 'MZAI_iOS-ios' FACET osMajorVersion SINCE 7 days ago

-- App version distribution
SELECT uniqueCount(deviceUuid) FROM Mobile
WHERE appName = 'MZAI_iOS-ios' FACET appVersion SINCE 7 days ago

-- Top interactions
SELECT count(*) AS 'Count', average(interactionDuration) AS 'Avg Duration ms',
       uniqueCount(deviceUuid) AS 'Devices'
FROM Mobile WHERE appName = 'MZAI_iOS-ios'
FACET name LIMIT 20 SINCE 7 days ago
```

## Browser / Frontend

```sql
-- Web sessions
SELECT uniqueCount(session) FROM PageView
WHERE appName = 'MyZodiacFront' SINCE 7 days ago

-- Page views
SELECT count(*) FROM PageView
WHERE appName = 'MyZodiacFront' SINCE 7 days ago

-- Average page load time
SELECT average(duration) FROM PageView
WHERE appName = 'MyZodiacFront' SINCE 7 days ago

-- Core Web Vitals over time
SELECT average(duration) AS 'Page Load',
       average(firstContentfulPaint) AS 'FCP',
       average(backendDuration) AS 'Backend',
       average(domProcessingDuration) AS 'DOM Processing'
FROM PageView WHERE appName = 'MyZodiacFront'
TIMESERIES 1 hour SINCE 7 days ago

-- JS Errors count
SELECT count(*) FROM JavaScriptError
WHERE appName = 'MyZodiacFront' SINCE 24 hours ago

-- Top JS errors
SELECT count(*) FROM JavaScriptError
WHERE appName = 'MyZodiacFront'
FACET errorMessage LIMIT 10 SINCE 7 days ago

-- AJAX errors
SELECT count(*) FROM AjaxRequest
WHERE appName = 'MyZodiacFront' AND httpResponseCode >= 400
FACET httpResponseCode SINCE 7 days ago
```

## Errors & Health

```sql
-- Total errors (24h)
SELECT count(*) FROM TransactionError
WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- Error rate over time
SELECT percentage(count(*), WHERE error IS true) AS 'All Errors %'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 30 minutes SINCE 7 days ago

-- HTTP error codes breakdown
SELECT count(*) FROM Transaction
WHERE appName = 'My_Zodiac_AI_prod' AND httpResponseCode >= 400
FACET httpResponseCode SINCE 7 days ago

-- Slow requests (>5s)
SELECT count(*) FROM Transaction
WHERE appName = 'My_Zodiac_AI_prod' AND duration > 5 SINCE 24 hours ago

-- Error logs
SELECT timestamp, level, message FROM Log
WHERE appName = 'My_Zodiac_AI_prod' AND level IN ('ERROR', 'error')
LIMIT 50 SINCE 24 hours ago

-- NR AI Incidents
SELECT title, priority, state, closedAt
FROM NrAiIssue LIMIT 20 SINCE 7 days ago
```

## MongoDB Performance

```sql
-- Average query duration
SELECT average(mongodb.driver.commands.duration) * 1000 AS 'Avg (ms)'
FROM Metric WHERE appName = 'My_Zodiac_AI_prod' SINCE 24 hours ago

-- Slow queries (>100ms)
SELECT count(*) FROM Metric
WHERE appName = 'My_Zodiac_AI_prod' AND mongodb.driver.commands.duration > 0.1
SINCE 24 hours ago

-- Connection pool: current vs available
SELECT latest(mongodb.connections.current) AS 'In Use',
       latest(mongodb.connections.available) AS 'Available'
FROM Metric WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 5 minutes SINCE 24 hours ago

-- Pool utilization %
SELECT (latest(mongodb.connections.current) /
       (latest(mongodb.connections.current) + latest(mongodb.connections.available))) * 100
       AS 'Utilization %'
FROM Metric WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 5 minutes SINCE 24 hours ago

-- Slowest collections
SELECT average(mongodb.driver.commands.duration) * 1000 AS 'avg ms'
FROM Metric WHERE appName = 'My_Zodiac_AI_prod'
AND mongodb.driver.commands.collectionName IS NOT NULL
FACET mongodb.driver.commands.collectionName LIMIT 10 SINCE 24 hours ago

-- Commands by type
SELECT count(*) FROM Metric
WHERE appName = 'My_Zodiac_AI_prod'
AND mongodb.driver.commands.duration IS NOT NULL
FACET mongodb.driver.commands.commandName SINCE 24 hours ago
```

## SLI/SLO Templates

```sql
-- Availability SLI (target: 99.9%)
SELECT percentage(count(*), WHERE httpResponseCode < 500) AS 'Availability %'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 30 days ago

-- Latency SLI (target: 99% under 1s)
SELECT percentage(count(*), WHERE duration < 1) AS 'Latency SLI %'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 30 days ago

-- Error Budget (availability)
SELECT
  (1 - 0.999) * count(*) AS 'Error Budget (events)',
  filter(count(*), WHERE httpResponseCode >= 500) AS 'Budget Consumed',
  ((1 - 0.999) * count(*) - filter(count(*), WHERE httpResponseCode >= 500)) AS 'Budget Remaining'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod' SINCE 30 days ago

-- SLI % over time (for burn rate chart)
SELECT percentage(count(*), WHERE httpResponseCode < 500) AS 'Availability %'
FROM Transaction WHERE appName = 'My_Zodiac_AI_prod'
TIMESERIES 1 day SINCE 30 days ago
```
