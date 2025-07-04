#!/bin/bash
set -e

echo "📁 Setting up working directory..."
mkdir -p revanced
cd revanced

echo "🌐 Downloading latest ReVanced CLI..."
CLI_URL=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
wget -q "$CLI_URL" -O cli.jar

echo "🌐 Downloading latest ReVanced Patches..."
PATCHES_URL=$(curl -s https://api.github.com/repos/ReVanced/revanced-patches/releases/latest \
  | jq -r '.assets[] | select(.name | test("patches.*\\.jar$")) | .browser_download_url')

if [[ -z "$PATCHES_URL" ]]; then
  echo "❌ Could not find patches JAR. Check release format."
  exit 1
fi

wget -q "$PATCHES_URL" -O patches.jar

echo "🌐 Downloading latest ReVanced Integrations..."
INTEGRATION_URL=$(curl -s https://api.github.com/repos/ReVanced/revanced-integrations/releases/latest | jq -r '.assets[] | select(.name | endswith(".apk")) | .browser_download_url')
wget -q "$INTEGRATION_URL" -O integrations.apk

echo "🔍 Fetching latest compatible YouTube version..."
YTVERSION=$(curl -s https://api.revanced.app/v2/patches | jq -r '.[] | select(.compatiblePackages[].name == "com.google.android.youtube") | .compatiblePackages[].versions[0]')
echo "✅ Compatible YouTube version: $YTVERSION"

echo "⬇️ Downloading YouTube APK (mock link for demo)..."
YOUTUBE_APK="youtube.apk"
# ⚠️ Replace this with your actual scraper or upload URL if needed
YT_DL_URL="https://github.com/AlexW750/apkmirror-scraper/releases/latest/download/Youtube-${YTVERSION}.apk"

wget -q "$YT_DL_URL" -O "$YOUTUBE_APK" || {
    echo "❌ Failed to download YouTube APK from $YT_DL_URL"
    exit 1
}

echo "🧩 Running patching process..."
java -jar cli.jar patch \
  -b patches.jar \
  -m integrations.apk \
  -o ../revanced.apk \
  "$YOUTUBE_APK"

echo "✅ Patching complete. Output: revanced.apk"
cd ..

