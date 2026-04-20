# Project Memory - Logistica-ME

## Environment
- **Python venv path:** `.venv/bin/python` (use this for all Python operations)
- **Language:** Python 3.11
- **Use venv for:** ALL Python operations in this project

## Project Files
- **API.py:** Downloads dataset from datamission API incrementally to single CSV (requires .env with API_KEY_DATASET)
- **Dataset file:** `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_full.csv` (single incremental CSV)
- **Old dataset files:** `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_{1..5}.csv` (5 separate files - legacy)
- **Environment:** `.env` (contains API_KEY_DATASET token)
- **read_dataset.py:** Python script to read and process datasets

## Dataset Schema
- log_id (uuid)
- timestamp (datetime)
- ip_address
- http_method (GET, POST, DELETE, etc)
- endpoint
- status_code (200, 400, 500, 401, etc)
- response_time_ms
- user_agent

## Token Usage Tracking
- **Requirement:** Track token usage per session/operation
- **Method:** Report tokens used after significant operations in `.opencode/tokens.md`
- **Note:** New incremental CSV: `dataset_{project_id}_full.csv`. Old format: 5 separate CSV files

## API.py Functionality
- Downloads data from API and appends to single CSV incrementally
- Checks for duplicate log_ids to avoid data duplication
- Uses standard CSV library (no pandas dependency)
- Loads API token from `.env` file without python-dotenv
- Output: `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_full.csv`

## Opencode Guidelines
- **DON'T:** Send full database content for evaluation online
- **DO:** Use Python scripts to extract schema + max 5 sample rows
- **Command:** `.venv/bin/python -c "import pandas as pd; df = pd.read_csv('file.csv'); print(df.head(5).to_string())"`

## Project Notes
- `.venv` created with Python 3.11.9
- `.venv-dbt` for dbt operations
- dbt project: `logistica_dbt/`

## dbt Configuration
- **dbt venv:** `.venv-dbt/bin/dbt`
- **dbt project:** `logistica_dbt/`
- **Download format:** CSV (5 incremental files: dataset_{project_id}_1.csv to _5.csv)

## Git Structure
- Main branch contains project files
- Data files are in root directory
- Source code in `src/` folder
- Tests in `tests/` folder

## Critical Paths
1. API download → CSV files → dbt transformation → analytics
2. Always use `.venv/bin/python` not system python
3. Check `.env` exists with API_KEY_DATASET before running API.py