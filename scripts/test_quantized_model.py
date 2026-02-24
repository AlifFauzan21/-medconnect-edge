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
