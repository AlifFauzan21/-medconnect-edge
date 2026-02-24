import os
import glob
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma

# --- KONFIGURASI ---
DATA_PATH = "data/guidelines"
DB_PATH = "data/vectorstore"
EMBED_MODEL = "sentence-transformers/all-MiniLM-L6-v2" # Model kecil & cepat

def ingest_documents():
    # 1. Cari semua PDF
    pdf_files = glob.glob(os.path.join(DATA_PATH, "*.pdf"))
    if not pdf_files:
        print(f"❌ Tidak ada PDF di folder {DATA_PATH}. Masukkan file dulu!")
        return

    print(f"📚 Menemukan {len(pdf_files)} dokumen medis...")
    
    documents = []
    for pdf_file in pdf_files:
        print(f"   - Membaca: {os.path.basename(pdf_file)}...")
        loader = PyPDFLoader(pdf_file)
        documents.extend(loader.load())

    # 2. Pecah jadi potongan kecil (Chunks)
    # Chunk size 500 kata cukup untuk konteks medis
    text_splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=50)
    texts = text_splitter.split_documents(documents)
    print(f"✂️  Dipecah menjadi {len(texts)} potongan informasi.")

    # 3. Download Model Embedding (Hanya sekali di awal)
    print("🧠 Memuat model embedding (MiniLM)...")
    embeddings = HuggingFaceEmbeddings(model_name=EMBED_MODEL)

    # 4. Simpan ke Vector DB (Chroma)
    print("💾 Menyimpan ke 'Otak' lokal (ChromaDB)...")
    # Hapus DB lama jika ada biar fresh
    if os.path.exists(DB_PATH):
        import shutil
        shutil.rmtree(DB_PATH)
        
    db = Chroma.from_documents(
        documents=texts, 
        embedding=embeddings, 
        persist_directory=DB_PATH
    )
    
    print("✅ SELESAI! Pengetahuan medis sudah tertanam di sistem.")
    print(f"📂 Database tersimpan di: {DB_PATH}")

if __name__ == "__main__":
    ingest_documents()
