# Logistica-ME dbt Project

## Project Structure
```
logistica_dbt/
├── models/
│   ├── staging/
│   │   └── stg_raw_logs.sql      # Clean raw data
│   ├── marts/
│   │   ├── fact_log_events.sql   # Main fact table
│   │   ├── dim_endpoints.sql     # Endpoint statistics
│   │   └── dim_time_periods.sql  # Hourly metrics
│   ├── sources.yml               # Source definitions
│   └── schema.yml               # Model documentation & tests
├── tests/
│   ├── unique_log_id.sql        # Unique constraint test
│   ├── not_null_log_id.sql      # Not null test
│   ├── not_null_timestamp.sql   # Not null test
│   ├── valid_status_code.sql    # Valid range test
│   └── positive_response_time.sql # Positive value test
├── scripts/
│   └── check_csv_files.py       # CSV file checker
├── macros/
│   └── generate_csv_seed.sql    # Seed generation macro
├── analyses/
├── seeds/
├── snapshots/
└── dbt_project.yml
```

## Data Pipeline
1. **CSV Generation**: `API.py` downloads data from API and creates `dataset_{project_id}_{seq_num}.csv`
   - **Automatic Testing**: Each CSV file is tested immediately after download
   - **Conformity Logging**: Test results saved as `{csv_file}_test_results.json`
   - **Overall Summary**: `download_conformity_summary.json` tracks overall conformity percentage
2. **Data Loading**: CSV files loaded as dbt seeds (`raw_logs_{seq_num}`)
3. **Transformation**: 
   - `stg_raw_logs`: Clean and type cast raw data
   - `fact_log_events`: Add analytics columns and categories
   - `dim_endpoints`: Endpoint performance metrics
   - `dim_time_periods`: Time-based aggregations
4. **Testing**: Data quality tests run on transformed data

## Data Import Process
### Step 1: Download and Validate
```bash
python3 API.py
```
**Outputs:**
- 5 CSV files (`dataset_b3884914-82a8-45c9-9c56-f37e87f45077_00001.csv` to `_00005.csv`)
- 5 test result JSON files (`dataset_*_test_results.json`)
- 1 overall conformity summary (`download_conformity_summary.json`)

**Automatic Tests Performed:**
1. ✅ File existence and readability
2. ✅ CSV structure validation (8 columns)
3. ✅ Column names match expected format
4. ✅ Data row count (1000 rows expected)
5. ✅ Human-readable column datatype documentation

**Column Datatypes Validated:**
1. `log_id` (uuid): Unique identifier (UUID format)
2. `timestamp` (iso8601_datetime): Event timestamp in ISO 8601 format
3. `ip_address` (string): Client IP address (IPv4 format)
4. `http_method` (string): HTTP method (GET, POST, PUT, DELETE, etc.)
5. `endpoint` (string): API endpoint path
6. `status_code` (integer): HTTP status code (integer: 200, 404, 500, etc.)
7. `response_time_ms` (integer): Response time in milliseconds (integer)
8. `user_agent` (string): Client user agent string

### Step 2: Check CSV Files
```bash
cd logistica_dbt
python3 scripts/check_csv_files.py
```
Generates dbt seed configuration based on available CSV files.

### Step 3: Load into PostgreSQL
```bash
# Configure dbt for PostgreSQL in profiles.yml
dbt seed --select raw_logs_*
```

### Step 4: Transform Data
```bash
dbt run
```

### Step 5: Validate Data Quality
```bash
dbt test
```

## CSV File Naming Convention
Files follow pattern: `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_{seq_num}.csv`
- `seq_num`: 5-digit sequence number (00001, 00002, ..., 00010)
- Oldest file: `_00001.csv` (lowest number)
- Newest file: Highest sequence number (e.g., `_00015.csv`)

**Important**: Each run of `API.py` downloads 5 new files with sequential numbering. The script automatically determines the next available sequence numbers.

## Data Quality Assurance
### Automatic Testing (Post-Download)
Every CSV file downloaded by `API.py` undergoes immediate validation:
1. **File Structure**: Validates CSV format and column count
2. **Schema Validation**: Checks column names against expected schema
3. **Data Type Documentation**: Provides human-readable column descriptions
4. **Conformity Percentage**: Calculates and logs test success rate
5. **Comprehensive Logging**: JSON files track all test results

### Test Output Files
- `dataset_*_test_results.json`: Individual file test results
- `download_conformity_summary.json`: Overall download session summary
- Human-readable console output with emoji indicators

