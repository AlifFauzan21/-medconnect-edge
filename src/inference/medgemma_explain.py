import argparse
import json
import os
import sys

# Import Library RAG
try:
    from langchain_community.vectorstores import Chroma
    from langchain_community.embeddings import HuggingFaceEmbeddings
    from llama_cpp import Llama
except ImportError:
    print(json.dumps({"status": "error", "ai_explanation": "Library error. Pastikan install langchain & chromadb."}))
    sys.exit(1)

# KONFIGURASI
MODEL_PATH = "models/gguf/gemma-2-2b-it-Q4_K_M.gguf"
DB_PATH = "data/vectorstore"
EMBED_MODEL = "sentence-transformers/all-MiniLM-L6-v2"

def get_rag_context(query_text):
    """Mencari referensi dari dokumen Kemenkes"""
    if not os.path.exists(DB_PATH):
        return ""
    
    try:
        # Load Database
        embeddings = HuggingFaceEmbeddings(model_name=EMBED_MODEL)
        db = Chroma(persist_directory=DB_PATH, embedding_function=embeddings)
        
        # Cari 3 paragraf paling relevan
        docs = db.similarity_search(query_text, k=3)
        
        # Gabungkan hasil
        context_str = "\n".join([f"- {doc.page_content}" for doc in docs])
        return context_str
    except Exception as e:
        return f"Error membaca referensi: {str(e)}"

def generate_medical_explanation(symptoms, triage_level, triage_note, vision_analysis=None):
    if not os.path.exists(MODEL_PATH):
        return {"status": "error", "ai_explanation": "Model not found."}

    try:
        # 1. Cari Referensi Dulu (RAG)
        # Kita cari berdasarkan gejala user
        rag_context = get_rag_context(symptoms)
        
        # 2. Siapkan Data Visual
        vision_section = ""
        if vision_analysis:
            vision_section = f"\n[DATA VISUAL DARI KAMERA]: {vision_analysis}\n"
        else:
            vision_section = "\n[DATA VISUAL]: TIDAK ADA GAMBAR.\n"

        # 3. Prompt Super Lengkap
        # Perhatikan kita memasukkan {rag_context} ke dalam prompt
        prompt = f"""<start_of_turn>user
Anda adalah MedGemma, asisten medis AI yang bekerja berdasarkan Panduan Kemenkes RI.

DATA PASIEN:
- Keluhan: "{symptoms}"
- Triase: {triage_level}
{vision_section}

REFERENSI RESMI (KEMENKES/WHO):
{rag_context}

INSTRUKSI:
1. Jawab pertanyaan pasien dengan ramah.
2. JIKA ADA REFERENSI DI ATAS: Gunakan informasi tersebut untuk memberikan saran medis yang akurat. Kutip referensinya (misal: "Berdasarkan panduan...").
3. JIKA TIDAK ADA REFERENSI: Gunakan pengetahuan umum medis Anda, tapi berikan disclaimer.
4. Berikan 3 langkah pertolongan pertama.

Jawab (Bahasa Indonesia):<end_of_turn>
<start_of_turn>model
"""

        # 4. Inferensi LLM
        llm = Llama(
            model_path=MODEL_PATH,
            n_ctx=4096, # Context window besar buat nampung RAG
            n_threads=4, 
            verbose=False
        )

        output = llm(
            prompt,
            max_tokens=600, 
            temperature=0.2, 
            stop=["<end_of_turn>"]
        )

        return {
            "status": "success",
            "model": "MedGemma-2B + RAG (Kemenkes RI)", # Kita pamerin fitur RAG-nya
            "ai_explanation": output['choices'][0]['text'].strip(),
            "method": "RAG-Enhanced Reasoning"
        }

    except Exception as e:
        return {"status": "error", "ai_explanation": str(e)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--symptoms", default="-")
    parser.add_argument("--triage-level", default="INFO")
    parser.add_argument("--triage-note", default="-")
    parser.add_argument("--vision-text", default=None)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = generate_medical_explanation(
        args.symptoms, 
        args.triage_level, 
        args.triage_note,
        args.vision_text
    )
    
    if args.json:
        print(json.dumps(result))
    else:
        print(result['ai_explanation'])
