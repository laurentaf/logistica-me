# Project Memory - Logistica-ME

## Environment
- **Python venv path:** `.venv/` (Windows) or system python3 (Linux)
- **dbt venv path:** `.venv-dbt/bin/dbt` (Linux) or `.venv-dbt/Scripts/dbt.exe` (Windows)
- **Language:** Python 3.12+

## CRITICAL: SECURITY RULES
- **NEVER READ `.env` FILE** - It contains production secrets. Always use `.env.example` to understand the required environment variable schema.
- `.env` contains: `API_KEY_DATASET`, `API_KEY_NVIDIA`, `API_KEY_OPENROUTER`, `POSTGRES_USERNAME`, `POSTGRES_PASSWORD`, `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DBNAME`.
- The schema and valid structure are in `.env.example` - use that file exclusively to understand what env vars are needed.
- **DO NOT** log, output, or echo the contents of `.env` in any command or response.

## Project Structure
- **API.py:** Downloads incremental CSV datasets from DataMission API
- **data_processing_pipeline.py:** Cleans and processes raw CSV data with pandas
- **incremental_dbt_seed.py:** Copies processed files to dbt seeds, runs incremental dbt seed
- **test_e2e_pipeline.py:** Full end-to-end pipeline test (API to process to seed to dbt run to dbt test to DB verify)
- **install_dbt.py:** Installs dbt-core, dbt-postgres, dbt-utils into `.venv-dbt`
- **preview_models.py:** Prints all dbt model schemas without DB connection

## Dataset Schema
- **shipment_id** (uuid): Unique identifier
- **timestamp** (iso8601_datetime): Event timestamp
- **origin** (string): Shipment origin location
- **destination** (string): Shipment destination location
- **weight_kg** (float): Weight of shipment in kilograms
- **delivery_status** (string): Current delivery status
- **vehicle_type** (string): Type of vehicle used
- **estimated_delay_minutes** (integer): Estimated delay in minutes (can be negative)

## Data Flow
1. `API.py` -> `data/raw/` (CSV + metadata JSON + test results JSON)
2. `data_processing_pipeline.py` -> `data/processed/` (processed CSV + cleaning report JSON)
3. `incremental_dbt_seed.py` -> `logistica_dbt/seeds/` (renamed CSVs) -> PostgreSQL (dbt seed)
4. `dbt run` -> PostgreSQL views (staging -> marts models)
5. `dbt test` -> Quality validation

## dbt Configuration
- **dbt venv:** `.venv-dbt/`
- **dbt project:** `logistica_dbt/`
- **Profiles dir:** Project root (uses `--profiles-dir .`)
- **Database:** PostgreSQL (Docker or local)
- **Models:** stg_shipments, fact_shipments, dim_routes, dim_vehicles, dim_incidents, risk_route/vehicle/temporal/delay_drivers/forecast analysis

## Claude Guidelines
- **DON'T:** Read or expose `.env` file contents ever
- **DON'T:** Send secrets, API keys, or database credentials online
- **DO:** Use `.env.example` to understand required environment variables
- **DO:** Use `python3` on Linux, `.venv/Scripts/python.exe` on Windows
- **DO:** Run `test_e2e_pipeline.py` before reporting pipeline health