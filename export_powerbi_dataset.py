#!/usr/bin/env python3
"""
Export final Power BI dataset from PostgreSQL to CSV.

Connects to PostgreSQL, joins fact_shipments with all dimensions,
and exports denormalized CSVs ready for Power BI consumption.
"""

import csv
import os
import sys
from datetime import datetime
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv


def get_conn_params():
    load_dotenv()
    required = ["POSTGRES_HOST", "POSTGRES_PORT", "POSTGRES_DBNAME",
                 "POSTGRES_USERNAME", "POSTGRES_PASSWORD"]
    missing = [k for k in required if not os.getenv(k)]
    if missing:
        print(f"ERROR: Missing env vars: {', '.join(missing)}")
        sys.exit(1)
    return {
        "host": os.getenv("POSTGRES_HOST"),
        "port": os.getenv("POSTGRES_PORT"),
        "dbname": os.getenv("POSTGRES_DBNAME"),
        "user": os.getenv("POSTGRES_USERNAME"),
        "password": os.getenv("POSTGRES_PASSWORD"),
    }


def export_table(query, filepath, conn):
    df = pd.read_sql(query, conn)
    df.to_csv(filepath, index=False, quoting=csv.QUOTE_NONNUMERIC)
    return len(df)


def main():
    params = get_conn_params()

    print("Connecting to PostgreSQL...")
    try:
        import sqlalchemy
        conn_str = (
            f"postgresql://{params['user']}:{params['password']}"
            f"@{params['host']}:{params['port']}/{params['dbname']}"
        )
        engine = sqlalchemy.create_engine(conn_str)
        conn = engine
        use_sqlalchemy = True
    except ImportError:
        import psycopg2
        conn = psycopg2.connect(**params)
        use_sqlalchemy = False

    output_dir = Path("data/powerbi")
    output_dir.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

    fact_query = """
        SELECT
            f.shipment_id,
            f.event_timestamp,
            f.event_date,
            f.event_hour,
            f.weight_kg,
            f.estimated_delay_minutes,
            f.is_on_time,
            f.is_delayed,
            r.origin,
            r.destination,
            r.route_name,
            v.vehicle_type,
            i.delivery_status,
            i.delay_category,
            i.incident_type
        FROM raw.fact_shipments f
        LEFT JOIN raw.dim_routes r ON f.route_id = r.route_id
        LEFT JOIN raw.dim_vehicles v ON f.vehicle_id = v.vehicle_id
        LEFT JOIN raw.dim_incidents i ON f.incident_id = i.incident_id
        ORDER BY f.event_timestamp
    """

    fact_path = output_dir / f"logistica_me_dataset_{timestamp}.csv"
    print("Exporting fact_shipments + dimensions...")
    rows = export_table(fact_query, fact_path, conn)
    print(f"  {rows:,} rows -> {fact_path}")

    risk_tables = {
        "risk_route_analysis": "SELECT * FROM raw.risk_route_analysis ORDER BY risk_score DESC",
        "risk_vehicle_analysis": "SELECT * FROM raw.risk_vehicle_analysis ORDER BY risk_score DESC",
        "risk_temporal_patterns": "SELECT * FROM raw.risk_temporal_patterns ORDER BY pct_delayed DESC",
        "risk_delay_drivers": "SELECT * FROM raw.risk_delay_drivers ORDER BY risk_score DESC",
        "risk_forecast_features": "SELECT * FROM raw.risk_forecast_features ORDER BY event_date DESC",
    }

    print("\nExporting risk analysis tables...")
    for name, query in risk_tables.items():
        try:
            risk_path = output_dir / f"{name}_{timestamp}.csv"
            rows = export_table(query, risk_path, conn)
            print(f"  {name}: {rows:,} rows -> {risk_path}")
        except Exception as e:
            print(f"  {name}: ERROR - {e}")

    if not use_sqlalchemy:
        conn.close()

    print(f"\nDone. All files in: {output_dir.resolve()}")
    print("Import into Power BI: Get Data -> Text/CSV")


if __name__ == "__main__":
    main()
