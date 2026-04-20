# Data Models

## Staging Layer (`staging/`)
- **`stg_raw_logs.sql`**: Cleans and transforms raw CSV data into structured format
  - Converts timestamp strings to timestamp type
  - Casts numeric fields (status_code, response_time_ms) to integers
  - Maintains all original columns with proper data types

## Marts Layer (`marts/`)
### Fact Tables
- **`fact_log_events.sql`**: Main fact table with enhanced analytics columns
  - Adds time dimensions (event_date, event_hour)
  - Categorizes status codes (success, client_error, server_error, other)
  - Categorizes response times (fast, medium, slow, very_slow)
  - Includes all original log data with calculated fields

### Dimension Tables
- **`dim_endpoints.sql`**: Aggregated endpoint statistics
  - Total requests per endpoint
  - Response time statistics (avg, min, max)
  - Success/error counts and rates
  - Useful for endpoint performance analysis

- **`dim_time_periods.sql`**: Hourly aggregated metrics
  - Request counts per hour
  - Average response times
  - Success/error counts
  - Success rate percentages
  - Useful for time-based trend analysis

## Data Flow
```
CSV Files → stg_raw_logs → fact_log_events
                              ↓
                    dim_endpoints + dim_time_periods
```

## Testing
See `../tests/` directory for data quality tests including:
- Unique log_id validation
- Not null constraints
- Valid status codes (100-599)
- Positive response times

## Column Reference
### Original CSV Columns
- `log_id`: Unique identifier (UUID format)
- `timestamp`: Event timestamp (ISO 8601 format)
- `ip_address`: Client IP address
- `http_method`: HTTP method (GET, POST, PUT, DELETE, etc.)
- `endpoint`: API endpoint path
- `status_code`: HTTP status code (200, 404, 500, etc.)
- `response_time_ms`: Response time in milliseconds
- `user_agent`: Client user agent string

### Calculated Fields (fact_log_events)
- `event_date`: Date portion of timestamp
- `event_hour`: Hour portion of timestamp  
- `status_category`: Categorized status codes
- `response_time_category`: Categorized response times