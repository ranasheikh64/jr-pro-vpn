#!/bin/bash
# ==============================================================================
# JRonix VPN - macOS ".dmg" Disk Image Builder
# Creates the standard macOS Drag-to-Applications installer disk image
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "${SCRIPT_DIR}/../../app" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"
VERSION="1.0.1"
DMG_NAME="JRonix-VPN-macOS-v${VERSION}.dmg"

echo "🚀 [1/3] Building Flutter macOS Release App..."
cd "${APP_DIR}"
flutter pub get
flutter build macos --release

APP_PATH="${APP_DIR}/build/macos/Build/Products/Release/JRonix VPN.app"
if [ ! -d "${APP_PATH}" ]; then
    APP_PATH=$(find "${APP_DIR}/build/macos/Build/Products/Release" -name "*.app" -maxdepth 1 | head -n 1)
fi

if [ -z "${APP_PATH}" ] || [ ! -d "${APP_PATH}" ]; then
    echo "❌ [ERROR] Could not find compiled .app bundle!"
    exit 1
fi

echo "📦 Found App at: ${APP_PATH}"
mkdir -p "${OUTPUT_DIR}"

DMG_STAGE=$(mktemp -d /tmp/jronix_dmg_XXXXXX)
echo "🚚 [2/3] Preparing Disk Image contents..."
cp -R "${APP_PATH}" "${DMG_STAGE}/"
ln -s /Applications "${DMG_STAGE}/Applications"

echo "📀 [3/3] Creating Apple Disk Image (.dmg)..."
FINAL_DMG="${OUTPUT_DIR}/${DMG_NAME}"
rm -f "${FINAL_DMG}"

hdiutil create \
    -volname "JRonix VPN" \
    -srcfolder "${DMG_STAGE}" \
    -ov \
    -format UDZO \
    "${FINAL_DMG}"

rm -rf "${DMG_STAGE}"

echo "=============================================================================="
echo "✅ SUCCESS! macOS Disk Image (.dmg) created at:"
echo "${FINAL_DMG}"
echo "=============================================================================="
