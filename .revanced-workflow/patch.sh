#!/bin/bash
set -e

echo "🔧 STARTING ReVanced Patch Script (Minimal Mode)"
echo "📁 Current working directory: $(pwd)"

# Define variables
WORK_DIR=revanced-temp
YT_VERSION="19.25.35"  # 👈 Update this manually if needed
CLI_VERSION="v5.0.1"
PATCHES_VERSION="v5.30.0"
USER_AGENT="Mozilla/5.0"

# Setup working directory
rm -rf $WORK_DIR
mkdir -p $WORK_DIR
cd $WORK_DIR

# Download CLI
echo "🌐 Fetching ReVanced CLI (.jar)..."
CLI_URL="https://github.com/ReVanced/revanced-cli/releases/download/${CLI_VERSION}/revanced-cli-${CLI_VERSION#v}-all.jar"
echo "📥 CLI Download URL: $CLI_URL"
curl -LO "$CLI_URL"

# Download patches
echo "🌐 Fetching ReVanced Patches (.rvp)..."
PATCHES_URL="https://github.com/ReVanced/revanced-patches/releases/download/${PATCHES_VERSION}/patches-${PATCHES_VERSION#v}.rvp"
echo "📥 Patches Download URL: $PATCHES_URL"
curl -LO "$PATCHES_URL"

# Download YouTube APK from apkmirror (headless / minimal logic)
echo "📥 Downloading YouTube APK version $YT_VERSION..."
APK_URL="https://example.com/youtube-$YT_VERSION.apk"  # ❗ REPLACE THIS with a direct link or use apkmirror-scraper
curl -L -o youtube.apk "$APK_URL"

# Patch the APK
echo "🛠️ Patching YouTube..."
java -jar revanced-cli-*-all.jar \
  patch \
  --patch-bundle patches-*.rvp \
  --keystore none \
  --input youtube.apk \
  --output revanced.apk

# Move output
mv revanced.apk ../patched.apk
cd ..
rm -rf $WORK_DIR

echo "✅ Done. Patched APK saved to patched.apk"


