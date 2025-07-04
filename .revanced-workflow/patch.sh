#!/bin/bash
set -e

echo "🔧 STARTING ReVanced Patch Script"

# 1. Setup working directory
WORKDIR=$(pwd)
echo "📁 Working directory: $WORKDIR"

# 2. Download ReVanced CLI
echo "🌐 Fetching ReVanced CLI..."
CLI_URL=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest \
  | grep browser_download_url \
  | grep 'all.jar' \
  | cut -d '"' -f 4)
curl -L -o revanced-cli.jar "$CLI_URL"

# 3. Download ReVanced Patches
echo "🌐 Fetching ReVanced Patches..."
PATCHES_URL=$(curl -s https://api.github.com/repos/ReVanced/revanced-patches/releases/latest \
  | grep browser_download_url \
  | grep '.rvp' \
  | cut -d '"' -f 4)
curl -L -o patches.rvp "$PATCHES_URL"

# 4. Extract latest compatible YouTube version
echo "🔍 Extracting latest compatible YouTube version..."
YT_VERSION=$(java -jar revanced-cli.jar list-patches --with-packages --with-versions --with-options patches.rvp \
  | awk '
    BEGIN { found = 0 }
    /Package name: com\.google\.android\.youtube/ { found = 1 }
    found && /Compatible versions:/ { capture = 1; next }
    capture && /^[ \t]*[0-9]+\.[0-9]+\.[0-9]+/ { versions[++count] = $1 }
    capture && NF == 0 { exit }
    END {
      latest = "0.0.0"
      for (i = 1; i <= count; i++) {
        split(versions[i], a, ".")
        split(latest, b, ".")
        if (a[1] > b[1] || (a[1] == b[1] && a[2] > b[2]) || (a[1] == b[1] && a[2] == b[2] && a[3] > b[3])) {
          latest = versions[i]
        }
      }
      print latest
    }')
echo "✅ Latest compatible YouTube version: $YT_VERSION"

# 5. Function to scrape YouTube APK from APKMirror
get_latest_youtube_apk() {
  echo "🌐 Scraping APKMirror for YouTube APK version $YT_VERSION..."

  # Search for version page
  YT_PAGE=$(curl -s "https://www.apkmirror.com/uploads/?q=youtube" \
    | grep -oP "/apk/google-inc/youtube/youtube-${YT_VERSION//./-}[^\"/]+" \
    | head -n 1)

  if [ -z "$YT_PAGE" ]; then
    echo "❌ Could not find APKMirror page for version $YT_VERSION"
    exit 1
  fi

  YT_URL="https://www.apkmirror.com$YT_PAGE"
  echo "🔗 YouTube version page: $YT_URL"

  # Find variant (non-bundle APK)
  VARIANT_PAGE=$(curl -s "$YT_URL" \
    | grep -oP '/apk/google-inc/youtube/[^"]+/download/[^"]*' \
    | grep -vE 'bundle|xapk' \
    | head -n 1)

  if [ -z "$VARIANT_PAGE" ]; then
    echo "❌ Could not find a valid APK variant for patching"
    exit 1
  fi

  DOWNLOAD_PAGE="https://www.apkmirror.com$VARIANT_PAGE"
  echo "🔗 Download page: $DOWNLOAD_PAGE"

  # Get direct download link
  FINAL_DOWNLOAD=$(curl -s "$DOWNLOAD_PAGE" \
    | grep -oP 'href="(/wp-content/themes/APKMirror/download.php\?[^"]+)' \
    | cut -d'"' -f2 | head -n1)

  if [ -z "$FINAL_DOWNLOAD" ]; then
    echo "❌ Could not extract final APK download link"
    exit 1
  fi

  APK_LINK="https://www.apkmirror.com$FINAL_DOWNLOAD"
  echo "📥 Downloading APK from: $APK_LINK"
  curl -L -o youtube.apk "$APK_LINK"
  echo "✅ YouTube APK saved as youtube.apk"
}

# 6. Download the APK
get_latest_youtube_apk

# 7. Patch YouTube
echo "🛠️ Patching YouTube..."
java -jar revanced-cli.jar patch \
  -p patches.rvp \
  -o revanced-youtube.apk \
  youtube.apk

echo "✅ Done! Patched APK: revanced-youtube.apk"



