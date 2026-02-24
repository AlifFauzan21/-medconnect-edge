import argparse
import json
import os
import sys
from datetime import datetime

# Coba import library AI
try:
    from llama_cpp import Llama
except ImportError:
    sys.exit(1)

MODEL_PATH = "models/gguf/gemma-2-2b-it-Q4_K_M.gguf"

def get_ai_triage(symptoms):
    if not os.path.exists(MODEL_PATH):
        return "NON-URGENT", "Model AI tidak ditemukan."

    try:
        llm = Llama(
            model_path=MODEL_PATH,
            n_ctx=1024,
            n_threads=4,
            verbose=False
        )

        # PROMPT UPDATED: Anti-Panik Mode
        prompt = f"""<start_of_turn>user
Anda adalah sistem triase medis. 
Tugas: Klasifikasikan input pasien ke dalam 3 kategori:

1. EMERGENCY (Mengancam nyawa: sesak napas, nyeri dada, pingsan, pendarahan hebat)
2. URGENT (Serius: demam tinggi >3 hari, muntah terus, luka dalam)
3. NON-URGENT (Ringan/Pertanyaan Umum: gatal, batuk ringan, atau HANYA BERTANYA "bahaya gak?" tanpa menyebut gejala)

Input Pasien: "{symptoms}"

Aturan Penting: 
- Jika input hanya berupa pertanyaan abstrak (contoh: "ini bahaya gak?", "obatnya apa?") TANPA deskripsi gejala fisik, WAJIB pilih NON-URGENT.
- Jangan asumsikan kondisi terburuk jika informasi tidak lengkap.

Format JSON:
{{
  "level": "KATEGORI",
  "reason": "Alasan singkat"
}}
Hanya JSON.<end_of_turn>
<start_of_turn>model
"""

        output = llm(
            prompt,
            max_tokens=100,
            temperature=0.0,
            stop=["<end_of_turn>"]
        )

        response_text = output['choices'][0]['text'].strip()
        response_text = response_text.replace("```json", "").replace("```", "").strip()
        
        try:
            data = json.loads(response_text)
            return data.get("level", "NON-URGENT"), data.get("reason", "Analisis AI")
        except:
            return "NON-URGENT", "Pertanyaan umum/tidak spesifik"

    except Exception as e:
        return "NON-URGENT", f"Error: {str(e)}"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--symptoms", required=True)
    args = parser.parse_args()

    level, note = get_ai_triage(args.symptoms)

    # Validasi
    valid_levels = ["EMERGENCY", "URGENT", "NON-URGENT"]
    if level not in valid_levels:
        level = "NON-URGENT" 

    out = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "input": args.symptoms,
        "triage_level": level,
        "note": note,
        "disclaimer": "AI Triase"
    }
    
    print(json.dumps(out, ensure_ascii=False))
