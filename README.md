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

