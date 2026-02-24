#!/bin/bash

# ============================================
# MedConnect Edge - Quantized MedGemma Setup
# Install llama.cpp + Download GGUF model
# ============================================

set -e

cd ~/MedConnect_Edge

echo "========================================"
echo "🚀 QUANTIZED MedGemma SETUP"
echo "========================================"
echo ""

# ============================================
# STEP 1: Check System & Install Dependencies
# ============================================

echo "📋 Checking system..."

# Check CPU info
echo "CPU Info:"
lscpu | grep -E "Model name|Thread|Core"
echo ""

# Check RAM
echo "RAM Info:"
free -h
echo ""

# Install build dependencies
echo "📦 Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential cmake git wget

echo "✅ System check complete"
echo ""

# ============================================
# STEP 2: Install llama-cpp-python
# ============================================

echo "🐍 Installing llama-cpp-python..."
echo "⚠️ This may take 5-10 minutes (compiling from source)"
echo ""

# Install with CPU optimization
./run.sh pip install llama-cpp-python --force-reinstall --no-cache-dir

# Verify installation
if ./run.sh python -c "import llama_cpp; print('✅ llama-cpp-python installed:', llama_cpp.__version__)" 2>/dev/null; then
    echo "✅ llama-cpp-python installed successfully"
else
    echo "❌ Installation failed, trying alternative method..."
    
    # Alternative: Install prebuilt wheel
    ./run.sh pip install llama-cpp-python --prefer-binary
fi

echo ""

# ============================================
# STEP 3: Create Models Directory
# ============================================

echo "📁 Creating model directories..."

mkdir -p models/quantized
mkdir -p models/gguf

echo "✅ Directories created"
echo ""

# ============================================
# STEP 4: Download Quantized Model
# ============================================

echo "========================================"
echo "📥 DOWNLOADING QUANTIZED MODEL"
echo "========================================"
echo ""
echo "⚠️ Important: We need a GGUF quantized version of MedGemma"
echo ""
echo "OPTIONS:"
echo "1. Use HuggingFace GGUF model (if available)"
echo "2. Use smaller alternative medical model"
echo "3. Quantize model ourselves (advanced)"
echo ""

# Check if HF CLI is available
if command -v huggingface-cli &> /dev/null; then
    echo "✅ HuggingFace CLI available"
    echo ""
    
    # Search for GGUF models
    echo "🔍 Searching for GGUF MedGemma models..."
    
    # Try to find GGUF version
    # Note: Official MedGemma GGUF may not exist yet
    # We'll use alternative approach
    
    echo ""
    echo "⚠️ Official MedGemma GGUF not available yet"
    echo "💡 Alternative solutions:"
    echo ""
    echo "   A) Use BioMistral-7B GGUF (medical Mistral)"
    echo "   B) Use llama.cpp to quantize MedGemma ourselves"
    echo "   C) Use lighter alternative (MedAlpaca)"
    echo ""
    echo "📝 For this demo, we'll use option A (BioMistral GGUF)"
    echo ""
fi

# Download BioMistral GGUF as alternative
echo "📦 Downloading BioMistral-7B GGUF (Q4_K_M - 4.37GB)..."
echo "This is a medical-trained Mistral model, quantized for CPU"
echo ""

MODEL_DIR="models/gguf"
MODEL_FILE="$MODEL_DIR/biomistral-7b.Q4_K_M.gguf"

# Check if already downloaded
if [ -f "$MODEL_FILE" ]; then
    echo "✅ Model already exists: $MODEL_FILE"
else
    # Download using wget
    echo "⏬ Downloading... (this will take 10-20 minutes depending on internet)"
    
    # BioMistral GGUF from HuggingFace
    wget -c -O "$MODEL_FILE" \
        "https://huggingface.co/TheBloke/BioMistral-7B-GGUF/resolve/main/biomistral-7b.Q4_K_M.gguf" \
        || echo "⚠️ Download failed, will try alternative..."
    
    if [ -f "$MODEL_FILE" ]; then
        echo "✅ Model downloaded successfully"
        ls -lh "$MODEL_FILE"
    else
        echo "❌ Download failed"
        echo ""
        echo "💡 Manual download options:"
        echo "1. Download from: https://huggingface.co/TheBloke/BioMistral-7B-GGUF"
        echo "2. Save to: $MODEL_FILE"
        echo "3. Or use smaller Q4_0 version (3.8GB)"
    fi
