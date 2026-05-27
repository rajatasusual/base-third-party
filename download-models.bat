@echo off
setlocal enabledelayedexpansion

REM Windows model download script
REM Reads configuration from versions.conf

echo.
echo Downloading models for llama.cpp and whisper.cpp
echo.

REM Check if versions.conf exists
if not exist "versions.conf" (
    echo Error: versions.conf not found!
    pause
    exit /b 1
)

REM Create directories
if not exist "llama.cpp\model" mkdir llama.cpp\model
if not exist "whisper.cpp\model" mkdir whisper.cpp\model

REM Extract model URLs from versions.conf
for /f "tokens=2 delims==" %%a in ('findstr "WHISPER_MODEL_URL" versions.conf') do (
    set "WHISPER_URL=%%a"
)
set "WHISPER_URL=!WHISPER_URL:"=!"

for /f "tokens=2 delims==" %%a in ('findstr "WHISPER_MODEL_NAME" versions.conf') do (
    set "WHISPER_NAME=%%a"
)
set "WHISPER_NAME=!WHISPER_NAME:"=!"

REM Download Whisper base.en model
echo ============================================================
echo Setting up whisper.cpp model
echo ============================================================

if exist "whisper.cpp\model\!WHISPER_NAME!" (
    echo ^✓ Model already exists: !WHISPER_NAME!
) else (
    if not "!WHISPER_URL!"=="" (
        echo Downloading: !WHISPER_NAME!
        powershell -NoProfile -Command "Write-Host 'URL: !WHISPER_URL!'; (New-Object Net.WebClient).DownloadFile('!WHISPER_URL!', 'whisper.cpp\model\!WHISPER_NAME!')"
        echo ^✓ Downloaded: !WHISPER_NAME!
    ) else (
        echo Warning: WHISPER_MODEL_URL not configured in versions.conf
    )
)

REM llama.cpp model note
echo.
echo ============================================================
echo Setting up llama.cpp model
echo ============================================================
echo Note: llama.cpp model needs to be configured manually
echo Check versions.conf for LLAMA_MODEL_URL
echo Models available at: https://huggingface.co/models
echo.

echo ============================================================
echo Model setup complete!
echo ============================================================
echo.
pause
