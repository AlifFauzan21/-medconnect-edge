#!/usr/bin/env python3
"""Generate metadata.json for tracking datasets"""

import json
import os
from pathlib import Path
from datetime import datetime

def count_files(directory, extensions):
    """Count files with specific extensions"""
    count = 0
    for ext in extensions:
        count += len(list(Path(directory).rglob(f"*.{ext}")))
    return count

def get_dir_size(directory):
    """Get directory size in MB"""
    total = 0
    for path in Path(directory).rglob('*'):
        if path.is_file():
            total += path.stat().st_size
    return round(total / (1024 * 1024), 2)

def generate_metadata():
    """Generate metadata for all datasets"""
    
    base_dir = Path("datasets/raw")
    metadata = {
        "project": "MedConnect Edge",
        "generated_at": datetime.now().isoformat(),
        "datasets": {}
    }
    
    # Check MedQA
    medqa_dir = base_dir / "MedQA"
    if medqa_dir.exists():
        metadata["datasets"]["MedQA"] = {
            "path": str(medqa_dir),
            "type": "medical_qa",
            "format": "json/jsonl",
            "json_files": count_files(medqa_dir, ["json", "jsonl"]),
            "size_mb": get_dir_size(medqa_dir),
            "source": "https://github.com/jind11/MedQA",
            "status": "downloaded"
        }
    
    # Check for other datasets
    for dataset_dir in base_dir.iterdir():
        if dataset_dir.is_dir() and dataset_dir.name != "MedQA":
            metadata["datasets"][dataset_dir.name] = {
                "path": str(dataset_dir),
                "type": "unknown",
                "size_mb": get_dir_size(dataset_dir),
                "status": "downloaded"
            }
    
    # Save metadata
    output_path = Path("datasets/metadata.json")
    with open(output_path, 'w') as f:
        json.dump(metadata, f, indent=2)
    
    print(f"✅ Metadata saved to: {output_path}")
    print(f"📊 Total datasets: {len(metadata['datasets'])}")
    
    # Print summary
    print("\n📋 Dataset Summary:")
    print("-" * 60)
    for name, info in metadata["datasets"].items():
        print(f"\n{name}:")
        print(f"  Type: {info.get('type', 'N/A')}")
        print(f"  Size: {info.get('size_mb', 0)} MB")
        if 'json_files' in info:
            print(f"  Files: {info['json_files']} JSON files")
        print(f"  Status: {info.get('status', 'unknown')}")

if __name__ == "__main__":
    generate_metadata()
