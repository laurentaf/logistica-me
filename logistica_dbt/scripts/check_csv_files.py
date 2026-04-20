#!/usr/bin/env python3
"""
Check CSV files and generate dbt seed configuration.
Run this script before dbt operations to ensure CSV files are available.
"""

import os
import csv
import json
from datetime import datetime

def find_csv_files():
    """Find all CSV files with project ID pattern."""
    project_id = "b3884914-82a8-45c9-9c56-f37e87f45077"
    pattern = f"dataset_{project_id}_"
    
    csv_files = []
    for file in os.listdir('..'):  # Look in parent directory (project root)
        if file.startswith(pattern) and file.endswith('.csv'):
            csv_files.append(file)
    
    return sorted(csv_files)

def generate_seed_config():
    """Generate dbt seed configuration YAML."""
    csv_files = find_csv_files()
    
    if not csv_files:
        print("No CSV files found!")
        return None
    
    config = {
        "version": 2,
        "seeds": []
    }
    
    seeds = []
    for csv_file in csv_files:
        # Extract sequence number from filename
        # Format: dataset_{project_id}_{seq_num}.csv
        seq_part = csv_file.split('_')[-1].replace('.csv', '')
        
        seed_config = {
            "name": f"raw_logs_{seq_part}",
            "description": f"Raw log data from {csv_file}",
            "config": {
                "schema": "raw",
                "tags": ["seed", "csv", f"seq_{seq_part}"]
            },
            "columns": [
                {"name": "log_id", "description": "Unique identifier for each log entry"},
                {"name": "timestamp", "description": "Event timestamp in ISO 8601 format"},
                {"name": "ip_address", "description": "Client IP address"},
                {"name": "http_method", "description": "HTTP method"},
                {"name": "endpoint", "description": "API endpoint path"},
                {"name": "status_code", "description": "HTTP status code"},
                {"name": "response_time_ms", "description": "Response time in milliseconds"},
                {"name": "user_agent", "description": "Client user agent string"}
            ]
        }
        seeds.append(seed_config)
    
    config["seeds"] = seeds
    return config

def check_csv_consistency():
    """Check consistency of CSV files."""
    csv_files = find_csv_files()
    
    print(f"Found {len(csv_files)} CSV files:")
    for file in csv_files:
        file_path = os.path.join('..', file)
        size = os.path.getsize(file_path)
        print(f"  - {file} ({size:,} bytes)")
        
        # Check row count
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                rows = list(reader)
                print(f"    Rows: {len(rows)} (header + {len(rows)-1} data rows)")
                
                # Check header
                if rows:
                    print(f"    Columns: {len(rows[0])} - {', '.join(rows[0])}")
        except Exception as e:
            print(f"    Error reading file: {e}")
    
    return csv_files

def main():
    """Main function."""
    print("=" * 60)
    print("CSV File Checker for dbt Project")
    print(f"Run time: {datetime.now().isoformat()}")
    print("=" * 60)
    
    # Check CSV files
    csv_files = check_csv_consistency()
    
    # Generate seed configuration
    config = generate_seed_config()
    
    if config:
        # Save configuration
        config_file = "seeds.yml"
        with open(config_file, 'w') as f:
            yaml_content = "version: 2\n\nseeds:\n"
            
            for seed in config["seeds"]:
                yaml_content += f"  - name: {seed['name']}\n"
                yaml_content += f"    description: {seed['description']}\n"
                yaml_content += f"    config:\n"
                yaml_content += f"      schema: {seed['config']['schema']}\n"
                yaml_content += f"      tags: {seed['config']['tags']}\n"
                yaml_content += f"    columns:\n"
                
                for col in seed["columns"]:
                    yaml_content += f"      - name: {col['name']}\n"
                    yaml_content += f"        description: {col['description']}\n"
            
            f.write(yaml_content)
        
        print(f"\nSeed configuration saved to: {config_file}")
        print(f"\nTo load CSV files into dbt, run:")
        print(f"  dbt seed --select raw_logs_*")
        print(f"\nOr load specific files:")
        for seed in config["seeds"]:
            print(f"  dbt seed --select {seed['name']}")
    
    print("\n" + "=" * 60)
    print("Next steps:")
    print("1. Run API.py to download new CSV files")
    print("2. Run this script to update seed configuration")
    print("3. Run dbt seed to load CSV files into database")
    print("4. Run dbt run to build models")
    print("5. Run dbt test to validate data quality")
    print("=" * 60)

if __name__ == "__main__":
    main()