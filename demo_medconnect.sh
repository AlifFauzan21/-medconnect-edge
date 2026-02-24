#!/bin/bash
# ============================================
# MedConnect Edge - End-to-End Demo
# Complete triage + AI explanation pipeline
# ============================================
set -e
cd ~/MedConnect_Edge
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
echo ""
echo "============================================================"
echo "🏥 MEDCONNECT EDGE - MEDICAL TRIAGE SYSTEM"
echo "============================================================"
echo ""
# ============================================
# Get user input
# ============================================
if [ -z "$1" ]; then
    echo "Usage: ./demo_medconnect.sh \"symptoms\""
    echo ""
    echo "Examples:"
    echo "  ./demo_medconnect.sh \"demam tinggi 3 hari, sakit kepala, nyeri otot\""
    echo "  ./demo_medconnect.sh \"batuk 2 minggu, sesak napas, demam ringin\""
    echo "  ./demo_medconnect.sh \"nyeri dada, keringat dingin, mual\""
    echo ""
    exit 1
fi
SYMPTOMS="$1"
echo -e "${BLUE}📝 Patient Symptoms:${NC}"
echo "   $SYMPTOMS"
echo ""
# ============================================
# STEP 1: Baseline Triage (Rule-based)
# ============================================
echo -e "${YELLOW}⏳ Step 1/2: Running baseline triage...${NC}"
echo ""
TRIAGE_OUTPUT=$(./run.sh python src/inference/triage_cli.py --symptoms "$SYMPTOMS" 2>/dev/null)
if [ -z "$TRIAGE_OUTPUT" ]; then
    echo -e "${RED}❌ Triage failed${NC}"
    exit 1
fi
echo "$TRIAGE_OUTPUT"
echo ""
# Parse JSON output
TRIAGE_LEVEL=$(echo "$TRIAGE_OUTPUT" | grep -o '"triage_level": "[^"]*"' | cut -d'"' -f4)
TRIAGE_NOTE=$(echo "$TRIAGE_OUTPUT" | grep -o '"note": "[^"]*"' | cut -d'"' -f4)
if [ -z "$TRIAGE_LEVEL" ]; then
    echo -e "${RED}❌ Failed to parse triage result${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Triage Level: $TRIAGE_LEVEL${NC}"
echo ""
# ============================================
# STEP 2: AI Explanation
# ============================================
echo -e "${YELLOW}⏳ Step 2/2: Generating AI explanation...${NC}"
echo ""
./run.sh python src/inference/medgemma_explain.py \
    --symptoms "$SYMPTOMS" \
    --triage-level "$TRIAGE_LEVEL" \
    --triage-note "$TRIAGE_NOTE" \
    2>/dev/null
echo ""
echo "============================================================"
echo -e "${GREEN}✅ CONSULTATION COMPLETE${NC}"
echo "============================================================"
echo ""
echo "⚠️  Remember: This is an AI-assisted triage system."
echo "    Always consult a healthcare professional for diagnosis."
echo ""
