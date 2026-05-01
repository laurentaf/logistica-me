#!/usr/bin/env python3
"""
End-to-End Pipeline Test
Executa todo o fluxo de dados desde a API até os modelos dbt,
reportando o sucesso/falha de cada etapa.
"""

import os
import sys
import subprocess
import time
from datetime import datetime
from pathlib import Path

class colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

def run_command(cmd, cwd=None, description=""):
    """Execute a command and return success status, stdout, stderr."""
    print(f"\n{colors.BLUE}▶ {description}{colors.END}")
    print(f"  Command: {cmd}")
    start = time.time()
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            cwd=cwd,
            timeout=300  # 5 min timeout
        )
        elapsed = time.time() - start
        if result.returncode == 0:
            print(f"  {colors.GREEN}✓ SUCCESS{colors.END} ({elapsed:.1f}s)")
            if result.stdout and len(result.stdout) > 500:
                print(f"  Output: [truncated - {len(result.stdout)} chars total]")
            elif result.stdout:
                print(f"  Output: {result.stdout.strip()}")
            return True, result.stdout, result.stderr
        else:
            print(f"  {colors.RED}✗ FAILED{colors.END} ({elapsed:.1f}s)")
            print(f"  Error: {result.stderr.strip()}")
            return False, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        print(f"  {colors.RED}✗ TIMEOUT{colors.END} ({elapsed:.1f}s)")
        return False, "", "Command timed out"
    except Exception as e:
        print(f"  {colors.RED}✗ ERROR: {e}{colors.END}")
        return False, "", str(e)

def check_dependencies():
    """Check if required tools are installed."""
    print(f"\n{colors.BOLD}🔍 Checking Dependencies{colors.END}")
    deps = {
        'python3': 'Python 3 interpreter',
        'dbt': 'dbt CLI',
        'psql': 'PostgreSQL client'
    }
    missing = []
    for cmd, desc in deps.items():
        try:
            subprocess.run([cmd, '--version'], capture_output=True, timeout=5)
            print(f"  {colors.GREEN}✓{colors.END} {desc} ({cmd})")
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"  {colors.RED}✗{colors.END} {desc} ({cmd}) - MISSING")
            missing.append(cmd)
    
    if missing:
        print(f"\n{colors.RED}❌ Missing dependencies: {', '.join(missing)}{colors.END}")
        print("Install before running pipeline.")
        return False
    return True

