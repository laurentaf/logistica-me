# Industry-Standard Tests Implemented

## Test Categories

### 1. Data Quality Tests
- `valid_ip_address.sql`: Validates IPv4 format and octet ranges
- `valid_timestamp_format.sql`: Ensures timestamps are valid ISO format
- `user_agent_format.sql`: Validates user agent string completeness
- `endpoint_pattern_consistency.sql`: Ensures endpoints follow path patterns

### 2. Referential Integrity Tests
- `foreign_key_integrity.sql`: Validates relationships between fact and staging tables
- `endpoint_referential_integrity.sql`: Ensures dimension endpoints exist in source data

### 3. Business Logic Tests
- `response_time_thresholds.sql`: Flags responses exceeding 10-second SLA
- `anomalous_response_times.sql`: Statistical anomaly detection (3σ outliers)
- `consistency_status_response_time.sql`: Validates successful responses aren't excessively slow

### 4. Completeness Tests
- `data_completeness_endpoints.sql`: Detects low-volume endpoints (<5 requests)
- `missing_timestamp_ranges.sql`: Identifies hours with zero requests

### 5. Data Consistency Tests
- Built-in column tests for not_null, unique, and accepted_values

## Consolidated Test Reporting

A consolidated `test_results` table aggregates all test executions:
- Single table with all test outcomes
- Categorized by test type
- Includes failure counts and pass/fail status
- Timestamped for trend analysis

## Usage

Run all tests:
```bash
dbt test
```

Run tests with consolidated reporting:
```bash
dbt run --model test_results
dbt test
```

View test results in PowerBI:
```sql
SELECT * FROM test_results ORDER BY execution_timestamp DESC;
```

## PowerBI Integration

1. PostgreSQL should run on Windows Server for optimal PowerBI Server compatibility
2. Connect PowerBI to PostgreSQL using native connector
3. Create dashboard with:
   - Test failure trends over time
   - Test category breakdown
   - Top failing tests
   - Data quality scorecard