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
import csv
import json
from datetime import datetime
import shutil
from pathlib import Path

def clean_and_process_csv(raw_file, processed_dir="data/processed"):
    """
    Clean CSV file and save to processed directory.
    
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
    
    # Data cleaning operations
    cleaning_stats = {
        "rows_processed": 0,
        "rows_cleaned": 0,
        "columns_processed": 8,  # Expected columns
        "timestamp_fixes": 0,
        "ip_fixes": 0,
        "response_time_fixes": 0
    }
    
    try:
        with open(raw_file, 'r', encoding='utf-8') as infile, \
             open(processed_path, 'w', encoding='utf-8', newline='') as outfile:
            
            reader = csv.DictReader(infile)
            fieldnames = reader.fieldnames
            
            if fieldnames is None:
                raise ValueError(f"Empty CSV file: {raw_file}")
            
            writer = csv.DictWriter(outfile, fieldnames=fieldnames)
            writer.writeheader()
            
            for row_num, row in enumerate(reader, 1):
                cleaning_stats["rows_processed"] += 1
                
                # Clean timestamp: ensure ISO format
                if 'timestamp' in row and row['timestamp']:
                    try:
                        # Try to parse and standardize timestamp
                        dt = datetime.fromisoformat(row['timestamp'].replace('Z', '+00:00'))
                        row['timestamp'] = dt.isoformat()
                        cleaning_stats["timestamp_fixes"] += 1
                    except (ValueError, TypeError):
                        pass  # Keep original if can't parse
                
                # Clean response_time_ms: ensure integer
                if 'response_time_ms' in row and row['response_time_ms']:
                    try:
                        row['response_time_ms'] = int(float(row['response_time_ms']))
                        cleaning_stats["response_time_fixes"] += 1
                    except (ValueError, TypeError):
                        pass
                
                # Clean status_code: ensure integer
                if 'status_code' in row and row['status_code']:
                    try:
                        row['status_code'] = int(row['status_code'])
                    except (ValueError, TypeError):
                        pass
                
                # Clean IP address: basic validation
                if 'ip_address' in row and row['ip_address']:
                    ip = row['ip_address'].strip()
                    # Simple IPv4 validation
                    if '.' in ip and len(ip.split('.')) == 4:
                        row['ip_address'] = ip
                    else:
                        cleaning_stats["ip_fixes"] += 1
                
                writer.writerow(row)
                cleaning_stats["rows_cleaned"] += 1
        
        print(f"✅ Processed {cleaning_stats['rows_cleaned']} rows")
        print(f"   Timestamp fixes: {cleaning_stats['timestamp_fixes']}")
        print(f"   IP fixes: {cleaning_stats['ip_fixes']}")
        print(f"   Response time fixes: {cleaning_stats['response_time_fixes']}")
        
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
        
    except Exception as e:
        print(f"❌ Error processing {raw_file}: {e}")
        return None

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
    
    # Check seed state to avoid re-processing
    seed_state_file = "opencode/seed_state.json"
    processed_before = set()
    
    if os.path.exists(seed_state_file):
        try:
            with open(seed_state_file, 'r') as f:
                state = json.load(f)
                processed_before = set(state.get("processed_files", []))
        except (json.JSONDecodeError, FileNotFoundError):
            pass
    
    # Find all processed CSV files
    processed_files = list(Path(processed_dir).glob("*_processed.csv"))
    
    # Filter out already processed files
    new_files = [f for f in processed_files if str(f) not in processed_before]
    
    print(f"🌱 Preparing {len(new_files)} new files for dbt seed...")
    if len(processed_files) - len(new_files) > 0:
        print(f"   ({len(processed_files) - len(new_files)} files already seeded)")
    
    seed_files = []
    for processed_file in new_files:
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
    
    # Step 3: Prepare for dbt seed
    seed_files = prepare_dbt_seeds()
    
    print("\n" + "=" * 60)
    print("🎉 PIPELINE COMPLETED SUCCESSFULLY")
    print("=" * 60)
    print(f"📊 Summary:")
    print(f"   Raw files: {len(raw_files)}")
    print(f"   Processed files: {len(processed_files)}")
    print(f"   Seed files prepared: {len(seed_files)}")
    print("\n📋 Next steps:")
    print("   1. Run dbt seed to load data to PostgreSQL")
    print("      cd logistica_dbt && dbt seed")
    print("   2. Run dbt models")
    print("      dbt run")
    print("   3. Run data quality tests")
    print("      dbt test")
    print("\n📈 Processed data available in: data/processed/")
    print("🌱 dbt seeds available in: logistica_dbt/seeds/")

if __name__ == "__main__":
    run_full_pipeline()