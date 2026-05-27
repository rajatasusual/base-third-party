@echo off
setlocal enabledelayedexpansion

REM Windows setup script for llama.cpp and whisper.cpp
REM Reads configuration from versions.conf

echo.
echo Setting up cross-platform binaries for llama.cpp and whisper.cpp
echo.

REM Check if versions.conf exists
if not exist "versions.conf" (
    echo Error: versions.conf not found!
    pause
    exit /b 1
)

REM Create directories
if not exist "llama.cpp\bin" mkdir llama.cpp\bin
if not exist "whisper.cpp\bin" mkdir whisper.cpp\bin
if not exist "llama.cpp\model" mkdir llama.cpp\model
if not exist "whisper.cpp\model" mkdir whisper.cpp\model

REM Extract URLs from versions.conf using PowerShell
echo Reading configuration from versions.conf...

REM Download llama.cpp for Windows (using the URL from versions.conf)
echo.
echo ============================================================
echo Downloading llama.cpp binaries...
echo ============================================================
for /f "tokens=2 delims==" %%a in ('findstr "LLAMA_WINDOWS_URL" versions.conf') do (
    set "LLAMA_URL=%%a"
)
set "LLAMA_URL=!LLAMA_URL:"=!"
if not "!LLAMA_URL!"=="" (
    powershell -NoProfile -Command "Write-Host 'Downloading: !LLAMA_URL!'; (New-Object Net.WebClient).DownloadFile('!LLAMA_URL!', 'llama-win64.zip')"
    echo Extracting llama.cpp...
    powershell -NoProfile -Command "Expand-Archive -Path 'llama-win64.zip' -DestinationPath 'llama.cpp\bin' -Force"
    del llama-win64.zip
    echo ^✓ llama.cpp binaries installed
) else (
    echo Warning: Could not find LLAMA_WINDOWS_URL in versions.conf
)

REM Download whisper.cpp for Windows (using the URL from versions.conf)
echo.
echo ============================================================
echo Downloading whisper.cpp binaries...
echo ============================================================
for /f "tokens=2 delims==" %%a in ('findstr "WHISPER_WINDOWS_URL" versions.conf') do (
    set "WHISPER_URL=%%a"
)
set "WHISPER_URL=!WHISPER_URL:"=!"
if not "!WHISPER_URL!"=="" (
    powershell -NoProfile -Command "Write-Host 'Downloading: !WHISPER_URL!'; (New-Object Net.WebClient).DownloadFile('!WHISPER_URL!', 'whisper-win64.zip')"
    echo Extracting whisper.cpp...
    powershell -NoProfile -Command "Expand-Archive -Path 'whisper-win64.zip' -DestinationPath 'whisper.cpp\bin' -Force"
    del whisper-win64.zip
    echo ^✓ whisper.cpp binaries installed
) else (
    echo Warning: Could not find WHISPER_WINDOWS_URL in versions.conf
)

echo.
echo ============================================================
echo Setup complete!
echo ============================================================
echo.
echo Next steps:
echo 1. Run: download-models.bat
echo 2. Verify binaries: dir llama.cpp\bin whisper.cpp\bin
echo 3. For usage, see README.md
echo.
pause
