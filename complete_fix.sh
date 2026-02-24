cd ~/MedConnect_Edge

# 1. Bikin folder scripts dulu
mkdir -p scripts

# 2. Bikin metadata generator
cat > scripts/generate_metadata.py << 'EOF'
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
EOF

chmod +x scripts/generate_metadata.py

# 3. Jalankan generator
./run.sh python scripts/generate_metadata.py

# 4. Update README
cat > README.md << 'EOF'
# 🏥 MedConnect Edge - AI Medical Assistant

**Lightweight AI-powered medical triage system optimized for edge devices**

> 🎯 Kaggle Challenge: HAI-DEF Foundation Models  
> 📱 Target: CLI + Android deployment  
> 🤖 Model: MedGemma (Google's medical LLM)

---

## 🚀 Quick Start

### Run Baseline Triage CLI
```bash
./run.sh python src/inference/triage_cli.py \
  --symptoms "demam 4 hari, sakit kepala, nyeri otot, bintik merah"
```

**Output:**
```json
{
  "triage_level": "URGENT",
  "note": "Curiga infeksi (mis. dengue/DBD) butuh evaluasi.",
  "disclaimer": "Ini bukan diagnosis medis. Konsultasi dokter."
}
```

---

## 📁 Project Structure
```
MedConnect_Edge/
├── datasets/
│   ├── raw/MedQA/        # Medical QA dataset
│   ├── processed/        # Preprocessed data
│   └── metadata.json     # Dataset info
├── src/
│   └── inference/        # Inference scripts
│       ├── triage_cli.py         # Baseline triage
│       └── medgemma_explain.py   # AI explainer
├── models/               # Model checkpoints & exports
├── scripts/              # Utility scripts
├── run.sh                # Convenience wrapper
└── requirements.txt      # Python dependencies
```

---

## 🛠️ Development

### Without venv activation (Recommended):
```bash
./run.sh python script.py
./run.sh pip install package
```

### With venv:
```bash
source venv/bin/activate
python script.py
```

---

## 📊 Datasets

- **MedQA**: Medical Question Answering
- **Path**: `datasets/raw/MedQA/`
- **Status**: ✅ Downloaded

View info: `cat datasets/metadata.json`

---

## 🤖 Models

- **Current**: MedGemma 1.5-4B-IT
- **Status**: ⚠️ Quantization needed for 8GB RAM

---

## 📈 Progress

- [x] Project setup
- [x] Baseline triage CLI
- [x] Dataset download
- [ ] MedGemma quantization
- [ ] Fine-tuning pipeline
- [ ] Android app

---

## 👨‍💻 Author

**Alif Fauzan**  
GitHub: [@AlifFauzan21](https://github.com/AlifFauzan21)

EOF

# 5. Bikin CHANGELOG
cat > CHANGELOG.md << 'EOF'
# Changelog

## [Unreleased]

### Added (2025-01-17)
- Project structure setup
- requirements.txt (127 packages)
- .gitignore for ML project
- .env.example template
- Dataset metadata tracking
- README.md documentation
- Baseline triage CLI

### In Progress
- MedGemma quantization
- Dataset preprocessing
- Training pipeline

### Known Issues
- MedGemma OOM on 8GB RAM
- MedQA parsing needed

EOF

# 6. Bikin verification script
cat > scripts/verify_setup.py << 'EOF'
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
EOF

chmod +x scripts/verify_setup.py

# 7. Run verification
echo ""
echo "🔍 Running verification..."
./run.sh python scripts/verify_setup.py

# 8. Show summary
echo ""
echo "========================================"
echo "✅ STRUCTURE FIX COMPLETED!"
echo "========================================"
echo ""
echo "📁 Files created:"
ls -lh requirements.txt .gitignore .env.example README.md CHANGELOG.md 2>/dev/null
echo ""
echo "📊 Dataset metadata:"
cat datasets/metadata.json 2>/dev/null
echo ""
