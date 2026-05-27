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

echo -e "${BLUE}Setting up cross-platform binaries for llama.cpp and whisper.cpp${NC}"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        OS_TYPE="linux"
        ;;
    Darwin*)
        OS_TYPE="macos"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS_TYPE="windows"
        ;;
    *)
        echo -e "${RED}Unsupported OS: $OS${NC}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64)
        ARCH_TYPE="x86_64"
        ;;
    aarch64|arm64)
        ARCH_TYPE="arm64"
        ;;
    *)
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Detected: $OS_TYPE / $ARCH_TYPE${NC}"

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

# Function to extract archive
extract_archive() {
    local file=$1
    local dest=$2
    
    if [[ "$file" == *.tar.gz ]]; then
        tar -xzf "$file" -C "$dest"
    elif [[ "$file" == *.zip ]]; then
        unzip -o "$file" -d "$dest"
    elif [[ "$file" == *.tar.bz2 ]]; then
        tar -xjf "$file" -C "$dest"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check dependencies
check_dependencies() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing dependencies: ${missing[*]}${NC}"
        return 1
    fi
    return 0
}

# Setup llama.cpp binaries
setup_llama() {
    echo -e "${BLUE}Setting up llama.cpp binaries (v$LLAMA_VERSION)...${NC}"
    
    mkdir -p llama.cpp/model
    mkdir -p llama.cpp/bin
    
    if [ "$LLAMA_BUILD_METHOD" = "source" ]; then
        setup_llama_from_source
    else
        setup_llama_from_download
    fi
}

# Setup llama.cpp from source (macOS or manual builds)
setup_llama_from_source() {
    echo -e "${BLUE}Building llama.cpp from source...${NC}"
    
    # Check dependencies
    if ! check_dependencies git cmake; then
        echo -e "${YELLOW}Installing dependencies...${NC}"
        if [ "$OS_TYPE" = "macos" ]; then
            echo "Run: brew install cmake git"
        elif [ "$OS_TYPE" = "linux" ]; then
            echo "Run: sudo apt-get install build-essential cmake git"
        fi
        return 1
    fi
    
    # Clone if needed
    if [ ! -d "llama.cpp/source" ]; then
        echo -e "${BLUE}Cloning llama.cpp repository...${NC}"
        git clone "$LLAMA_GIT_REPO" llama.cpp/source
    fi
    
    cd llama.cpp/source
    
    # Checkout specific version
    echo -e "${BLUE}Checking out version $LLAMA_GIT_TAG...${NC}"
    git fetch origin
    git checkout "$LLAMA_GIT_TAG"
    
    # Build
    echo -e "${BLUE}Building llama.cpp...${NC}"
    mkdir -p build
    cd build
    cmake .. $LLAMA_CMAKE_FLAGS 2>/dev/null || cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc)" || make
    
    # Copy binaries to bin directory
    cd ../..
    find llama.cpp/source/build -maxdepth 1 -type f -executable ! -name "*.a" -exec cp {} llama.cpp/bin/ \;
    
    echo -e "${GREEN}✓ llama.cpp built from source${NC}"
}

