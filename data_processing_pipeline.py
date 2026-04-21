#!/usr/bin/env python3
"""
Data Processing Pipeline for Logística-ME
Steps:
1. Download data via API → data/raw
2. Run consistency tests and clean data
3. Save cleaned data → data/processed  
4. Prepare for dbt seed → PostgreSQL
"""

import os
import json
from datetime import datetime
import shutil
from pathlib import Path
import pandas as pd

def clean_and_process_csv(raw_file, processed_dir="data/processed"):
    """
    Clean CSV file using pandas and save to processed directory.
    
    Args:
        raw_file: Path to raw CSV file
        processed_dir: Directory for processed files
        
    Returns:
        Path to processed file
    """
    # Ensure processed directory exists
    os.makedirs(processed_dir, exist_ok=True)
    
    raw_path = Path(raw_file)
    processed_path = Path(processed_dir) / raw_path.name.replace(".csv", "_processed.csv")
    
    print(f"🔧 Processing: {raw_file} → {processed_path}")
    
    # Read CSV with pandas
    try:
        df = pd.read_csv(raw_file, dtype=str)  # Read everything as string first
    except Exception as e:
        print(f"❌ Error reading {raw_file}: {e}")
        return None
    
    original_rows = len(df)
    cleaning_stats = {
        "rows_processed": original_rows,
        "rows_cleaned": original_rows,
        "columns_processed": len(df.columns),
        "timestamp_fixes": 0,
        "ip_fixes": 0,
        "response_time_fixes": 0,
        "status_code_fixes": 0
    }
    
    # Clean timestamp: ensure ISO format
    if 'timestamp' in df.columns:
        before = df['timestamp'].copy()
        df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce', utc=True).dt.strftime('%Y-%m-%dT%H:%M:%S.%f')
        # Restore NaT (parsing failures) to original
        mask = df['timestamp'].isna()
        df.loc[mask, 'timestamp'] = before[mask]
        cleaning_stats["timestamp_fixes"] = (df['timestamp'] != before).sum()
    
    # Clean response_time_ms: ensure integer
    if 'response_time_ms' in df.columns:
        before = df['response_time_ms'].copy()
        # Convert to numeric, errors='coerce' turns invalid values into NaN
        df['response_time_ms'] = pd.to_numeric(df['response_time_ms'], errors='coerce')
        # Round to integer (floor) and fill NaN with original where conversion failed
        df['response_time_ms'] = df['response_time_ms'].apply(
            lambda x: int(x) if pd.notna(x) else None
        )
        # Count how many were successfully converted to int
        cleaning_stats["response_time_fixes"] = df['response_time_ms'].notna().sum() - before.notna().sum()
    
    # Clean status_code: ensure integer
    if 'status_code' in df.columns:
        before = df['status_code'].copy()
        df['status_code'] = pd.to_numeric(df['status_code'], errors='coerce')
        df['status_code'] = df['status_code'].apply(
            lambda x: int(x) if pd.notna(x) else None
        )
        cleaning_stats["status_code_fixes"] = df['status_code'].notna().sum() - before.notna().sum()
    
    # Clean IP address: basic validation (keep simple IPv4 pattern)
    if 'ip_address' in df.columns:
        before = df['ip_address'].copy()
        # Simple IPv4 pattern: 4 octets of 0-255 separated by dots
        ipv4_pattern = r'^\d{1,3}(\.\d{1,3}){3}$'
        valid_mask = df['ip_address'].str.match(ipv4_pattern, na=False)
        # Replace invalid IPs with None
        df['ip_address'] = df['ip_address'].where(valid_mask, None)
        cleaning_stats["ip_fixes"] = (~valid_mask).sum()
    
    # Write processed CSV (use index=False to avoid extra column)
    df.to_csv(processed_path, index=False)
    
    print(f"✅ Processed {cleaning_stats['rows_cleaned']} rows")
    print(f"   Timestamp fixes: {cleaning_stats['timestamp_fixes']}")
    print(f"   IP fixes: {cleaning_stats['ip_fixes']}")
    print(f"   Response time fixes: {cleaning_stats['response_time_fixes']}")
    print(f"   Status code fixes: {cleaning_stats['status_code_fixes']}")
    
    # Save cleaning report
    report_path = Path(processed_dir) / raw_path.name.replace(".csv", "_cleaning_report.json")
    with open(report_path, 'w', encoding='utf-8') as report_file:
        json.dump({
            "raw_file": str(raw_file),
            "processed_file": str(processed_path),
            "processing_timestamp": datetime.now().isoformat(),
            "cleaning_stats": cleaning_stats
        }, report_file, indent=2)
    
    return str(processed_path)

def prepare_dbt_seeds(processed_dir="data/processed", seeds_dir="logistica_dbt/seeds"):
    """
    Prepare processed files for dbt seed command.
    Only prepares files that haven't been seeded before (incremental).
    
    Args:
        processed_dir: Directory with processed CSV files
        seeds_dir: dbt seeds directory
        
    Returns:
        List of seed files prepared
    """
    os.makedirs(seeds_dir, exist_ok=True)
    
    # Find all processed CSV files
    processed_files = list(Path(processed_dir).glob("*_processed.csv"))
    
    print(f"🌱 Preparing {len(processed_files)} files for dbt seed (copy only)...")
    
    seed_files = []
    for processed_file in processed_files:
        seed_name = processed_file.stem.replace("_processed", "")
        seed_path = Path(seeds_dir) / processed_file.name.replace("_processed", "")
        
        try:
            # Copy processed file to seeds directory
            shutil.copy2(processed_file, seed_path)
            seed_files.append(str(seed_path))
            
            print(f"✅ Prepared seed: {seed_path.name}")
            
        except Exception as e:
            print(f"❌ Error preparing seed {processed_file.name}: {e}")
    
    return seed_files

def run_full_pipeline():
    """Run complete data processing pipeline."""
    print("=" * 60)
    print("🚀 LOGÍSTICA-ME DATA PROCESSING PIPELINE")
    print("=" * 60)
    
    # Step 1: Check for raw data
    raw_files = list(Path("data/raw").glob("dataset_*.csv"))
    
    if not raw_files:
        print("❌ No raw data files found in data/raw/")
        print("   Run API.py first to download data")
        return
    
    print(f"📁 Found {len(raw_files)} raw data files")
    
    # Step 2: Clean and process each file
    processed_files = []
    for raw_file in raw_files:
        processed_file = clean_and_process_csv(raw_file)
        if processed_file:
            processed_files.append(processed_file)
    
    if not processed_files:
        print("❌ No files were processed successfully")
        return
    
    print(f"✅ Successfully processed {len(processed_files)} files")
    
    # Step 3: Prepare for dbt seed (Just copy; incremental_dbt_seed.py manages incremental load)
    seed_files = prepare_dbt_seeds()
    
    print("\n" + "=" * 60)
    print("🎉 PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   Raw files: {len(raw_files)}")
    print(f"   Processed files: {len(processed_files)}")
    print(f"   Seed files prepared: {len(seed_files)}")
    print("\n📋 Next steps:")
    print("   1. Run incremental dbt seed to load new data to PostgreSQL")
    print("      python3 incremental_dbt_seed.py")
    print("   2. Run dbt models")
    print("      cd logistica_dbt && dbt run")
    print("   3. Run data quality tests")
    print("      dbt test")
    print("\n📈 Processed data available in: data/processed/")
    print("🌱 dbt seeds available in: logistica_dbt/seeds/")

if __name__ == "__main__":
    run_full_pipeline()
