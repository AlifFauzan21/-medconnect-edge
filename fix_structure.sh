#!/bin/bash

# ============================================
# MedConnect Edge - Project Structure Fixer
# Fix missing files & improve organization
# ============================================

set -e

cd ~/MedConnect_Edge

echo "========================================"
echo "🔧 FIXING PROJECT STRUCTURE"
echo "========================================"
echo ""

# ============================================
# 1. GENERATE requirements.txt
# ============================================

echo "📦 Generating requirements.txt..."
./run.sh pip freeze > requirements.txt
echo "✅ requirements.txt created ($(wc -l < requirements.txt) packages)"

# ============================================
# 2. CREATE .gitignore
# ============================================

echo ""
echo "🚫 Creating .gitignore..."

cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environment
venv/
env/
ENV/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Jupyter Notebook
.ipynb_checkpoints
*.ipynb

# Model files & weights (large files)
*.h5
*.pb
*.onnx
*.tflite
*.pt
*.pth
*.bin
*.safetensors
models/checkpoints/*.pth
models/exports/*.onnx

# Dataset cache
.hf_cache/
datasets/raw/*/cache/
*.cache

# OS
.DS_Store
Thumbs.db

# Logs & Results
results/logs/*.log
results/metrics/*.csv
*.log

# Secrets & Config
.env
*.key
*.pem
kaggle.json

# Temporary files
*.tmp
*.temp
temp/
tmp/

# Large dataset files (track metadata only)
datasets/raw/**/*.zip
datasets/raw/**/*.tar.gz
datasets/processed/*.npy
datasets/augmented/*.npy
EOF

echo "✅ .gitignore created"

# ============================================
# 3. CREATE .env.example
# ============================================

echo ""
echo "🔑 Creating .env.example..."

cat > .env.example << 'EOF'
# HuggingFace API Token
HF_TOKEN=your_huggingface_token_here

# Kaggle API Credentials
KAGGLE_USERNAME=your_kaggle_username
KAGGLE_KEY=your_kaggle_key

# Model Configuration
MODEL_NAME=google/medgemma-1.5-4b-it
MAX_LENGTH=512
BATCH_SIZE=1

# Paths
DATASET_PATH=./datasets/raw/MedQA
MODEL_CACHE_DIR=./models/checkpoints
RESULTS_DIR=./results

# Inference Settings
USE_QUANTIZATION=true
DEVICE=cpu
EOF

echo "✅ .env.example created"

# ============================================
# 4. EXPLORE MedQA Dataset Structure
# ============================================

echo ""
echo "📊 Exploring MedQA dataset..."

# Check if actual data exists
if [ -d "datasets/raw/MedQA/IR" ]; then
    echo "✅ MedQA IR folder found"
    
    # List subdirectories
    echo ""
    echo "MedQA structure:"
    find datasets/raw/MedQA/IR -maxdepth 2 -type d | head -10
    
    # Look for actual data files
    echo ""
    echo "Looking for medical QA files..."
    find datasets/raw/MedQA -name "*.jsonl" -o -name "*.json" | grep -v stopwords | head -10
    
else
    echo "⚠️ MedQA data structure incomplete"
fi

# ============================================
# 5. CREATE DATASET METADATA GENERATOR
# ============================================

echo ""
echo "📝 Creating metadata generator..."

cat > scripts/generate_metadata.py << 'EOF'
#!/usr/bin/env python3
"""
Generate metadata.json for tracking datasets
"""

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

# ============================================
# 6. CREATE scripts/ DIRECTORY
# ============================================

mkdir -p scripts

# ============================================
# 7. RUN METADATA GENERATOR
# ============================================

echo ""
echo "🔄 Generating dataset metadata..."
./run.sh python scripts/generate_metadata.py

# ============================================
# 8. CREATE IMPROVED README
# ============================================

echo ""
echo "📝 Updating README.md..."

cat > README.md << 'EOF'
# 🏥 MedConnect Edge - AI Medical Assistant (Edge Devices)

**Lightweight AI-powered medical triage system optimized for edge devices**

> 🎯 Kaggle Challenge Submission: HAI-DEF Foundation Models  
> 📱 Target: CLI + Android deployment  
> 🤖 Model: MedGemma (Google's medical LLM)

---

## 📋 Project Overview

MedConnect Edge adalah sistem triase medis berbasis AI yang dirancang untuk:
- ✅ Analisis gejala & rekomendasi triase (URGENT/NON-URGENT)
- ✅ Penjelasan medis dengan bahasa natural (powered by MedGemma)
- ✅ Optimized untuk edge devices (low memory, CPU inference)
- ✅ Offline-first architecture

---

## 🚀 Quick Start

### 1. Activate Environment
```bash
cd ~/MedConnect_Edge
source venv/bin/activate
```

### 2. Run Baseline Triage CLI
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

### 3. Run AI Explainer (MedGemma)
```bash
./run.sh python src/inference/medgemma_explain.py \
  --symptoms "demam tinggi 3 hari" \
  --triage-result "URGENT"
```

---

## 📁 Project Structure

```
MedConnect_Edge/
├── datasets/
│   ├── raw/              # Raw datasets (MedQA, etc)
│   ├── processed/        # Preprocessed data
│   └── metadata.json     # Dataset tracking
│
├── src/
│   ├── inference/        # Inference scripts
│   │   ├── triage_cli.py         # Baseline rule-based triage
│   │   └── medgemma_explain.py   # AI explanation layer
│   ├── preprocessing/    # Data preprocessing (TODO)
│   ├── training/         # Model training (TODO)
│   └── utils/            # Utility functions
│
├── models/
│   ├── checkpoints/      # Training checkpoints
│   ├── exports/          # Exported models (ONNX, TFLite)
│   └── tflite/           # Quantized TFLite models
│
├── results/
│   ├── logs/             # Training logs
│   ├── metrics/          # Evaluation metrics
│   └── visualizations/   # Plots & charts
│
├── scripts/              # Utility scripts
│   └── generate_metadata.py
│
├── run.sh                # Convenience wrapper (no venv activation needed)
├── requirements.txt      # Python dependencies
└── .env.example          # Environment variables template

```

---

## 🛠️ Development Workflow

### Without Activating venv (Recommended)
```bash
# Install packages
./run.sh pip install package_name

# Run scripts
./run.sh python your_script.py

# Check Python version
./run.sh python --version
```

### With venv Activation (Traditional)
```bash
source venv/bin/activate
python your_script.py
deactivate
```

---

## 📊 Datasets

### MedQA Dataset
- **Path:** `datasets/raw/MedQA/`
- **Type:** Medical Question Answering
- **Source:** [jind11/MedQA](https://github.com/jind11/MedQA)
- **Status:** ✅ Downloaded
- **Usage:** Fine-tuning MedGemma for Indonesian medical context

View dataset info:
```bash
cat datasets/metadata.json
```

---

## 🤖 Models

### Current Model: MedGemma
- **Model ID:** `google/medgemma-1.5-4b-it`
- **Size:** 4B parameters
- **Purpose:** Medical explanation & triage reasoning
- **Status:** ⚠️ In progress (quantization needed for 8GB RAM)

---

## 🔧 Installation & Setup

### System Requirements
- Python 3.12+
- 8GB RAM minimum
- 20GB disk space

### Initial Setup
```bash
cd ~/MedConnect_Edge
./run.sh pip install -r requirements.txt
```

### Environment Variables
```bash
cp .env.example .env
# Edit .env dengan token/credentials kamu
```

---

## 📈 Development Roadmap

- [x] Project structure setup
- [x] Baseline rule-based triage CLI
- [x] HuggingFace integration
- [x] MedQA dataset download
- [ ] MedGemma quantization (for 8GB RAM)
- [ ] Fine-tuning pipeline
- [ ] Model optimization (TFLite export)
- [ ] Android app development
- [ ] Kaggle submission

---

## 🐛 Known Issues

### 1. MedGemma OOM on 8GB RAM
**Issue:** Model killed by OOM killer during load  
**Solution:** Use quantized model (GGUF) or cloud training

### 2. Dataset Parsing
**Issue:** MedQA format needs preprocessing  
**Solution:** Create preprocessing pipeline (in progress)

---

## 📝 License

MIT License - See LICENSE file

---

## 👨‍💻 Author

**Alif Fauzan**  
- GitHub: [@AlifFauzan21](https://github.com/AlifFauzan21)
- Project: [medconnect-edge](https://github.com/AlifFauzan21/-medconnect-edge)

---

## 🙏 Acknowledgments

- Google HAI-DEF Team (MedGemma model)
- Kaggle Challenge organizers
- MedQA dataset creators

EOF

echo "✅ README.md updated"

# ============================================
# 9. CREATE CHANGELOG
# ============================================

echo ""
echo "📜 Creating CHANGELOG.md..."

cat > CHANGELOG.md << 'EOF'
# Changelog

All notable changes to MedConnect Edge project.

## [Unreleased]

### Added
- Project structure setup
- Baseline rule-based triage CLI
- MedGemma integration (in progress)
- HuggingFace authentication
- MedQA dataset download
- Convenience run.sh wrapper
- Comprehensive documentation

### In Progress
- MedGemma quantization for 8GB RAM
- Dataset preprocessing pipeline
- Training scripts

### Known Issues
- MedGemma OOM on 8GB RAM
- MedQA dataset needs parsing

## [0.1.0] - 2025-01-15

### Added
- Initial project setup
- Virtual environment configuration
- Basic inference scripts

EOF

echo "✅ CHANGELOG.md created"

# ============================================
# 10. CREATE SETUP VERIFICATION SCRIPT
# ============================================

echo ""
echo "✅ Creating verification script..."

cat > scripts/verify_setup.py << 'EOF'
#!/usr/bin/env python3
"""Verify project setup is correct"""

import sys
from pathlib import Path

def verify_structure():
    """Check if all required directories exist"""
    required_dirs = [
        "datasets/raw",
        "datasets/processed",
        "src/inference",
        "models/checkpoints",
        "results/logs",
        "scripts"
    ]
    
    print("📁 Verifying directory structure...")
    all_exist = True
    for dir_path in required_dirs:
        path = Path(dir_path)
        status = "✅" if path.exists() else "❌"
        print(f"  {status} {dir_path}")
        if not path.exists():
            all_exist = False
    
    return all_exist

def verify_files():
    """Check if required files exist"""
    required_files = [
        "run.sh",
        "requirements.txt",
        ".gitignore",
        ".env.example",
        "README.md",
        "src/inference/triage_cli.py"
    ]
    
    print("\n📄 Verifying required files...")
    all_exist = True
    for file_path in required_files:
        path = Path(file_path)
        status = "✅" if path.exists() else "❌"
        print(f"  {status} {file_path}")
        if not path.exists():
            all_exist = False
    
    return all_exist

def verify_packages():
    """Check if key packages are installed"""
    packages = [
        "transformers",
        "torch",
        "datasets",
        "huggingface_hub"
    ]
    
    print("\n📦 Verifying Python packages...")
    all_installed = True
    for package in packages:
        try:
            __import__(package)
            print(f"  ✅ {package}")
        except ImportError:
            print(f"  ❌ {package}")
            all_installed = False
    
    return all_installed

def main():
    print("="*60)
    print("🔍 MedConnect Edge - Setup Verification")
    print("="*60 + "\n")
    
    checks = [
        verify_structure(),
        verify_files(),
        verify_packages()
    ]
    
    print("\n" + "="*60)
    if all(checks):
        print("✅ ALL CHECKS PASSED!")
        print("🚀 Your project is ready for development")
        return 0
    else:
        print("⚠️ SOME CHECKS FAILED")
        print("💡 Run ./fix_structure.sh to fix issues")
        return 1

if __name__ == "__main__":
    sys.exit(main())
EOF

chmod +x scripts/verify_setup.py

# ============================================
# 11. RUN VERIFICATION
# ============================================

echo ""
echo "🔍 Running setup verification..."
echo ""
./run.sh python scripts/verify_setup.py

# ============================================
# COMPLETION
# ============================================

echo ""
echo "========================================"
echo "✨ PROJECT STRUCTURE FIXED!"
echo "========================================"
echo ""
echo "📋 Summary of changes:"
echo "  ✅ requirements.txt generated"
echo "  ✅ .gitignore created"
echo "  ✅ .env.example created"
echo "  ✅ README.md updated"
echo "  ✅ CHANGELOG.md created"
echo "  ✅ Dataset metadata generated"
echo "  ✅ Verification scripts added"
echo ""
echo "📁 New files created:"
echo "  - requirements.txt"
echo "  - .gitignore"
echo "  - .env.example"
echo "  - CHANGELOG.md"
echo "  - datasets/metadata.json"
echo "  - scripts/generate_metadata.py"
echo "  - scripts/verify_setup.py"
echo ""
echo "🚀 Next steps:"
echo "  1. Review requirements.txt"
echo "  2. Check datasets/metadata.json"
echo "  3. Copy .env.example to .env and add your tokens"
echo "  4. Commit to git: git add . && git commit -m 'Project structure fixed'"
echo ""
echo "💡 To verify anytime: ./run.sh python scripts/verify_setup.py"
echo ""
