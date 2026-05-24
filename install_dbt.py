#!/usr/bin/env python3
"""
Instala o dbt no ambiente virtual .venv-dbt
"""

import subprocess
import sys
from pathlib import Path

def main():
    venv_path = Path(".venv-dbt")
    
    if not venv_path.exists():
        print(f"❌ Virtual environment not found at {venv_path}")
        print("Create it first: python -m venv .venv-dbt")
        sys.exit(1)
    
    # Determine pip path based on OS
    if sys.platform == "win32":
        pip_path = venv_path / "Scripts" / "pip"
        dbt_path = venv_path / "Scripts" / "dbt"
    else:
        pip_path = venv_path / "bin" / "pip"
        dbt_path = venv_path / "bin" / "dbt"
    
    print("🚀 Installing dbt in .venv-dbt...")
    
    # Upgrade pip first
    print("\n1️⃣ Upgrading pip...")
    subprocess.run([str(pip_path), "install", "--upgrade", "pip"])
    
    # Install dbt-core and dbt-postgres
    print("\n2️⃣ Installing dbt-core and dbt-postgres...")
    result = subprocess.run([str(pip_path), "install", "dbt-core", "dbt-postgres"])
    
    if result.returncode != 0:
        print(f"\n❌ Failed to install dbt")
        print("Try manually: .venv-dbt\\Scripts\\activate && pip install dbt-core dbt-postgres")
        sys.exit(1)
    
    # dbt-utils is resolved via dbt deps (packages.yml) — not via pip
    # See logistica_dbt/packages.yml for the correct version
    
    # Check installation
    print("\n4️⃣ Verifying installation...")
    if dbt_path.exists():
        print(f"✅ dbt installed at: {dbt_path}")
    else:
        print(f"⚠️  dbt executable not found at expected location")
    
    # Try running dbt --version via python -m dbt
    print("\n5️⃣ Testing dbt installation...")
    try:
        import dbt
        print(f"✅ dbt module found (version: {getattr(dbt, '__version__', 'unknown')})")
    except ImportError:
        print("❌ dbt module not importable")
    
    print("\n" + "=" * 60)
    print("✅ INSTALLATION COMPLETE!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Activate virtual environment:")
    if sys.platform == "win32":
        print("   .venv-dbt\\Scripts\\Activate.ps1")
    else:
        print("   source .venv-dbt/bin/activate")
    print("2. Navigate to project: cd logistica_dbt")
    print("3. Run dbt debug to test connection")
    print("4. Run dbt deps to install project packages")
    print("5. Run the full pipeline: python test_e2e_pipeline.py")
    print("=" * 60)

if __name__ == "__main__":
    main()
