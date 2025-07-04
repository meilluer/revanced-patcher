#!/bin/bash
set -e

echo "🔧 STARTING ReVanced Patch Script (Minimal Mode)"
echo "📁 Current working directory: $(pwd)"

mkdir -p revanced
cd revanced || { echo "❌ Failed to enter 'revanced' directory"; exit 1; }

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

# === 1. Download ReVanced CLI ===
echo "🌐 Fetching ReVanced CLI (.jar)..."
CLI_JSON=$(curl -s -H "Accept: application/vnd.github+json" \
                   -H "User-Agent: $USER_AGENT" \
                   https://api.github.com/repos/ReVanced/revanced-cli/releases/latest)

if ! echo "$CLI_JSON" | jq . > /dev/null 2>&1; then
  echo "❌ Failed to parse CLI JSON response"
  echo "$CLI_JSON" | head -n 20
  exit 1
fi

CLI_URL=$(echo "$CLI_JSON" | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
echo "📥 CLI Download URL: $CLI_URL"
wget -q "$CLI_URL" -O cli.jar || { echo "❌ Failed to download CLI"; exit 1; }

# === 2. Download ReVanced Patches (.rvp) ===
echo "🌐 Fetching ReVanced Patches (.rvp)..."
PATCHES_JSON=$(curl -s -H "Accept: application/vnd.github+json" \
                      -H "User-Agent: $USER_AGENT" \
                      https://api.github.com/repos/ReVanced/revanced-patches/releases/latest)

if ! echo "$PATCHES_JSON" | jq . > /dev/null 2>&1; then
  echo "❌ Failed to parse Patches JSON response"
  echo "$PATCHES_JSON" | head -n 20
  exit 1
fi

PATCHES_URL=$(echo "$PATCHES_JSON" | jq -r '.assets[] | select(.name | endswith(".rvp")) | .browser_download_url')
echo "📥 Patches Download URL: $PATCHES_URL"
wget -q "$PATCHES_URL" -O patches.rvp || { echo "❌ Failed to download patches"; exit 1; }

# === 3. Get compatible YouTube version ===
echo "🔍 Fetching latest compatible YouTube version..."
YT_API_JSON=$(curl -Ls -H "User-Agent:" https://api.revanced.app/patches)
echo "📦 Raw YouTube patch data:"
echo "$YT_API_JSON" | head -n 20



if ! echo "$YT_API_JSON" | jq . > /dev/null 2>&1; then
  echo "❌ Failed to parse YouTube patch data"
  echo "$YT_API_JSON" | head -n 20
  exit 1
fi

YTVERSION=$(echo "$YT_API_JSON" | jq -r '.[] | select(.compatiblePackages[].name == "com.google.android.youtube") | .compatiblePackages[].versions[0]')

if [[ -z "$YTVERSION" ]]; then
  echo "❌ Could not find compatible YouTube version"
  exit 1
fi
echo "✅ Latest compatible YouTube version: $YTVERSION"

# === 4. Download YouTube APK ===
echo "⬇️ Downloading YouTube APK..."
YOUTUBE_APK="youtube.apk"
YT_DL_URL="https://github.com/AlexW750/apkmirror-scraper/releases/latest/download/Youtube-${YTVERSION}.apk"
echo "📥 YouTube APK URL: $YT_DL_URL"
wget -q "$YT_DL_URL" -O "$YOUTUBE_APK" || {
  echo "❌ YouTube APK download failed from $YT_DL_URL"
  exit 1
}

# === 5. Patch YouTube APK ===
echo "🧩 Running ReVanced patcher..."
echo "📂 Files before patching:"
ls -lh

java -jar cli.jar patch \
  -p patches.rvp \
  -o ../revanced.apk \
  "$YOUTUBE_APK" || {
    echo "❌ Patching failed"
    exit 1
}

echo "✅ Patch complete!"
ls -lh ../revanced.apk

cd ..



