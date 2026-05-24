#!/usr/bin/env python3
"""
Incremental dbt seed for PostgreSQL.
Concatenates all processed CSVs into a single shipments.csv seed,
then loads it via dbt seed --full-refresh and runs dbt models.
"""
import os, sys, json, csv, subprocess
from pathlib import Path
from datetime import datetime

SEED_FILE = "logistica_dbt/seeds/shipments.csv"
SEED_STATE = "config/seed_state.json"
PROCESSED_DIR = "data/processed"
DBT_DIR = "logistica_dbt"


def load_state():
    try:
        with open(SEED_STATE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {"last_run": None, "processed_files": [], "total_rows_loaded": 0}


def save_state(state):
    state["last_run"] = datetime.now().isoformat()
    os.makedirs(os.path.dirname(SEED_STATE), exist_ok=True)
    with open(SEED_STATE, "w") as f:
        json.dump(state, f, indent=2)


def build_single_seed():
    all_processed = sorted(Path(PROCESSED_DIR).glob("*_processed.csv"))
    if not all_processed:
        print("No processed files found")
        return 0

    header, total = None, 0
    with open(SEED_FILE, "w", newline="", encoding="utf-8") as out:
        w = csv.writer(out)
        for fp in all_processed:
            with open(fp, newline="", encoding="utf-8") as f:
                r = csv.reader(f)
                h = next(r)
                if header is None:
                    header = h
                    w.writerow(header)
                for row in r:
                    w.writerow(row)
                    total += 1
    print(f"Built shipments.csv: {total} rows from {len(all_processed)} files")
    return total


def run_dbt(*args):
    from dotenv import load_dotenv
    load_dotenv(".env")
    env = os.environ.copy()
    for k in ("POSTGRES_HOST", "POSTGRES_PORT", "POSTGRES_USERNAME",
              "POSTGRES_PASSWORD", "POSTGRES_DBNAME"):
        env[k] = os.getenv(k, "")

    dbt = str(Path(".venv-dbt/Scripts/dbt.exe") if Path(".venv-dbt/Scripts/dbt.exe").exists() else "dbt")
    cmd = [dbt] + list(args) + ["--profiles-dir", "."]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600, env=env, cwd=DBT_DIR)
    for line in (r.stdout + r.stderr).splitlines():
        if any(s in line for s in ("PASS", "FAIL", "ERROR", "Completed",
                                    "Finished", "Done.", "OK created")):
            print(line.strip())
    return r.returncode == 0


def main():
    state = load_state()
    new_files = [str(f) for f in sorted(Path(PROCESSED_DIR).glob("*_processed.csv"))
                 if str(f) not in state["processed_files"]]

    if not new_files:
        print(f"No new files. Last run: {state.get('last_run', 'Never')}")
        return

    print(f"Found {len(new_files)} new file(s)")
    total_rows = build_single_seed()

    print("Seeding shipments to PostgreSQL...")
    if not run_dbt("seed", "--select", "shipments", "--full-refresh"):
        print("dbt seed failed"); return

    for f in new_files:
        state["processed_files"].append(f)
    state["total_rows_loaded"] += total_rows
    save_state(state)

    print("Running dbt models...")
    run_dbt("run")
    print("Running dbt tests...")
    run_dbt("test")


if __name__ == "__main__":
    main()
