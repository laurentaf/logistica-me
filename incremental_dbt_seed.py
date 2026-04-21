#!/usr/bin/env python3
"""
Incremental dbt seed for PostgreSQL.
Only loads new files that haven't been processed yet.
"""

import os
import json
from pathlib import Path
import subprocess
from datetime import datetime

class IncrementalDBTSeed:
    def __init__(self):
        self.state_file = "config/seed_state.json"
        self.seeds_dir = "logistica_dbt/seeds"
        self.processed_dir = "data/processed"
        self.raw_dir = "data/raw"
        
        # Initialize state file if it doesn't exist
        self.ensure_state_file()
        
    def ensure_state_file(self):
        """Ensure state file exists."""
        # Ensure the directory for the state file exists
        state_dir = os.path.dirname(self.state_file)
        if state_dir:
            os.makedirs(state_dir, exist_ok=True)
        
        if not os.path.exists(self.state_file):
            state = {
                "last_run": None,
                "processed_files": [],
                "loaded_files": [],
                "total_rows_loaded": 0
            }
            self.save_state(state)
    
    def load_state(self):
        """Load current state."""
        try:
            with open(self.state_file, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {
                "last_run": None,
                "processed_files": [],
                "loaded_files": [],
                "total_rows_loaded": 0
            }
    
    def save_state(self, state):
        """Save state to file."""
        state["last_run"] = datetime.now().isoformat()
        with open(self.state_file, 'w') as f:
            json.dump(state, f, indent=2)
    
    def count_rows_in_csv(self, csv_file):
        """Count rows in CSV file (excluding header)."""
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                return sum(1 for line in f) - 1  # Subtract header
        except Exception:
            return 0
    
    def get_new_processed_files(self, state):
        """Get processed files that haven't been loaded yet."""
        processed_files = list(Path(self.processed_dir).glob("*_processed.csv"))
        
        new_files = []
        for file_path in processed_files:
            file_str = str(file_path)
            if file_str not in state["processed_files"]:
                new_files.append(file_str)
        
        return new_files
    
    def prepare_seed_from_processed(self, processed_file):
        """Prepare seed file from processed file."""
        processed_path = Path(processed_file)
        
        # Extract sequence number from filename:
        # Example: dataset_b3884914-82a8-45c9-9c56-f37e87f45077_00001_processed.csv
        stem = processed_path.stem
        # Remove trailing "_processed" if present
        if stem.endswith('_processed'):
            stem = stem[:-10]  # remove "_processed" (10 chars)
        # Now stem: dataset_b3884914-..._00001
        # Get last part after final underscore
        seq = stem.rsplit('_', 1)[-1]
        if not seq.isdigit():
            raise ValueError(f"Could not extract sequence from filename: {processed_path.name}")
        
        seed_name = f"raw_logs_{seq}"
        seed_filename = f"{seed_name}.csv"
        seed_path = Path(self.seeds_dir) / seed_filename
        
        # Copy processed file to seeds directory with new name
        import shutil
        shutil.copy2(processed_file, seed_path)
        
        return str(seed_path), seed_name
    
    def run_dbt_seed_select(self, seed_names):
        """Run dbt seed command for specific seeds only."""
        if not seed_names:
            print("⚠️  No new seeds to load")
            return True
        
        print(f"🌱 Running dbt seed for {len(seed_names)} new seed(s): {', '.join(seed_names)}")
        
        try:
            # Change to dbt directory
            original_dir = os.getcwd()
            os.chdir("logistica_dbt")
            
            # Build command: dbt seed --select seed1 seed2 ...
            cmd = ["dbt", "seed", "--profiles-dir", "."] + seed_names
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            # Return to original directory
            os.chdir(original_dir)
            
            if result.returncode == 0:
                print("✅ dbt seed completed successfully")
                if result.stdout:
                    print(result.stdout[:500])
                return True
            else:
                print("❌ dbt seed failed")
                print("STDOUT:", result.stdout)
                print("STDERR:", result.stderr)
                return False
                
        except Exception as e:
            print(f"❌ Error running dbt seed: {e}")
            return False
    
    def run_incremental_pipeline(self):
        """Run complete incremental pipeline."""
        print("=" * 60)
        print("🌱 INCREMENTAL DBT SEED PIPELINE")
        print("=" * 60)
        
        # Load current state
        state = self.load_state()
        
        # Check for new processed files
        new_processed_files = self.get_new_processed_files(state)
        
        if not new_processed_files:
            print("✅ No new processed files to load")
            print(f"Last run: {state.get('last_run', 'Never')}")
            print(f"Total files loaded: {len(state['loaded_files'])}")
            print(f"Total rows loaded: {state['total_rows_loaded']}")
            return
        
        print(f"📁 Found {len(new_processed_files)} new processed files")
        
        # Prepare seeds and update state
        seed_paths_prepared = []
        seed_names = []
        total_new_rows = 0
        
        for processed_file in new_processed_files:
            try:
                seed_path, seed_name = self.prepare_seed_from_processed(processed_file)
                row_count = self.count_rows_in_csv(seed_path)
                
                seed_paths_prepared.append(seed_path)
                seed_names.append(seed_name)
                state["processed_files"].append(processed_file)
                state["loaded_files"].append({
                    "file": seed_name,
                    "processed_source": processed_file,
                    "rows": row_count,
                    "loaded_at": datetime.now().isoformat()
                })
                state["total_rows_loaded"] += row_count
                
                print(f"✅ Prepared: {seed_name} ({row_count} rows)")
                total_new_rows += row_count
                
            except Exception as e:
                print(f"❌ Error preparing {processed_file}: {e}")
        
        # Run dbt seed for only the new seeds
        if seed_names:
            success = self.run_dbt_seed_select(seed_names)
            
            if success:
                # Update state
                self.save_state(state)
                
                print("\n" + "=" * 60)
                print("🎉 INCREMENTAL LOAD COMPLETED")
                print("=" * 60)
                print(f"📊 Summary:")
                print(f"   New files loaded: {len(seed_names)}")
                print(f"   Total rows added: {total_new_rows}")
                print(f"   Total files in database: {len(state['loaded_files'])}")
                print(f"   Total rows in database: {state['total_rows_loaded']}")
                print(f"\n📈 Next incremental run will only process new files")
            else:
                print("❌ Incremental load failed - state not updated")
        else:
            print("⚠️  No seed files were successfully prepared")

def main():
    """Main function."""
    pipeline = IncrementalDBTSeed()
    pipeline.run_incremental_pipeline()

if __name__ == "__main__":
    main()