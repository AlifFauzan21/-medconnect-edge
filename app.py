#!/usr/bin/env python3
"""
MedConnect Edge - Web UI (Vision-Aware Triage Version)
"""

import streamlit as st
import subprocess
import json
import os
import time
import psutil
from PIL import Image

# Page config
st.set_page_config(
    page_title="MedConnect Edge",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header { font-size: 3rem; font-weight: bold; color: #1E88E5; text-align: center; margin-bottom: 1rem; }
    .sub-header { font-size: 1.2rem; color: #666; text-align: center; margin-bottom: 2rem; }
    .urgent-box { background-color: #FFEBEE; padding: 1.5rem; border-radius: 10px; border-left: 5px solid #F44336; }
    .non-urgent-box { background-color: #E8F5E9; padding: 1.5rem; border-radius: 10px; border-left: 5px solid #4CAF50; }
    .emergency-box { background-color: #FCE4EC; padding: 1.5rem; border-radius: 10px; border-left: 5px solid #E91E63; }
    .stButton>button { width: 100%; background-color: #1E88E5; color: white; font-size: 1.1rem; padding: 0.75rem; border-radius: 8px; font-weight: bold; }
</style>
""", unsafe_allow_html=True)

# Initialize session state
if 'results' not in st.session_state: st.session_state.results = None
if 'exec_time' not in st.session_state: st.session_state.exec_time = 0.0

# Header
st.markdown('<div class="main-header">🏥 MedConnect Edge</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">AI-Powered Medical Triage Assistant for Edge Devices</div>', unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.header("ℹ️ About")
    st.write("**MedConnect Edge** is an Offline AI triage system designed for remote clinics.")
    st.divider()
    st.header("🎯 Capabilities")
    st.markdown("""
    - 📝 **Symptom Triage** (NLP)
    - 📸 **Wound/Skin Analysis** (Vision)
    - 🧠 **Medical Advice** (LLM)
    """)
    st.divider()
    st.warning("⚠️ AI Tool. NOT a Doctor.")

# Main tabs
tab1, tab2, tab3 = st.tabs(["🔍 Multimodal Assessment", "📊 System Info", "📖 Examples"])

with tab1:
    st.header("Patient Assessment")
    
    col_text, col_img = st.columns([0.6, 0.4])
    
    with col_text:
        symptoms_input = st.text_area(
            "Enter Patient Symptoms:",
            placeholder="Contoh: Demam tinggi 3 hari, ada bintik merah di lengan...",
            height=150
        )
    
    with col_img:
        st.write("📸 Clinical Image (Optional)")
        uploaded_file = st.file_uploader("Upload foto (Luka/Kulit)", type=['png', 'jpg', 'jpeg'])
        
        image_path = None
        if uploaded_file is not None:
            st.image(uploaded_file, caption="Preview", use_container_width=True)
            temp_dir = "temp_images"
            os.makedirs(temp_dir, exist_ok=True)
            image_path = os.path.join(temp_dir, uploaded_file.name)
            with open(image_path, "wb") as f:
                f.write(uploaded_file.getbuffer())

    # Analyze button
    if st.button("🔍 Analyze Case (Multimodal)", type="primary"):
        if symptoms_input.strip() or image_path:
            
            st.session_state.results = None
            start_time = time.time()
            
            triage_data = None
            vision_data = None
            ai_data = None
            
            # --- LOGIKA BARU: VISION FIRST ---
            # Kita jalankan Vision dulu agar hasilnya bisa dipakai untuk Triase

            # 1. ANALISIS GAMBAR (VISUAL)
            vision_context_text = ""
            if image_path:
                with st.spinner("1/3 Analyzing Clinical Image (Vision AI)..."):
                    try:
                        res_vision = subprocess.run(
                            ["./run.sh", "python", "src/inference/medvision_analyze.py", 
                             "--image", image_path, "--json"],
                            capture_output=True, text=True
                        )
                        output_lines = res_vision.stdout.strip().split('\n')
                        for line in output_lines:
                            clean_line = line.strip()
                            if clean_line.startswith('{') and clean_line.endswith('}') and '"status":' in clean_line:
                                try:
                                    vision_data = json.loads(clean_line)
                                    # Ambil teks hasil vision untuk context triase
                                    if vision_data.get('status') == 'success':
                                        vision_context_text = vision_data.get('analysis', '')
                                    break
                                except: continue
                    except Exception as e:
                        st.warning(f"Vision AI Error: {e}")

            # 2. ANALISIS TEKS (TRIASE)
            # Sekarang Triase lebih pintar karena tahu konteks gambar
            with st.spinner("2/3 Performing Triage Assessment..."):
                try:
                    # Gabungkan input user + hasil vision
                    combined_input = symptoms_input
                    if vision_context_text:
                        combined_input += f" [Visual Context from Image: {vision_context_text}]"
                    
                    # Jika input user kosong tapi ada gambar, pakai deskripsi gambar sebagai input triase
                    if not symptoms_input.strip() and vision_context_text:
                        combined_input = f"Patient condition based on image: {vision_context_text}"

                    if combined_input.strip():
                        res_triage = subprocess.run(
                            ["./run.sh", "python", "src/inference/triage_cli.py", "--symptoms", combined_input],
                            capture_output=True, text=True
                        )
                        if res_triage.returncode == 0:
                            lines = res_triage.stdout.strip().split('\n')
                            for line in lines:
                                if line.strip().startswith('{') and line.strip().endswith('}'):
                                    try:
                                        triage_data = json.loads(line)
                                        break
                                    except: continue
                except Exception as e:
                    st.error(f"Triage Error: {e}")

            # 3. EXPLAINER (GABUNGAN)
            if triage_data:
                with st.spinner("3/3 Generating Final Medical Advice..."):
                    
                    vision_arg = []
                    if vision_context_text:
                        vision_arg = ["--vision-text", vision_context_text]
                    
                    # Gunakan input asli user untuk prompt penjelasan agar lebih natural
                    final_symptoms = symptoms_input if symptoms_input.strip() else "Analisis visual saja."

                    cmd = ["./run.sh", "python", "src/inference/medgemma_explain.py",
                           "--symptoms", final_symptoms,
                           "--triage-level", triage_data['triage_level'],
                           "--triage-note", triage_data['note'],
                           "--json"] + vision_arg 

                    res_explain = subprocess.run(
                        cmd,
                        capture_output=True, text=True
                    )
                    
                    if res_explain.returncode == 0:
                        lines = res_explain.stdout.strip().split('\n')
                        for line in lines:
                            if line.strip().startswith('{') and line.strip().endswith('}'):
                                try:
                                    ai_data = json.loads(line)
                                    break
                                except: continue

            # Stop Stopwatch
            end_time = time.time()
            st.session_state.exec_time = end_time - start_time
            
            # Simpan Hasil
            st.session_state.results = {
                'triage': triage_data,
                'vision': vision_data,
                'ai': ai_data
            }
            
        else:
            st.warning("⚠️ Mohon isi gejala atau upload foto.")
    
    # DISPLAY RESULTS
    if st.session_state.results:
        st.divider()
        
        # Triage Box
        triage = st.session_state.results.get('triage')
        if triage:
            lvl = triage['triage_level']
            # Logic warna
            if lvl == "URGENT": cls, icn = "urgent-box", "🚨"
            elif lvl == "EMERGENCY": cls, icn = "emergency-box", "🚨🚨"
            else: cls, icn = "non-urgent-box", "✅"
            
            st.markdown(f'<div class="{cls}">', unsafe_allow_html=True)
            st.markdown(f"## {icn} Triage Level: {lvl}")
            st.markdown(f"**Assessment:** {triage['note']}")
            st.markdown('</div>', unsafe_allow_html=True)

        # Vision AI Result
        if st.session_state.results.get('vision'):
            vis = st.session_state.results['vision']
            st.divider()
            col_v1, col_v2 = st.columns([0.1, 0.9])
            with col_v1:
                st.markdown("## 👁️")
            with col_v2:
                st.subheader("Visual Analysis (BakLLaVA)")
                if vis.get('status') == 'success':
                    st.success(f"Model: {vis.get('model')}")
                    st.info(vis.get('analysis'))
                else:
                    st.error(f"Vision Error: {vis.get('analysis')}")

        # Text AI Result
        if st.session_state.results.get('ai'):
            st.divider()
            ai = st.session_state.results['ai']
            st.header("💡 Medical Explanation")
            st.markdown(ai.get('ai_explanation'))
            st.caption(f"Reasoning Model: {ai.get('model')}")
            
        st.divider()
        st.error("**⚠️ CRITICAL DISCLAIMER:** AI output only. Consult a doctor.")

with tab2:
    st.header("🖥️ System Information")
    
    # RAM Monitoring
    mem = psutil.virtual_memory()
    used_ram_gb = mem.used / (1024 ** 3)
    total_ram_gb = mem.total / (1024 ** 3)
    ram_percent = mem.percent
    
    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Architecture")
        st.markdown("""
        **Multimodal Edge System:**
        - Vision: BakLLaVA-1 (4GB)
        - Logic: MedGemma 2B (1.5GB)
        - Triage: Semantic Router
        """)
    with col2:
        st.subheader("Capabilities")
        st.markdown("""
        - ✅ **Image Understanding**
        - ✅ Real-time Triage
        - ✅ **100% Offline**
        """)
    
    st.divider()
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Vision Model", "BakLLaVA (Local)")
    with col2:
        time_str = f"{st.session_state.exec_time:.2f}s" if st.session_state.exec_time > 0 else "Ready"
        st.metric("Processing Time", time_str)
    with col3:
        st.metric("RAM Usage", f"{used_ram_gb:.1f}/{total_ram_gb:.1f} GB ({ram_percent}%)")

    if st.button("🔄 Refresh Stats"):
        st.rerun()

with tab3:
    st.header("📖 Example Cases")
    st.info("Upload images to test Vision capabilities.")
    examples = [
        ("🦟 Dengue", "demam tinggi 4 hari, bintik merah, nyeri sendi", "URGENT"),
        ("❤️ Heart Attack", "nyeri dada menjalar ke lengan, keringat dingin", "EMERGENCY"),
    ]
    for title, symptoms, expected in examples:
        with st.expander(f"{title}"):
            st.write(f"Symptoms: {symptoms}")

# Footer
st.divider()
st.markdown("<div style='text-align: center; color: #666;'>MedConnect Edge - 2026 Kaggle MedGemma Impact Challenge</div>", unsafe_allow_html=True)
