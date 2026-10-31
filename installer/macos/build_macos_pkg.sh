#!/bin/bash
# ==============================================================================
# JRonix VPN - macOS ".pkg" Wizard Installer Builder
# Creates the native Apple macOS "Continue > Continue > Install" installer package
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/../../app" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"
VERSION="1.0.1"
PKG_NAME="JRonix-VPN-macOS-Installer-v${VERSION}.pkg"

echo "🚀 [1/4] Building Flutter macOS Release App..."
cd "${APP_DIR}"
flutter clean
flutter pub get
flutter build macos --release

APP_PATH="${APP_DIR}/build/macos/Build/Products/Release/JRonix VPN.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "⚠️ App bundle not found with exact space, checking alternate name..."
    APP_PATH=$(find "${APP_DIR}/build/macos/Build/Products/Release" -name "*.app" -maxdepth 1 | head -n 1)
fi

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    echo "❌ [ERROR] Could not find compiled .app bundle!"
    exit 1
fi

echo "📦 Found App at: ${APP_PATH}"

mkdir -p "${OUTPUT_DIR}"
echo "🎁 [2/2] Generating macOS Installer Package for /Applications..."
FINAL_PKG="${OUTPUT_DIR}/${PKG_NAME}"
productbuild \
    --component "${APP_PATH}" \
    /Applications \
    "${FINAL_PKG}"

echo "=============================================================================="
echo "✅ SUCCESS! Native macOS Installer (.pkg) created at:"
echo "${FINAL_PKG}"
echo "Users can double-click this .pkg file and follow the standard Apple 'Continue > Continue > Install' wizard!"
echo "=============================================================================="