def main():
    print("=" * 80)
    print(f"{colors.BOLD}🚀 LOGISTICA-ME END-TO-END PIPELINE TEST{colors.END}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    
    results = []
    
    # Step 0: Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Step 1: Download from API
    success, stdout, stderr = run_command(
        "python3 API.py --count 1",
        description="Step 1: Download data from API"
    )
    results.append(("API Download", success))
    
    if not success:
        print(f"\n{colors.RED}❌ Pipeline failed at Step 1. Aborting.{colors.END}")
        sys.exit(1)
    
    # Verify raw files exist
    raw_files = list(Path("data/raw").glob("dataset_*.csv"))
    if raw_files:
        print(f"  📁 {len(raw_files)} raw file(s) downloaded")
        for f in raw_files[-1:]:
            print(f"     Latest: {f.name}")
    else:
        print(f"  {colors.YELLOW}⚠️  No raw files found{colors.END}")
    
    # Step 2: Process and clean data
    success, stdout, stderr = run_command(
        "python3 data_processing_pipeline.py",
        description="Step 2: Process and clean data"
    )
    results.append(("Data Processing", success))
    
    if not success:
        print(f"\n{colors.RED}❌ Pipeline failed at Step 2. Aborting.{colors.END}")
        sys.exit(1)
    
    # Verify processed files exist
    processed_files = list(Path("data/processed").glob("*_processed.csv"))
    if processed_files:
        print(f"  📁 {len(processed_files)} processed file(s) created")
    else:
        print(f"  {colors.YELLOW}⚠️  No processed files found{colors.END}")
    
    # Step 3: Incremental dbt seed
    success, stdout, stderr = run_command(
        "python3 incremental_dbt_seed.py",
        description="Step 3: Load data to PostgreSQL (dbt seed)"
    )
    results.append(("dbt Seed", success))
    
    if not success:
        print(f"\n{colors.RED}❌ Pipeline failed at Step 3. Aborting.{colors.END}")
        sys.exit(1)
    
    # Step 4: dbt run (transform models)
    success, stdout, stderr = run_command(
        "dbt run --profiles-dir .",
        cwd="logistica_dbt",
        description="Step 4: Run dbt models (staging → marts)"
    )
    results.append(("dbt Run", success))
    
    # Parse output to see which models succeeded
    if success:
        # Count lines with "OK" or "PASS"
        ok_count = stdout.count("OK") + stdout.count("PASS")
        print(f"  📊 Models executed successfully: {ok_count} references found")
    else:
        print(f"  {colors.RED}Some models failed{colors.END}")
    
    # Step 5: dbt test (quality checks)
    success, stdout, stderr = run_command(
        "dbt test --profiles-dir .",
        cwd="logistica_dbt",
        description="Step 5: Run dbt tests"
    )
    results.append(("dbt Test", success))
    
    # Parse test results summary
    if success:
        # Look for pass/fail summary
        if "PASS" in stdout or "All tests passed" in stdout:
            test_summary = "✅ Tests passed"
            print(f"  {test_summary}")
        else:
            print(f"  {colors.YELLOW}⚠️  Tests completed but check output for failures{colors.END}")
    else:
        print(f"  {colors.RED}Some tests failed{colors.END}")
    
    # Step 6: Verify tables in database
    print(f"\n{colors.BOLD}🔍 Step 6: Verifying database tables{colors.END}")
    try:
        import psycopg2
        from dotenv import load_dotenv
        import os
        
        load_dotenv()
        conn = psycopg2.connect(
            host=os.getenv('POSTGRES_HOST', 'localhost'),
            port=os.getenv('POSTGRES_PORT', '5432'),
            database=os.getenv('POSTGRES_DBNAME', 'logistica_db'),
            user=os.getenv('POSTGRES_USERNAME', 'postgres'),
            password=os.getenv('POSTGRES_PASSWORD', '')
        )
        cur = conn.cursor()
        
        tables_to_check = [
            'stg_shipments',
            'dim_routes', 
            'dim_vehicles',
            'dim_incidents',
            'fact_shipments',
            'risk_route_analysis',
            'risk_vehicle_analysis',
            'risk_temporal_patterns',
            'risk_delay_drivers',
            'risk_forecast_features',
            'test_registry'
        ]
        
        existing_tables = []
        missing_tables = []
        
        for table in tables_to_check:
            cur.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = %s
                )
            """, (table,))
            exists = cur.fetchone()[0]
            if exists:
                existing_tables.append(table)
                print(f"  {colors.GREEN}✓{colors.END} {table}")
            else:
                missing_tables.append(table)
                print(f"  {colors.RED}✗{colors.END} {table} (MISSING)")
        
        # Check row counts for key tables
        print(f"\n  📊 Row counts (sample):")
        for table in ['fact_shipments', 'risk_route_analysis']:
            if table in existing_tables:
                cur.execute(f"SELECT COUNT(*) FROM {table}")
                count = cur.fetchone()[0]
                print(f"    {table}: {count:,} rows")
        
        cur.close()
        conn.close()
        
        results.append(("Database Tables", len(missing_tables) == 0))
        
    except Exception as e:
        print(f"  {colors.YELLOW}⚠️  Could not verify database: {e}{colors.END}")
        results.append(("Database Tables", False))
    
    # Summary
    print("\n" + "=" * 80)
    print(f"{colors.BOLD}📋 PIPELINE EXECUTION SUMMARY{colors.END}")
    print("=" * 80)
    
    all_passed = True
    for step, success in results:
        status = f"{colors.GREEN}✓ PASS{colors.END}" if success else f"{colors.RED}✗ FAIL{colors.END}"
        print(f"  {status} - {step}")
        if not success:
            all_passed = False
    
    print("=" * 80)
    if all_passed:
        print(f"{colors.GREEN}{colors.BOLD}🎉 ALL STEPS COMPLETED SUCCESSFULLY!{colors.END}")
        print(f"\nThe pipeline is working end-to-end. Data flows from API → processed files → PostgreSQL → dbt models.")
    else:
        print(f"{colors.RED}{colors.BOLD}❌ PIPELINE FAILED{colors.END}")
        print(f"\nSome steps did not complete successfully. Review errors above.")
        sys.exit(1)
    
    print(f"\n{colors.BOLD}⏱️  Total execution time: {time.time():.1f}s{colors.END}")
    print("=" * 80)

if __name__ == "__main__":
    main()
