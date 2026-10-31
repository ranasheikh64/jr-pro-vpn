@echo off
REM ============================================================================
REM JRonix VPN - Windows Release Build & Inno Setup Installer Generator
REM ============================================================================
setlocal enabledelayedexpansion

echo [1/3] Navigating to Flutter App directory...
cd /d "%~dp0..\..\app"

echo [2/3] Building Flutter Windows Release Bundle...
call flutter clean
call flutter pub get
call flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter Windows build failed! Please check your Visual Studio C++ setup.
    pause
    exit /b %ERRORLEVEL%
)

echo [3/3] Compiling Inno Setup Installer...
cd /d "%~dp0"

REM Check standard Inno Setup 6 installation paths
set "ISCC_PATH="
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
) else if exist "C:\Program Files\Inno Setup 6\ISCC.exe" (
    set "ISCC_PATH=C:\Program Files\Inno Setup 6\ISCC.exe"
)

if "%ISCC_PATH%"=="" (
    echo [WARNING] ISCC.exe (Inno Setup) not found in standard paths.
    echo Please install Inno Setup 6 from: https://jrsoftware.org/isdl.php
    echo Or manually compile: "%~dp0inno_setup.iss" using Inno Setup Compiler GUI.
    pause
    exit /b 1
)

"%ISCC_PATH%" "%~dp0inno_setup.iss"

if %ERRORLEVEL% EQU 0 (
    echo ============================================================================
    echo SUCCESS! Windows Setup Wizard generated at:
    echo %~dp0output\JRonix-VPN-Windows-Setup-v1.0.1.exe
    echo ============================================================================
) else (
    echo [ERROR] Inno Setup compilation failed!
)

pause