# Setup llama.cpp from prebuilt binaries
setup_llama_from_download() {
    echo -e "${BLUE}Downloading llama.cpp binaries...${NC}"
    
    local LLAMA_URL=""
    
    if [ "$OS_TYPE" = "macos" ]; then
        if [ "$ARCH_TYPE" = "arm64" ]; then
            LLAMA_URL="$LLAMA_MACOS_URL"
        else
            LLAMA_URL="$LLAMA_MACOS_X86_URL"
        fi
    elif [ "$OS_TYPE" = "linux" ] && [ "$ARCH_TYPE" = "x86_64" ]; then
        LLAMA_URL="$LLAMA_LINUX_X64_URL"
    elif [ "$OS_TYPE" = "linux" ] && [ "$ARCH_TYPE" = "arm64" ]; then
        LLAMA_URL="$LLAMA_LINUX_ARM64_URL"
    elif [ "$OS_TYPE" = "windows" ]; then
        LLAMA_URL="$LLAMA_WINDOWS_URL"
    else
        echo -e "${RED}No llama.cpp binary available for $OS_TYPE/$ARCH_TYPE${NC}"
        return 1
    fi
    
    if [ -z "$LLAMA_URL" ]; then
        echo -e "${RED}Could not determine llama.cpp release URL${NC}"
        return 1
    fi
    
    local LLAMA_ARCHIVE="llama-$OS_TYPE-$ARCH_TYPE.zip"
    download_file "$LLAMA_URL" "$LLAMA_ARCHIVE"
    mkdir -p llama.cpp/bin
    extract_archive "$LLAMA_ARCHIVE" llama.cpp/bin
    
    # Flatten nested directory structure if present (build/bin/*)
    if [ -d "llama.cpp/bin/build/bin" ]; then
        echo -e "${BLUE}Organizing binaries...${NC}"
        mv llama.cpp/bin/build/bin/* llama.cpp/bin/ 2>/dev/null || true
        rm -rf llama.cpp/bin/build llama.cpp/bin/*.metal llama.cpp/bin/*.h 2>/dev/null || true
    fi
    
    rm "$LLAMA_ARCHIVE"
    
    echo -e "${GREEN}✓ llama.cpp binaries installed${NC}"
}

# Setup whisper.cpp binaries
setup_whisper() {
    echo -e "${BLUE}Setting up whisper.cpp binaries (v$WHISPER_VERSION)...${NC}"
    
    mkdir -p whisper.cpp/model
    mkdir -p whisper.cpp/bin
    
    # macOS always builds from source for better CLI integration
    if [ "$OS_TYPE" = "macos" ]; then
        setup_whisper_from_source
    else
        setup_whisper_from_download
    fi
}

# Setup whisper.cpp from source (macOS)
setup_whisper_from_source() {
    echo -e "${BLUE}Building whisper.cpp from source for macOS...${NC}"
    
    # Check dependencies
    if ! check_dependencies git cmake; then
        echo -e "${RED}Missing dependencies for building from source${NC}"
        echo -e "${YELLOW}Install requirements:${NC}"
        echo "  1. Xcode Command Line Tools: xcode-select --install"
        echo "  2. CMake: brew install cmake"
        exit 1
    fi
    
    # Clone if needed
    if [ ! -d "whisper.cpp/source" ]; then
        echo -e "${BLUE}Cloning whisper.cpp repository...${NC}"
        git clone "$WHISPER_GIT_REPO" whisper.cpp/source
    fi
    
    cd whisper.cpp/source
    
    # Checkout specific version
    echo -e "${BLUE}Checking out version $WHISPER_GIT_TAG...${NC}"
    git fetch origin
    git checkout "$WHISPER_GIT_TAG"
    
    # Build
    echo -e "${BLUE}Building whisper.cpp with CMake...${NC}"
    mkdir -p build
    cd build
    
    # Use configuration from versions.conf
    cmake .. $WHISPER_CMAKE_FLAGS \
        -DCMAKE_INSTALL_PREFIX="$(cd ../.. && pwd)/whisper.cpp/bin" \
        2>&1 | grep -E "(error|Building|Configuring|CMake)" || true
    
    make -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)" || {
        echo -e "${YELLOW}Parallel build failed, trying sequential build...${NC}"
        make
    }
    
    # Install binaries to bin directory
    echo -e "${BLUE}Installing binaries...${NC}"
    cd ..
    # Copy main executables to bin
    for exe in build/bin/* build/*.exe build/main build/stream build/command; do
        if [ -f "$exe" ] && [ -x "$exe" ]; then
            cp "$exe" ../bin/ 2>/dev/null || true
        fi
    done
    
    cd ../..

    rm -rf whisper.cpp/source
    
    echo -e "${GREEN}✓ whisper.cpp built from source${NC}"
}

# Setup whisper.cpp from prebuilt binaries (Linux/Windows)
setup_whisper_from_download() {
    echo -e "${BLUE}Downloading whisper.cpp binaries...${NC}"
    
    local WHISPER_URL=""
    
    if [ "$OS_TYPE" = "linux" ] && [ "$ARCH_TYPE" = "x86_64" ]; then
        WHISPER_URL="$WHISPER_LINUX_X64_URL"
    elif [ "$OS_TYPE" = "linux" ] && [ "$ARCH_TYPE" = "arm64" ]; then
        WHISPER_URL="$WHISPER_LINUX_ARM64_URL"
    elif [ "$OS_TYPE" = "windows" ]; then
        WHISPER_URL="$WHISPER_WINDOWS_URL"
    else
        echo -e "${RED}No whisper.cpp binary available for $OS_TYPE/$ARCH_TYPE${NC}"
        return 1
    fi
    
    if [ -z "$WHISPER_URL" ]; then
        echo -e "${RED}Could not determine whisper.cpp release URL${NC}"
        return 1
    fi
    
    local WHISPER_ARCHIVE="whisper-$OS_TYPE-$ARCH_TYPE.zip"
    download_file "$WHISPER_URL" "$WHISPER_ARCHIVE"
    mkdir -p whisper.cpp/bin
    extract_archive "$WHISPER_ARCHIVE" whisper.cpp/bin
    rm "$WHISPER_ARCHIVE"
    
    echo -e "${GREEN}✓ whisper.cpp binaries installed${NC}"
}

# Main setup
echo -e "${BLUE}Starting setup process...${NC}"
setup_llama || echo -e "${YELLOW}⚠ llama.cpp setup had issues${NC}"
setup_whisper || echo -e "${YELLOW}⚠ whisper.cpp setup had issues${NC}"

# Initialize Git hooks for future updates
if command_exists git && [ -d .git ]; then
    echo ""
    echo -e "${BLUE}Initializing Git hooks...${NC}"
    if [ -f "init-hooks.sh" ]; then
        bash init-hooks.sh
    fi
fi

echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo -e "${BLUE}Next steps:${NC}"
echo "1. Download models: ./download-models.sh"
echo "2. Verify binaries: ls -la llama.cpp/bin/ whisper.cpp/bin/"
echo "3. Test: ./llama.cpp/bin/llama --help"
echo "4. Run models: see README.md for usage examples"
echo ""
echo -e "${YELLOW}Tips:${NC}"
echo "- To update versions, edit: versions.conf"
echo "- For custom builds, modify: setup.sh"
echo "- On macOS, source builds ensure best compatibility"