### Column-Level Validation
Each column is validated with specific datatype expectations:
- **UUID Format**: `log_id` must follow UUID pattern
- **ISO 8601**: `timestamp` must be parseable ISO datetime
- **Integer Validation**: `status_code` and `response_time_ms` must be integers
- **IP Address**: `ip_address` expected to be IPv4 format
- **HTTP Methods**: `http_method` validated against common methods

## Available CSV Files
Current files in project root:
- `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_00001.csv` to `_00010.csv`
- Each contains 1000 rows + header (1001 total lines)

## How to Use

### 1. Download New Data (with Automatic Testing)
```bash
# Run from project root
python3 API.py
```
**What happens:**
- Downloads 5 CSV files from API
- Runs immediate data quality tests on each file
- Generates conformity percentage logs
- Saves detailed test results as JSON
- Outputs human-readable test summaries

### 2. Check CSV Files
```bash
# Run from logistica_dbt/ directory
python3 scripts/check_csv_files.py
```
**What happens:**
- Scans for CSV files in project root
- Validates file naming conventions
- Generates dbt seed configuration
- Provides loading commands for PostgreSQL

### 3. Configure PostgreSQL Connection
Create `~/.dbt/profiles.yml` with PostgreSQL configuration:
```yaml
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: your_username
      pass: your_password
      port: 5432
      dbname: logistica_db
      schema: raw
      threads: 4
```

### 4. Load CSV Files into PostgreSQL
```bash
# Load all CSV files
dbt seed --select raw_logs_*

# Or load specific sequence
dbt seed --select raw_logs_00001
```

### 4. Transform Data
```bash
# Build all models
dbt run

# Build specific model
dbt run --select stg_raw_logs
dbt run --select fact_log_events
dbt run --select dim_endpoints
dbt run --select dim_time_periods
```

### 5. Run Tests
```bash
# Run all tests
dbt test

# Run specific tests
dbt test --select unique_log_id
dbt test --select not_null
```

## Model Dependencies (PostgreSQL)
```
PostgreSQL Database
      ↓
raw_logs_{seq_num} (seeds loaded via dbt seed)
      ↓
  stg_raw_logs (cleans raw data)
      ↓
fact_log_events (enhanced analytics table)
     ├── dim_endpoints (endpoint statistics)
     └── dim_time_periods (time-based aggregations)
```

## PostgreSQL Configuration
### Database Setup
```sql
-- Create database
CREATE DATABASE logistica_db;

-- Create schema for raw data
CREATE SCHEMA IF NOT EXISTS raw;

-- Create schema for analytics
CREATE SCHEMA IF NOT EXISTS analytics;
```

### dbt Profile Configuration
Location: `~/.dbt/profiles.yml`
```yaml
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: postgres  # or your PostgreSQL username
      pass: your_password
      port: 5432
      dbname: logistica_db
      schema: raw      # Default schema for seeds
      threads: 4
      keepalives_idle: 0
      sslmode: prefer
```

### Schema Mapping
- **Seeds (CSV files)**: Loaded into `raw` schema as `raw_logs_{seq_num}`
- **Staging models**: Created in `raw` schema
- **Mart models**: Created in `analytics` schema (configurable in `dbt_project.yml`)

## Data Quality Tests
- **Unique Constraints**: `log_id` must be unique
- **Not Null**: `log_id`, `timestamp`, `status_code`, `response_time_ms` cannot be null
- **Valid Ranges**: `status_code` (100-599), `response_time_ms` (positive)
- **Accepted Values**: `http_method` (GET, POST, PUT, DELETE, etc.)

## Column Transformations
### Raw CSV → stg_raw_logs
- `timestamp` (string) → `event_timestamp` (timestamp)
- `status_code` (string) → `status_code` (integer)
- `response_time_ms` (string) → `response_time_ms` (integer)

### stg_raw_logs → fact_log_events
- Add `event_date`, `event_hour` (time dimensions)
- Add `status_category` (success/client_error/server_error/other)
- Add `response_time_category` (fast/medium/slow/very_slow)

## Analytics Use Cases
- **Endpoint Performance**: Use `dim_endpoints` for endpoint success rates and response times
- **Time Trends**: Use `dim_time_periods` for hourly request patterns
- **Error Analysis**: Use `fact_log_events` with `status_category` for error investigation
- **Slow Requests**: Use `response_time_category` in `fact_log_events` to identify performance issues

## Maintenance
- Run `python3 scripts/check_csv_files.py` periodically to verify CSV file consistency
- Update `API.py` if API endpoint changes
- Add new tests in `tests/` directory as needed
- Update `schema.yml` when adding new columns or models