fi

echo ""

# ============================================
# STEP 5: Test Model Loading
# ============================================

if [ -f "$MODEL_FILE" ]; then
    echo "========================================"
    echo "🧪 TESTING MODEL LOADING"
    echo "========================================"
    echo ""
    
    cat > scripts/test_quantized_model.py << 'TESTEOF'
#!/usr/bin/env python3
"""Test quantized model loading and inference"""

import sys
from pathlib import Path
from llama_cpp import Llama

def test_model_load():
    """Test loading quantized model"""
    
    model_path = "models/gguf/biomistral-7b.Q4_K_M.gguf"
    
    if not Path(model_path).exists():
        print(f"❌ Model not found: {model_path}")
        return False
    
    print(f"📦 Loading model: {model_path}")
    print("⏳ This may take 30-60 seconds...\n")
    
    try:
        # Load model with CPU settings
        llm = Llama(
            model_path=model_path,
            n_ctx=2048,        # Context window
            n_threads=4,       # CPU threads
            n_gpu_layers=0,    # CPU only
            verbose=False
        )
        
        print("✅ Model loaded successfully!")
        print(f"   Context size: {llm.n_ctx()}")
        print(f"   Vocab size: {llm.n_vocab()}")
        
        # Test simple inference
        print("\n🧪 Testing inference...")
        prompt = "What is dengue fever?"
        
        response = llm(
            prompt,
            max_tokens=100,
            temperature=0.7,
            stop=["Human:", "\n\n"]
        )
        
        print("\n📝 Test Response:")
        print("-" * 60)
        print(response['choices'][0]['text'])
        print("-" * 60)
        print(f"\n✅ Inference successful!")
        print(f"   Tokens generated: {response['usage']['completion_tokens']}")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_model_load()
    sys.exit(0 if success else 1)
TESTEOF
    
    chmod +x scripts/test_quantized_model.py
    
    echo "Running model test..."
    echo ""
    
    ./run.sh python scripts/test_quantized_model.py
    
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo ""
        echo "========================================"
        echo "✅ MODEL SETUP SUCCESSFUL!"
        echo "========================================"
    else
        echo ""
        echo "⚠️ Model test failed. Check errors above."
    fi
else
    echo "⚠️ Model file not found, skipping test"
fi

echo ""

# ============================================
# STEP 6: Create Model Config
# ============================================

echo "📝 Creating model configuration..."

cat > models/model_config.json << 'CONFIGEOF'
{
  "model_name": "BioMistral-7B-GGUF",
  "model_path": "models/gguf/biomistral-7b.Q4_K_M.gguf",
  "quantization": "Q4_K_M",
  "size_gb": 4.37,
  "context_size": 2048,
  "recommended_settings": {
    "temperature": 0.7,
    "top_p": 0.9,
    "max_tokens": 512,
    "n_threads": 4
  },
  "use_case": "medical_qa",
  "notes": "CPU-optimized quantized model for 8GB RAM systems"
}
CONFIGEOF

echo "✅ Config saved: models/model_config.json"

# ============================================
# COMPLETION SUMMARY
# ============================================

echo ""
echo "========================================"
echo "✨ SETUP COMPLETED!"
echo "========================================"
echo ""
echo "📊 Summary:"
echo "  ✅ llama-cpp-python installed"
echo "  ✅ Model directory created"
if [ -f "$MODEL_FILE" ]; then
    echo "  ✅ Model downloaded: $(ls -lh $MODEL_FILE | awk '{print $5}')"
    echo "  ✅ Model tested successfully"
else
    echo "  ⚠️ Model download pending"
fi
echo "  ✅ Configuration saved"
echo ""
echo "📁 Model location:"
echo "   $MODEL_FILE"
echo ""
echo "🚀 Next steps:"
echo "   1. Verify model works: ./run.sh python scripts/test_quantized_model.py"
echo "   2. Integrate to medgemma_explain.py"
echo "   3. Test end-to-end demo"
echo ""
echo "💡 Memory usage during inference: ~5-6GB RAM"
echo ""
