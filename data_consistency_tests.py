#!/usr/bin/env python3
"""Run data consistency tests on CSV files without pandas dependency."""

import os
import csv
import json
from datetime import datetime
import re

def test_csv_files():
    """Run consistency tests on all CSV files."""
    results = []
    test_id = 1
    
    # Get all CSV files with project ID pattern
    csv_files = sorted([f for f in os.listdir("data/raw") if f.startswith('dataset_b3884914-82a8-45c9-9c56-f37e87f45077_') and f.endswith('.csv')])
    
    print(f"Found {len(csv_files)} CSV files:")
    for f in csv_files:
        print(f"  - {f}")
    
    # Test 1: File existence and naming convention
    test_id = 1
    test_results = []
    for csv_file in csv_files:
        if not csv_file.endswith('.csv'):
            test_results.append({"file": csv_file, "status": "FAIL", "message": "Not a CSV file"})
        elif not csv_file.startswith('dataset_b3884914-82a8-45c9-9c56-f37e87f45077_'):
            test_results.append({"file": csv_file, "status": "FAIL", "message": "Wrong naming pattern"})
        else:
            test_results.append({"file": csv_file, "status": "PASS", "message": "Valid naming convention"})
    
    results.append({
        "test_id": test_id,
        "test_name": "File naming convention",
        "results": test_results
    })
    
    # Test 2: File readability and structure
    test_id += 1
    test_results = []
    for csv_file in csv_files:
        try:
            with open(os.path.join("data/raw", csv_file), 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                
                # Check a few rows
                row_count = 0
                for i, row in enumerate(reader):
                    if i < 5:  # Check first 5 data rows
                        if len(row) == len(headers):
                            row_count += 1
                        else:
                            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Row {i+2} has {len(row)} columns, expected {len(headers)}"})
                            break
                
                if len(headers) == 8:
                    test_results.append({"file": csv_file, "status": "PASS", "message": f"8 columns found: {headers}"})
                else:
                    test_results.append({"file": csv_file, "status": "FAIL", "message": f"Expected 8 columns, got {len(headers)}"})
        except Exception as e:
            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Error reading file: {str(e)}"})
    
    results.append({
        "test_id": test_id,
        "test_name": "File structure and readability",
        "results": test_results
    })
    
    # Test 3: Column names consistency
    test_id += 1
    test_results = []
    expected_columns = ['log_id', 'timestamp', 'ip_address', 'http_method', 'endpoint', 'status_code', 'response_time_ms', 'user_agent']
    
    for csv_file in csv_files:
        try:
            with open(os.path.join("data/raw", csv_file), 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                
                if headers == expected_columns:
                    test_results.append({"file": csv_file, "status": "PASS", "message": "Column names match expected"})
                else:
                    test_results.append({"file": csv_file, "status": "FAIL", "message": f"Columns: {headers}"})
        except Exception as e:
            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Error reading headers: {str(e)}"})
    
    results.append({
        "test_id": test_id,
        "test_name": "Column names consistency",
        "results": test_results
    })
    
    # Test 4: Data types and null values (sample check)
    test_id += 1
    test_results = []
    uuid_pattern = re.compile(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$', re.IGNORECASE)
    
    for csv_file in csv_files:
        try:
            with open(os.path.join("data/raw", csv_file), 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                
                # Sample 100 rows or less if file is smaller
                sample_rows = []
                null_counts = {col: 0 for col in headers}
                uuid_valid_count = 0
                total_rows_checked = 0
                
                for i, row in enumerate(reader):
                    if i >= 100:  # Limit sample size
                        break
                    
                    total_rows_checked += 1
                    
                    # Check for null/empty values
                    for j, value in enumerate(row):
                        if not value or value.strip() == '':
                            null_counts[headers[j]] += 1
                    
                    # Check UUID format for log_id (first column)
                    if row and len(row) > 0:
                        if uuid_pattern.match(row[0]):
                            uuid_valid_count += 1
                    
                    sample_rows.append(row)
                
                # Calculate UUID validity percentage
                uuid_valid_percentage = (uuid_valid_count / total_rows_checked * 100) if total_rows_checked > 0 else 0
                
                if uuid_valid_percentage > 95:
                    test_results.append({
                        "file": csv_file, 
                        "status": "PASS", 
                        "message": f"UUID validity: {uuid_valid_percentage:.1f}%, nulls: {null_counts}"
                    })
                else:
                    test_results.append({
                        "file": csv_file, 
                        "status": "WARNING", 
                        "message": f"UUID validity low: {uuid_valid_percentage:.1f}%, nulls: {null_counts}"
                    })
                
        except Exception as e:
            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Error in data type check: {str(e)}"})
    
    results.append({
        "test_id": test_id,
        "test_name": "Data types and null values",
        "results": test_results
    })
    
    # Test 5: File size consistency (rough check)
    test_id += 1
    test_results = []
    
    file_sizes = {}
    for csv_file in csv_files:
        size = os.path.getsize(csv_file)
        file_sizes[csv_file] = size
        
        if size > 100000:  # At least 100KB
            test_results.append({"file": csv_file, "status": "PASS", "message": f"File size: {size:,} bytes"})
        else:
            test_results.append({"file": csv_file, "status": "WARNING", "message": f"File size small: {size:,} bytes"})
    
    results.append({
        "test_id": test_id,
        "test_name": "File size consistency",
        "results": test_results
    })
    
    # Test 6: Row count consistency
    test_id += 1
    test_results = []
    
    for csv_file in csv_files:
        try:
            # Count lines efficiently
            with open(csv_file, 'r') as f:
                line_count = sum(1 for line in f)
            
            # Subtract 1 for header
            data_rows = line_count - 1 if line_count > 0 else 0
            
            if data_rows >= 900 and data_rows <= 1100:
                test_results.append({"file": csv_file, "status": "PASS", "message": f"Row count: {data_rows}"})
            else:
                test_results.append({"file": csv_file, "status": "WARNING", "message": f"Row count out of range: {data_rows}"})
                
        except Exception as e:
            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Error counting rows: {str(e)}"})
    
    results.append({
        "test_id": test_id,
        "test_name": "Row count consistency",
        "results": test_results
    })
    
    # Test 7: Timestamp format check
    test_id += 1
    test_results = []
    timestamp_pattern = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+$')
    
    for csv_file in csv_files:
        try:
            with open(os.path.join("data/raw", csv_file), 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                
                # Find timestamp column index
                timestamp_idx = headers.index('timestamp') if 'timestamp' in headers else -1
                
                if timestamp_idx == -1:
                    test_results.append({"file": csv_file, "status": "FAIL", "message": "No timestamp column found"})
                    continue
                
                # Sample 50 rows
                invalid_timestamps = 0
                total_checked = 0
                
                for i, row in enumerate(reader):
                    if i >= 50:
                        break
                    
                    total_checked += 1
                    if len(row) > timestamp_idx:
                        timestamp = row[timestamp_idx]
                        if not timestamp_pattern.match(timestamp):
                            invalid_timestamps += 1
                
                if invalid_timestamps == 0:
                    test_results.append({"file": csv_file, "status": "PASS", "message": "All timestamps valid"})
                else:
                    test_results.append({"file": csv_file, "status": "WARNING", "message": f"{invalid_timestamps}/{total_checked} invalid timestamps"})
                
        except Exception as e:
            test_results.append({"file": csv_file, "status": "FAIL", "message": f"Error in timestamp check: {str(e)}"})
    
    results.append({
        "test_id": test_id,
        "test_name": "Timestamp format validation",
        "results": test_results
    })
    
    # Generate summary report
    summary = {
        "test_run_time": datetime.now().isoformat(),
        "total_files_tested": len(csv_files),
        "total_tests": test_id,
        "detailed_results": results
    }
    
    # Save results to JSON file
    with open('data_consistency_test_results.json', 'w') as f:
        json.dump(summary, f, indent=2)
    
    # Print summary
    print(f"\n=== Data Consistency Test Results ===")
    print(f"Test run time: {summary['test_run_time']}")
    print(f"Files tested: {summary['total_files_tested']}")
    print(f"Tests performed: {summary['total_tests']}")
    
    for test in results:
        print(f"\nTest {test['test_id']}: {test['test_name']}")
        for result in test['results']:
            status_color = "🟢" if result['status'] == 'PASS' else "🟡" if result['status'] == 'WARNING' else "🔴"
            print(f"  {status_color} {result['file']}: {result['message']}")
    
    print(f"\nDetailed results saved to: data_consistency_test_results.json")
    
    return summary

if __name__ == "__main__":
    test_csv_files()