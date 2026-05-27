#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$SCRIPT_DIR/versions.conf" ]; then
    echo -e "${RED}Error: versions.conf not found in $SCRIPT_DIR${NC}"
    exit 1
fi
source "$SCRIPT_DIR/versions.conf"

echo -e "${BLUE}Downloading models for llama.cpp and whisper.cpp${NC}"

# Function to download file
download_file() {
    local url=$1
    local output=$2
    echo -e "${BLUE}Downloading: $(basename "$output")${NC}"
    
    if command -v curl &> /dev/null; then
        curl -L -o "$output" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$output" "$url"
    else
        echo -e "${RED}Error: Neither curl nor wget found. Please install one of them.${NC}"
        exit 1
    fi
}

# Setup llama.cpp model
echo -e "${BLUE}Setting up llama.cpp model ($LLAMA_MODEL_NAME)...${NC}"
mkdir -p llama.cpp/model

if [ -f "llama.cpp/model/$LLAMA_MODEL_NAME.gguf" ]; then
    echo -e "${GREEN}✓ Model already exists: $LLAMA_MODEL_NAME.gguf${NC}"
elif [ -z "$LLAMA_MODEL_URL" ]; then
    echo -e "${YELLOW}⚠ Model URL not configured for: $LLAMA_MODEL_NAME${NC}"
    echo -e "${BLUE}To configure:${NC}"
    echo "  1. Download from: https://huggingface.co/models"
    echo "  2. Place in: llama.cpp/model/"
    echo "  3. Or update LLAMA_MODEL_URL in versions.conf"
else
    echo -e "${BLUE}Downloading $LLAMA_MODEL_NAME...${NC}"
    download_file "$LLAMA_MODEL_URL" "llama.cpp/model/$LLAMA_MODEL_NAME.gguf"
    echo -e "${GREEN}✓ Downloaded: $LLAMA_MODEL_NAME.gguf${NC}"
fi

# Setup whisper.cpp model
echo -e "${BLUE}Setting up whisper.cpp model ($WHISPER_MODEL_NAME)...${NC}"
mkdir -p whisper.cpp/model

if [ -f "whisper.cpp/model/$WHISPER_MODEL_NAME" ]; then
    echo -e "${GREEN}✓ Model already exists: $WHISPER_MODEL_NAME${NC}"
elif [ -z "$WHISPER_MODEL_URL" ]; then
    echo -e "${RED}Error: WHISPER_MODEL_URL not configured in versions.conf${NC}"
    exit 1
else
    echo -e "${BLUE}Downloading $WHISPER_MODEL_NAME...${NC}"
    download_file "$WHISPER_MODEL_URL" "whisper.cpp/model/$WHISPER_MODEL_NAME"
    echo -e "${GREEN}✓ Downloaded: $WHISPER_MODEL_NAME${NC}"
fi

echo ""
echo -e "${GREEN}✓ Model setup complete!${NC}"
echo -e "${BLUE}Available models:${NC}"
ls -lh llama.cpp/model/ whisper.cpp/model/ 2>/dev/null || true
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "- Test llama: ./llama.cpp/bin/llama -m ./llama.cpp/model/*.gguf -p 'Hello world' -n 50"
echo "- Test whisper: ./whisper.cpp/bin/main -m ./whisper.cpp/model/ggml-base.en.bin -f audio.wav"
