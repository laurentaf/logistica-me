# Project Memory - Logistica-ME

## Environment
- **Python venv path:** `.venv/Scripts/python.exe`
- **Language:** Python 3.11
- **Use venv for:** All Python operations in this project

## Project Files
- **API.py:** Downloads dataset from datamission API (requires .env with API_KEY_DATASET)
- **Dataset file:** `dataset_b3884914-82a8-45c9-9c56-f37e87f45077.parquet`
- **Environment:** `.env` (contains API_KEY_DATASET token)

## Dataset Schema
- log_id (uuid)
- timestamp (datetime)
- ip_address
- http_method (GET, POST, DELETE, etc)
- endpoint
- status_code (200, 400, 500, 401, etc)
- response_time_ms
- user_agent
