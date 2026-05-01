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
        "weight_fixes": 0,
        "delay_fixes": 0,
        "id_fixes": 0
    }
    
    # Standardize column names: lowercase and strip
    df.columns = [c.strip().lower() for c in df.columns]
    
    # Expected columns for logistic data
    expected_cols = ['shipment_id', 'timestamp', 'origin', 'destination', 'weight_kg', 'delivery_status', 'vehicle_type', 'estimated_delay_minutes']
    missing_cols = [c for c in expected_cols if c not in df.columns]
    if missing_cols:
        print(f"❌ Missing columns in {raw_file}: {missing_cols}")
        return None
    
    # Clean timestamp: ensure ISO format
    if 'timestamp' in df.columns:
        before = df['timestamp'].copy()
        df['timestamp'] = pd.to_datetime(df['timestamp'], errors='coerce', utc=True).dt.strftime('%Y-%m-%dT%H:%M:%S.%f')
        mask = df['timestamp'].isna()
        df.loc[mask, 'timestamp'] = before[mask]
        cleaning_stats["timestamp_fixes"] = (df['timestamp'] != before).sum()
    
    # Clean weight_kg: convert to float
    if 'weight_kg' in df.columns:
        before = df['weight_kg'].copy()
        df['weight_kg'] = pd.to_numeric(df['weight_kg'], errors='coerce')
        cleaning_stats["weight_fixes"] = df['weight_kg'].notna().sum() - before.notna().sum()
    
    # Clean estimated_delay_minutes: convert to integer
    if 'estimated_delay_minutes' in df.columns:
        before = df['estimated_delay_minutes'].copy()
        df['estimated_delay_minutes'] = pd.to_numeric(df['estimated_delay_minutes'], errors='coerce')
        df['estimated_delay_minutes'] = df['estimated_delay_minutes'].apply(
            lambda x: int(x) if pd.notna(x) else None
        )
        cleaning_stats["delay_fixes"] = df['estimated_delay_minutes'].notna().sum() - before.notna().sum()
    
    # Ensure shipment_id is string and clean
    if 'shipment_id' in df.columns:
        before = df['shipment_id'].copy()
        df['shipment_id'] = df['shipment_id'].astype(str).str.strip()
        cleaning_stats["id_fixes"] = (df['shipment_id'] != before).sum()
    
    # Normalize text fields
    for col in ['origin', 'destination', 'delivery_status', 'vehicle_type']:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip()
    
    # Write processed CSV
    df.to_csv(processed_path, index=False)
    
    print(f"✅ Processed {cleaning_stats['rows_cleaned']} rows")
    print(f"   Timestamp fixes: {cleaning_stats['timestamp_fixes']}")
    print(f"   Weight fixes: {cleaning_stats['weight_fixes']}")
    print(f"   Delay fixes: {cleaning_stats['delay_fixes']}")
    print(f"   ID fixes: {cleaning_stats['id_fixes']}")
    
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
    
    print("\n" + "=" * 60)
    print("🎉 PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   Raw files: {len(raw_files)}")
    print(f"   Processed files: {len(processed_files)}")
    print("\n📋 Next steps:")
    print("   1. Run incremental dbt seed to load new data to PostgreSQL")
    print("      python3 incremental_dbt_seed.py")
    print("   2. Run dbt models")
    print("      cd logistica_dbt && dbt run")
    print("   3. Run data quality tests")
    print("      dbt test")
    print("\n📈 Processed data available in: data/processed/")

if __name__ == "__main__":
    run_full_pipeline()
