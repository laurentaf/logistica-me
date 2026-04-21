import os
import argparse
import csv
import requests
import subprocess
import json
import sys
from datetime import datetime
from pathlib import Path

project_id = "b3884914-82a8-45c9-9c56-f37e87f45077"
url = f"https://api.datamission.com.br/projects/{project_id}/dataset?format=csv"

# Load API token from .env file
def load_api_token():
    """Load API token from .env file."""
    try:
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('API_KEY_DATASET='):
                    # Remove quotes if present
                    token = line.split('=', 1)[1].strip()
                    if token.startswith('"') and token.endswith('"'):
                        token = token[1:-1]
                    elif token.startswith("'") and token.endswith("'"):
                        token = token[1:-1]
                    return token
    except FileNotFoundError:
        pass
    return None

def get_next_sequence(start=None):
    """Get next sequence number. If start provided, use it. Otherwise auto-detect from existing files."""
    if start is not None:
        return int(start)
    
    # Auto-detect: find highest existing sequence number and add 1
    raw_dir = Path("data/raw")
    if not raw_dir.exists():
        return 1
    
    pattern = f"dataset_{project_id}_*.csv"
    existing_files = list(raw_dir.glob(pattern))
    
    max_seq = 0
    for file in existing_files:
        try:
            # Extract sequence: dataset_{project_id}_{seq}.csv
            seq_part = file.stem.split('_')[-1]
            seq_num = int(seq_part)
            if seq_num > max_seq:
                max_seq = seq_num
        except (ValueError, IndexError):
            continue
    
    return max_seq + 1

def run_data_test(csv_file):
    """Run data consistency test on downloaded CSV file."""
    print(f"\n🧪 Running data quality test for {csv_file}...")
    
# Create a simple test script for this specific file
    test_script = f"""
import csv
import os
import json
from datetime import datetime

csv_file = "{csv_file}"

test_results = {{
    "test_timestamp": datetime.now().isoformat(),
    "file_name": csv_file,
    "columns": [],
    "tests": []
}}

# Test 1: File exists and readable
test_results["tests"].append({{
    "name": "file_existence",
    "description": "CSV file exists and is readable",
    "status": "PASS" if os.path.exists(csv_file) else "FAIL"
}})

if os.path.exists(csv_file):
    # Test 2: Read CSV structure
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            headers = next(reader)
            
            test_results["tests"].append({{
                "name": "readable_csv",
                "description": "CSV file can be read successfully",
                "status": "PASS"
            }})
            
            # Test 3: Column count
            expected_columns = 8
            actual_columns = len(headers)
            test_results["tests"].append({{
                "name": "column_count",
                "description": f"Expected {{expected_columns}} columns, got {{actual_columns}}",
                "status": "PASS" if actual_columns == expected_columns else "FAIL",
                "expected": expected_columns,
                "actual": actual_columns
            }})
            
            # Test 4: Column names
            expected_columns_list = ['log_id', 'timestamp', 'ip_address', 'http_method', 'endpoint', 'status_code', 'response_time_ms', 'user_agent']
            column_match = headers == expected_columns_list
            
            test_results["tests"].append({{
                "name": "column_names",
                "description": f"Column names match expected format",
                "status": "PASS" if column_match else "FAIL",
                "expected": expected_columns_list,
                "actual": headers
            }})
            
            # Test 5: Sample data row count
            data_rows = 0
            for row in reader:
                data_rows += 1
            
            test_results["tests"].append({{
                "name": "data_row_count",
                "description": f"Data rows (excluding header): {{data_rows}}",
                "status": "PASS" if data_rows > 0 else "FAIL",
                "actual": data_rows
            }})
            
            # Store column information with data types
            column_info = []
            for i, header in enumerate(headers):
                data_type = "string"  # Default
                if header == 'log_id':
                    data_type = "uuid"
                elif header == 'timestamp':
                    data_type = "iso8601_datetime"
                elif header == 'status_code':
                    data_type = "integer"
                elif header == 'response_time_ms':
                    data_type = "integer"
                
                column_info.append({{
                    "name": header,
                    "position": i + 1,
                    "expected_type": data_type,
                    "description": {{
                        "log_id": "Unique identifier (UUID format)",
                        "timestamp": "Event timestamp in ISO 8601 format (YYYY-MM-DDTHH:MM:SS.ssssss)",
                        "ip_address": "Client IP address (IPv4 format)",
                        "http_method": "HTTP method (GET, POST, PUT, DELETE, etc.)",
                        "endpoint": "API endpoint path",
                        "status_code": "HTTP status code (integer: 200, 404, 500, etc.)",
                        "response_time_ms": "Response time in milliseconds (integer)",
                        "user_agent": "Client user agent string"
                    }}[header]
                }})
            
            test_results["columns"] = column_info
            
    except Exception as e:
        test_results["tests"].append({{
            "name": "csv_read_error",
            "description": f"Error reading CSV: {{str(e)}}",
            "status": "FAIL"
        }})

# Calculate conformity percentage
passed_tests = sum(1 for test in test_results["tests"] if test.get("status") == "PASS")
total_tests = len(test_results["tests"])
conformity_pct = (passed_tests / total_tests * 100) if total_tests > 0 else 0

test_results["summary"] = {{
    "total_tests": total_tests,
    "passed_tests": passed_tests,
    "failed_tests": total_tests - passed_tests,
    "conformity_percentage": round(conformity_pct, 2)
}}

# Save test results
results_file = csv_file.replace('.csv', '_test_results.json')
with open(results_file, 'w') as f:
    json.dump(test_results, f, indent=2)

print(f"Test results saved to: {{results_file}}")
print(f"Conformity: {{conformity_pct:.1f}}% ({{passed_tests}}/{{total_tests}} tests passed)")

# Print human-readable summary
print(f"\\n📋 TEST SUMMARY FOR {{test_results['file_name']}}")
print("=" * 50)
for test in test_results["tests"]:
    status_icon = "✅" if test.get("status") == "PASS" else "❌"
    print(f"{{status_icon}} {{test['name']}}: {{test['description']}}")

print(f"\\n📊 COLUMN DATATYPES:")
for col in test_results["columns"]:
    print(f"  {{col['position']}}. {{col['name']}} ({{col['expected_type']}}): {{col['description']}}")

print(f"\\n📈 CONFORMITY: {{conformity_pct:.1f}}%")
"""

    # Run the test script using the current Python interpreter (cross-platform)
    try:
        result = subprocess.run(
            [sys.executable, '-c', test_script],
            capture_output=True,
            text=True,
            check=True
        )
        print(result.stdout)
        
        # Parse the JSON results file
        results_file = csv_file.replace('.csv', '_test_results.json')
        if os.path.exists(results_file):
            with open(results_file, 'r') as f:
                results = json.load(f)
                return results
    except subprocess.CalledProcessError as e:
        print(f"Test execution failed: {e}")
        print(f"Stderr: {e.stderr}")
    except Exception as e:
        print(f"Error running test: {e}")
    
    return None

