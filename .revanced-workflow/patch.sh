#!/bin/bash
set -e

echo "🔧 STARTING PATCH SCRIPT (Debug Mode Enabled)"
echo "📁 Working directory: $(pwd)"

mkdir -p revanced
cd revanced || { echo "❌ Failed to enter revanced directory"; exit 1; }

# CLI
echo "🌐 Fetching ReVanced CLI (.jar) release..."
CLI_JSON=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest)
echo "📄 CLI release info: $(echo "$CLI_JSON" | jq -r '.name, .tag_name')"

CLI_URL=$(echo "$CLI_JSON" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
echo "📥 CLI Download URL: $CLI_URL"
wget -q "$CLI_URL" -O cli.jar || { echo "❌ CLI download failed"; exit 1; }

# PATCHES
echo "🌐 Fetching ReVanced Patches (.rvp) release..."
PATCHES_JSON=$(curl -s https://api.github.com/repos/ReVanced/revanced-patches/releases/latest)
echo "📄 Patches release info: $(echo "$PATCHES_JSON" | jq -r '.name, .tag_name')"

PATCHES_URL=$(echo "$PATCHES_JSON" | jq -r '.assets[] | select(.name | endswith(".rvp")) | .browser_download_url')
echo "📥 Patches Download URL: $PATCHES_URL"
wget -q "$PATCHES_URL" -O patches.rvp || { echo "❌ Patches download failed"; exit 1; }

# INTEGRATIONS
echo "🌐 Fetching ReVanced Integrations (.apk)..."
INTEGRATION_JSON=$(curl -s https://api.github.com/repos/ReVanced/revanced-integrations/releases/latest)
echo "📄 Integrations release info: $(echo "$INTEGRATION_JSON" | jq -r '.name, .tag_name')"

INTEGRATION_URL=$(echo "$INTEGRATION_JSON" | jq -r '.assets[] | select(.name | endswith(".apk")) | .browser_download_url')
echo "📥 Integration APK URL: $INTEGRATION_URL"
wget -q "$INTEGRATION_URL" -O integrations.apk || { echo "❌ Integration APK download failed"; exit 1; }

# YouTube Version
echo "🔍 Fetching latest compatible YouTube version..."
YTVERSION=$(curl -s https://api.revanced.app/v2/patches \
  | jq -r '.[] | select(.compatiblePackages[].name == "com.google.android.youtube") | .compatiblePackages[].versions[0]')

if [[ -z "$YTVERSION" ]]; then
  echo "❌ Failed to fetch compatible YouTube version"
  exit 1
fi

echo "✅ Latest compatible YouTube version: $YTVERSION"

# YouTube APK
echo "⬇️ Downloading YouTube APK..."
YOUTUBE_APK="youtube.apk"
YT_DL_URL="https://github.com/AlexW750/apkmirror-scraper/releases/latest/download/Youtube-${YTVERSION}.apk"
echo "📥 YouTube APK URL: $YT_DL_URL"
wget -q "$YT_DL_URL" -O "$YOUTUBE_APK" || {
  echo "❌ YouTube APK download failed from $YT_DL_URL"
  exit 1
}

# Patching
echo "🧩 Running ReVanced CLI patch command..."
echo "📂 Files in directory:"
ls -lh

java -jar cli.jar patch \
  -p patches.rvp \
  -m integrations.apk \
  -o ../revanced.apk \
  "$YOUTUBE_APK" || {
    echo "❌ Patching failed"
    exit 1
}

echo "✅ Patching complete!"
ls -lh ../revanced.apk
cd ..

