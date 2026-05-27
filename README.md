# Cross-Platform Third-Party Binaries Repository

This repository contains setup scripts to download and run cross-platform binaries for [llama.cpp](https://github.com/ggerganov/llama.cpp) and [whisper.cpp](https://github.com/ggerganov/whisper.cpp).

## Features

- **Cross-Platform Support**: Automatically detects your OS (Linux, macOS, Windows) and CPU architecture (x86_64, ARM64)
- **Smart Build Strategy**:
  - **macOS**: Builds whisper.cpp from source for optimal command-line performance and native support
  - **Linux/Windows**: Downloads pre-compiled binaries for faster setup
- **Centralized Configuration**: All versions and URLs managed in `versions.conf`
- **Model Management**: Includes setup for both llama.cpp and whisper.cpp models
- **Submodule Ready**: Can be used as a Git submodule in other projects

## Supported Platforms

### Operating Systems
- **macOS** (Apple Silicon & Intel) - *whisper.cpp builds from source*
- **Linux** (x86_64 & ARM64) - *downloads prebuilt binaries*
- **Windows** (x86_64) - *downloads prebuilt binaries*

### Architectures
- x86_64 (Intel/AMD)
- ARM64 (Apple Silicon, ARM servers, etc.)

## Prerequisites

### For All Platforms
- **curl** or **wget** (for downloading binaries and models)
- **bash** or **sh** (on Windows, use Git Bash, WSL, or native batch files)
- **zip/unzip** utilities

### For macOS (whisper.cpp source build)
- **Xcode Command Line Tools**: `xcode-select --install`
- **CMake**: `brew install cmake`
- **Git**: Usually comes with Xcode CLT

### Install Prerequisites

**macOS:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install CMake via Homebrew
brew install cmake
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl wget unzip tar build-essential cmake git
```

**Windows (using Git Bash):**
Most tools come pre-installed. Download [Git for Windows](https://git-scm.com/download/win) if needed.

## Quick Start

### 1. Clone or Add as Submodule

**Clone directly:**
```bash
git clone <repository-url> base-third-party
cd base-third-party
```

**Add as submodule:**
```bash
git submodule add <repository-url> third-party
cd third-party
```

### 2. Setup Binaries

**On macOS/Linux/WSL:**
```bash
chmod +x setup.sh download-models.sh
./setup.sh
```

**On Windows (native):**
```batch
setup.bat
```

The setup script will:
- Detect your OS and CPU architecture
- For macOS: Build whisper.cpp from source (ensures compatibility)
- For Linux/Windows: Download pre-compiled binaries
- Create directory structure with binaries in `bin/` subdirectories

### 3. Download Models

**On macOS/Linux/WSL:**
```bash
./download-models.sh
```

**On Windows (native):**
```batch
download-models.bat
```

This will:
- Download whisper base.en model to `whisper.cpp/model/`
- Set up directory for llama.cpp model (manual configuration needed)
- Display available models

## Directory Structure

```
base-third-party/
├── setup.sh                  # Main setup (macOS/Linux)
├── setup.bat                 # Setup for Windows
├── download-models.sh        # Model download (macOS/Linux)
├── download-models.bat       # Model download (Windows)
├── versions.conf             # Configuration - version/URL management
├── .gitignore                # Excludes binaries and models
├── README.md                 # This file
├── llama.cpp/
│   ├── bin/                  # Downloaded/built binaries (git-ignored)
│   ├── source/               # Source code (macOS optional, git-ignored)
│   └── model/
│       └── gemma3-4b-it.gguf (user-provided)
├── whisper.cpp/
│   ├── bin/                  # Downloaded/built binaries (git-ignored)
│   ├── source/               # Source code (macOS, git-ignored)
│   └── model/
│       └── ggml-base.en.bin
```

## Usage

### Running llama.cpp

After setup, run llama.cpp commands using downloaded binaries:

```bash
# Interactive prompt
./llama.cpp/bin/llama -m ./llama.cpp/model/gemma3-4b-it.gguf -p "Hello" -i

# Generate text
./llama.cpp/bin/llama -m ./llama.cpp/model/gemma3-4b-it.gguf -p "Write a story:" -n 100
```

### Running whisper.cpp

After setup and build, transcribe audio:

```bash
# Transcribe audio file
./whisper.cpp/bin/main -m ./whisper.cpp/model/ggml-base.en.bin -f audio.wav

# Output to file
./whisper.cpp/bin/main -m ./whisper.cpp/model/ggml-base.en.bin -f audio.wav -o output.txt
```

## Configuration Management

All versions and URLs are centralized in `versions.conf`:

```bash
# Update a specific version
LLAMA_VERSION="b3835"       # Change version number
WHISPER_VERSION="v1.6.2"    # Change version tag
```

To use different binary sources:

1. Edit `versions.conf`
2. Update the corresponding `*_URL` variables
3. Re-run `setup.sh` or `setup.bat`

### Building from Source (Optional)

To build llama.cpp from source on any platform:

```bash
# Edit versions.conf
LLAMA_BUILD_METHOD="source"

# Re-run setup
./setup.sh
```

## Using as a Submodule

When using this as a Git submodule in another project:

```bash
# In your main project
git submodule add <repository-url> third-party
cd third-party
./setup.sh          # or setup.bat on Windows
./download-models.sh
```

### Automated CI/CD Integration

For continuous integration pipelines:

```bash
#!/bin/bash
# Initialize submodule
git submodule update --init --recursive

# Setup
cd third-party
./setup.sh
./download-models.sh

# Verify
ls -la llama.cpp/bin whisper.cpp/bin
```

## Troubleshooting

### macOS: "cmake not found"
```bash
# Install CMake
brew install cmake

# Then re-run setup
./setup.sh
```

### macOS: "xcode-select: error"
```bash
# Install Xcode Command Line Tools
xcode-select --install
```

### "Permission denied" running scripts
```bash
# Make scripts executable
chmod +x setup.sh download-models.sh
```

### Binary not found after setup
```bash
# Check what was installed
ls -la llama.cpp/bin/
ls -la whisper.cpp/bin/

# Verify setup completed without errors
./setup.sh
```

### Model download fails
- Check internet connection
- Verify URLs in `versions.conf` are still valid
- Try downloading manually from Hugging Face

### Windows PowerShell issues
- Run Command Prompt as Administrator
- Or use Git Bash: `bash setup.sh`
- Or use WSL: Windows Subsystem for Linux

## Advanced Customization

### Custom CMake Flags (macOS source builds)

Edit `versions.conf`:
```bash
WHISPER_CMAKE_FLAGS="-DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0"
```

Then re-run:
```bash
./setup.sh
```

### Building Different Versions

Update `versions.conf` with desired version tags:

```bash
# For llama.cpp: https://github.com/ggerganov/llama.cpp/releases
LLAMA_GIT_TAG="b3900"

# For whisper.cpp: https://github.com/ggerganov/whisper.cpp/releases
WHISPER_GIT_TAG="v1.7.0"
```

## Build Strategy

### macOS: whisper.cpp
- **Method**: Source build with CMake
- **Advantages**: 
  - Compiled for your specific architecture
  - Better command-line integration
  - No platform-specific binary size issues
  - Can use latest optimizations
- **Build time**: ~2-5 minutes depending on hardware

### Linux/Windows: Both tools
- **Method**: Download pre-compiled binaries
- **Advantages**:
  - Fast setup
  - No build dependencies required
  - Consistent binary versions

## Performance Notes

- macOS source builds are optimized for the M1/M2/M3 architectures
- Linux binaries support x86_64 and ARM64
- Windows binaries are x86_64 only

## License

This repository contains setup scripts. See the respective projects for licensing:
- [llama.cpp](https://github.com/ggerganov/llama.cpp/blob/master/LICENSE)
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp/blob/master/LICENSE)

## Contributing

To contribute improvements:

1. Test changes on multiple platforms if possible
2. Update scripts and documentation
3. Verify `versions.conf` entries are correct
4. Submit pull requests with clear descriptions

## References

- [llama.cpp GitHub](https://github.com/ggerganov/llama.cpp)
  - [Releases](https://github.com/ggerganov/llama.cpp/releases)
  - [Building from source](https://github.com/ggerganov/llama.cpp#readme)
- [whisper.cpp GitHub](https://github.com/ggerganov/whisper.cpp)
  - [Releases](https://github.com/ggerganov/whisper.cpp/releases)
  - [Building from source](https://github.com/ggerganov/whisper.cpp#building-from-source)
- [Hugging Face Models](https://huggingface.co/models)
  - [Whisper models](https://huggingface.co/ggerganov/whisper.cpp)
- [CMake](https://cmake.org/)