def log_conformity_summary(test_results_list):
    """Log conformity summary across all files."""
    print(f"\n📊 OVERALL CONFORMITY SUMMARY")
    print("=" * 50)
    
    total_passed = 0
    total_tests = 0
    
    for results in test_results_list:
        if results and "summary" in results:
            summary = results["summary"]
            total_passed += summary["passed_tests"]
            total_tests += summary["total_tests"]
            
            print(f"{results['file_name']}: {summary['conformity_percentage']}% "
                  f"({summary['passed_tests']}/{summary['total_tests']})")
    
    if total_tests > 0:
        overall_pct = (total_passed / total_tests * 100)
        print(f"\n📈 OVERALL: {overall_pct:.1f}% ({total_passed}/{total_tests} tests passed)")
        
        # Save overall summary
        summary_data = {
            "timestamp": datetime.now().isoformat(),
            "total_files_tested": len(test_results_list),
            "total_tests": total_tests,
            "total_passed": total_passed,
            "total_failed": total_tests - total_passed,
            "overall_conformity_percentage": round(overall_pct, 2),
            "files": [{
                "file": r["file_name"],
                "conformity": r["summary"]["conformity_percentage"] if r and "summary" in r else 0
            } for r in test_results_list if r]
        }
        
        with open('download_conformity_summary.json', 'w') as f:
            json.dump(summary_data, f, indent=2)
        
        print(f"\n📄 Summary saved to: download_conformity_summary.json")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download incremental dataset logs")
    parser.add_argument('--count', type=int, default=5, help='Number of files to download')
    parser.add_argument('--start', type=int, help='Starting sequence number (default: auto-detect)')
    args = parser.parse_args()

    token = load_api_token()
    if not token:
        raise ValueError("API_KEY_DATASET not found in .env file")

    headers = {"Authorization": f"Bearer {token}"}

    test_results = []

    start_seq = get_next_sequence(args.start)
    print(f"📥 Starting download from sequence {start_seq:05d} ({args.count} files)")

    for i in range(start_seq, start_seq + args.count):
        response = requests.get(url, headers=headers)
        response.raise_for_status()

        # Ensure data/raw directory exists
        os.makedirs("data/raw", exist_ok=True)
        
        filename = f"dataset_{project_id}_{i:05d}.csv"
        filepath = os.path.join("data/raw", filename)
        with open(filepath, "wb") as file:
            file.write(response.content)

        # Collect metadata immediately after download
        file_size = os.path.getsize(filepath)
        row_count = 0
        column_count = 0
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                headers = next(reader)
                column_count = len(headers)
                row_count = sum(1 for _ in reader)
        except Exception:
            pass  # If reading fails, keep counts zero; test will catch it

        metadata = {
            "filename": filename,
            "filepath": filepath,
            "download_timestamp": datetime.now().isoformat(),
            "file_size_bytes": file_size,
            "row_count": row_count,
            "column_count": column_count,
            "source_url": url,
            "project_id": project_id,
            "sequence": i
        }
        metadata_file = filepath.replace('.csv', '_metadata.json')
        with open(metadata_file, 'w') as f:
            json.dump(metadata, f, indent=2)

        print(f"✅ Download {i-start_seq+1}/{args.count} concluído: {filepath} ({row_count} rows)")
        
        # Run test immediately after download
        test_result = run_data_test(filepath)
        if test_result:
            test_results.append(test_result)

    print("\n🎉 Todos os downloads concluídos com sucesso!")

    # Log overall conformity summary
    log_conformity_summary(test_results)
