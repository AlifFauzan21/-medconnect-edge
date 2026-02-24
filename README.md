# 🏥 MedConnect Edge v2.0 - Offline Multimodal Medical Triage

**An ultra-lightweight, offline-first multimodal AI triage system optimized for extreme edge devices and remote clinics (*Puskesmas Terpencil*).**

> 🏆 **Submitted for:** 2026 Kaggle MedGemma Impact Challenge (The Edge AI Prize)  
> 🎥 **Video Demo:** [Watch the 3-Minute Demo on YouTube](https://youtu.be/FmhcWjZVyv8)  
> 🧠 **Core Models:** MedGemma-2B (Logic/RAG) + BakLLaVA (Vision)  
> 💻 **Hardware Requirement:** Runs smoothly on **~2.4 GB of RAM** entirely offline.

---

## ✨ Key Features

1. **Split-Brain Multimodal AI:** Combines visual analysis for skin conditions/wounds (via BakLLaVA) with NLP symptom triage (via MedGemma-2B).
2. **100% Offline RAG Pipeline:**  Retrieves official Indonesian Ministry of Health guidelines locally using ChromaDB, ensuring advice is medically aligned without needing internet access.
3. **Extreme Edge Optimization:** Utilizes aggressive 4-bit quantization (GGUF `Q4_K_M`) via `llama.cpp` to run on severely constrained hardware.
4. **Interactive Web UI:** Clean, human-centered Streamlit interface designed for fast data entry by frontline health workers.

---

## 🚀 Quick Start

### 1. Run the Web App (Streamlit)
To launch the full interactive multimodal UI:
```bash
./run.sh streamlit run app.py

The app will be available at http://localhost:8501
2. Run Headless / CLI Tools

You can still run individual modules via CLI for testing:
Bash

# Test Vision AI
./run.sh python src/inference/medvision_analyze.py --image temp_images/luka.jpeg

# Test Text Triage
./run.sh python src/inference/triage_cli.py --symptoms "demam 4 hari dan bintik merah"

📁 Project Structure

MedConnect_Edge/
├── app.py                      # Main Streamlit Web Application
├── data/
│   ├── guidelines/             # Medical PDFs (Kemenkes)
│   └── vectorstore/            # ChromaDB offline RAG database
├── models/
│   └── gguf/                   # Quantized models (MedGemma & BakLLaVA)
├── src/
│   ├── inference/              # Inference scripts
│   │   ├── medvision_analyze.py # Vision AI logic
│   │   ├── triage_cli.py        # NLP triage logic
│   │   └── medgemma_explain.py  # Final RAG explanation generator
│   └── rag/
│       └── build_knowledge.py   # RAG vector database builder
├── run.sh                      # Environment execution wrapper
└── requirements.txt            # Python dependencies

⚠️ Disclaimer

CRITICAL: This software provides AI-generated output for decision-support purposes only. It is NOT a replacement for professional medical diagnosis. Always consult a certified human doctor.
👨‍💻 Author

Alif Fauzan Lead Developer & Edge AI Engineer GitHub: @AlifFauzan21
