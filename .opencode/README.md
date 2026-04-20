# Opencode Adaptation for Logistica-ME

## What This Is
Adapted version of the `.claude` memory and tracking system for use with opencode.

## Files Created
1. `.opencode/memory.md` - Project memory and guidelines
2. `.opencode/tokens.md` - Token usage tracking log
3. `.opencode/README.md` - This documentation

## Key Adaptations from Claude Files
- Changed Python paths from Windows (`Scripts/python.exe`) to Unix/Linux (`bin/python`)
- Updated permission references for opencode bash tool usage
- Maintained all critical project information and guidelines
- Preserved token tracking requirement
- Kept dataset schema and business context

## Usage Instructions
1. Always check `.opencode/memory.md` for project guidelines
2. Use `.venv/bin/python` for Python operations (not system python)
3. Track significant operations in `.opencode/tokens.md`
4. Follow security guidelines (don't send full database content online)

## Project Structure Reference
- Root: `/mnt/c/Users/Laurent/OneDrive - 6zmz7p/Portfolio/Logistica-ME`
- Python venv: `.venv/`
- dbt venv: `.venv-dbt/`
- dbt project: `logistica_dbt/`
- Data files: CSV files with `dataset_b3884914-82a8-45c9-9c56-f37e87f45077_*.csv` pattern

## When Working on This Project
- Always activate the virtual environment before Python operations
- Check `.env` exists and contains `API_KEY_DATASET`
- Use incremental token tracking for major operations

## OpenCode Guidelines (Do's and Don'ts)
- **DON'T:** Send full database content for evaluation online
- **DON'T:** never expose .env
- **DO:** Use quick Python script to extract schema + max 5 sample rows only, check if what user is asking is possible
- **Example:** `python -c "import pandas as pd; df = pd.read_csv('file.csv'); print(df.head(5).to_string())"`
- **DO:** check if what user is asking is possible