import argparse
import json
import os
import sys

# Coba import Llama
try:
    from llama_cpp import Llama
    from llama_cpp.llama_chat_format import Llava15ChatHandler
except ImportError:
    print(json.dumps({"status": "error", "analysis": "Library llama-cpp-python error"}))
    sys.exit(1)

# ==========================================
# KONFIGURASI MODEL VISION (BakLLaVA)
# ==========================================
MODEL_PATH = "models/gguf/ggml-model-q4_k.gguf"
CLIP_PATH = "models/gguf/mmproj-model-f16.gguf"

def analyze_medical_image(image_path, user_query):
    # 1. Validasi File
    if not os.path.exists(MODEL_PATH) or not os.path.exists(CLIP_PATH):
        return {
            "status": "error",
            "analysis": f"Model Vision tidak lengkap.\nCek folder models/gguf",
            "model": "Not Found"
        }
    
    if not os.path.exists(image_path):
        return {
            "status": "error",
            "analysis": f"File gambar tidak ditemukan: {image_path}",
            "model": "Error"
        }

    try:
        # [FIX] Konversi ke Absolute Path agar 'file://' tidak error
        abs_path = os.path.abspath(image_path)
        
        # 2. Setup "Mata" (Chat Handler untuk BakLLaVA/LLaVA v1.5)
        # verbose=False agar log tidak mengotori JSON output
        chat_handler = Llava15ChatHandler(clip_model_path=CLIP_PATH, verbose=False)

        # 3. Load Model (Vision + Text)
        llm = Llama(
            model_path=MODEL_PATH,
            chat_handler=chat_handler,
            n_ctx=2048, 
            n_threads=4, # Sesuaikan core CPU
            n_gpu_layers=0, # Paksa CPU
            verbose=False
        )

        # 4. Prompting dengan Gambar
        prompt_system = "You are an AI Medical Assistant. Analyze this clinical image and describe the visible symptoms or conditions."
        
        response = llm.create_chat_completion(
            messages=[
                {"role": "system", "content": prompt_system},
                {
                    "role": "user",
                    "content": [
                        # [FIX] Gunakan abs_path di sini
                        {"type": "image_url", "image_url": {"url": f"file://{abs_path}"}},
                        {"type": "text", "text": user_query}
                    ]
                }
            ],
            max_tokens=300,
            temperature=0.1
        )

        analysis_text = response["choices"][0]["message"]["content"]

        return {
            "status": "success",
            "analysis": analysis_text,
            "model": "BakLLaVA-1 (Local Vision)",
            "method": "Offline Multimodal Inference"
        }

    except Exception as e:
        return {
            "status": "error",
            "analysis": f"Gagal memproses gambar: {str(e)}",
            "model": "Crash"
        }

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", required=True, help="Path ke file gambar")
    parser.add_argument("--query", default="Describe the medical condition in this image.", help="Pertanyaan")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = analyze_medical_image(args.image, args.query)
    
    if args.json:
        print(json.dumps(result))
    else:
        print(result['analysis'])
