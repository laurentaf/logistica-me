# Project Memory - Logistica-ME

## Environment
- **Python venv path:** `.venv/Scripts/python.exe` (THIS PROJECT ONLY - always use this)
- **Language:** Python 3.11
- **Use venv for:** ALL Python operations in this project (never system python)

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

## Token Usage Tracking
- **Requirement:** Always track token usage per session/conversation
- **Method:** I (Claude) should report tokens used after every operations in a file 'tokens.md'
- **Note:** Two datasets exist: `dataset.parquet` (10k rows) and `dataset_b388...parquet` (1k rows) - different data

## Project Notes
- `.venv` created by user on 2025-04-12 with Python 3.11.9
