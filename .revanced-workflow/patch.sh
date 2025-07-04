#!/bin/bash
set -e

echo "🔧 STARTING PATCH SCRIPT (Minimal Mode)"
echo "📁 Working directory: $(pwd)"

mkdir -p revanced
cd revanced || { echo "❌ Failed to enter revanced directory"; exit 1; }

# ReVanced CLI
echo "🌐 Fetching ReVanced CLI (.jar)..."
CLI_JSON=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest)
echo "📄 CLI release: $(echo "$CLI_JSON" | jq -r '.name, .tag_name')"

CLI_URL=$(echo "$CLI_JSON" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
echo "📥 CLI URL: $CLI_URL"
wget -q "$CLI_URL" -O cli.jar || { echo "❌ CLI download failed"; exit 1; }

# ReVanced Patches (.rvp)
echo "🌐 Fetching ReVanced Patches (.rvp)..."
PATCHES_JSON=$(curl -s https://api.github.com/repos/ReVanced/revanced-patches/releases/latest)
echo "📄 Patches release: $(echo "$PATCHES_JSON" | jq -r '.name, .tag_name')"

PATCHES_URL=$(echo "$PATCHES_JSON" | jq -r '.assets[] | select(.name | endswith(".rvp")) | .browser_download_url')
echo "📥 Patches URL: $PATCHES_URL"
wget -q "$PATCHES_URL" -O patches.rvp || { echo "❌ Patches download failed"; exit 1; }

# Get latest compatible YouTube version
echo "🔍 Fetching latest compatible YouTube version..."
YTVERSION=$(curl -s https://api.revanced.app/v2/patches \
  | jq -r '.[] | select(.compatiblePackages[].name == "com.google.android.youtube") | .compatiblePackages[].versions[0]')

if [[ -z "$YTVERSION" ]]; then
  echo "❌ Could not determine compatible YouTube version"
  exit 1
fi
echo "✅ Latest YouTube version: $YTVERSION"

# Download YouTube APK (adjust source as needed)
echo "⬇️ Downloading YouTube APK..."
YOUTUBE_APK="youtube.apk"
YT_DL_URL="https://github.com/AlexW750/apkmirror-scraper/releases/latest/download/Youtube-${YTVERSION}.apk"
echo "📥 YouTube APK URL: $YT_DL_URL"
wget -q "$YT_DL_URL" -O "$YOUTUBE_APK" || {
  echo "❌ YouTube APK download failed from $YT_DL_URL"
  exit 1
}

# Run patcher
echo "🧩 Running ReVanced CLI patch..."
echo "📂 Directory contents before patching:"
ls -lh

java -jar cli.jar patch \
  -p patches.rvp \
  -o ../revanced.apk \
  "$YOUTUBE_APK" || {
    echo "❌ Patching failed"
    exit 1
}

echo "✅ Patching completed successfully!"
ls -lh ../revanced.apk
cd ..

