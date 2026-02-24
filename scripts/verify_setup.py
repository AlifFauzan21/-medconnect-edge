#!/usr/bin/env python3
"""Verify project setup"""

import sys
from pathlib import Path

def verify():
    print("🔍 Verifying MedConnect Edge setup...\n")
    
    required = {
        "Directories": [
            "datasets/raw", "src/inference", "models", "scripts"
        ],
        "Files": [
            "run.sh", "requirements.txt", ".gitignore", 
            ".env.example", "README.md", "datasets/metadata.json"
        ]
    }
    
    all_ok = True
    
    for category, items in required.items():
        print(f"📋 {category}:")
        for item in items:
            exists = Path(item).exists()
            status = "✅" if exists else "❌"
            print(f"  {status} {item}")
            if not exists:
                all_ok = False
        print()
    
    if all_ok:
        print("✅ ALL CHECKS PASSED! Ready for development.\n")
        return 0
    else:
        print("⚠️ Some items missing. Review output above.\n")
        return 1

if __name__ == "__main__":
    sys.exit(verify())
