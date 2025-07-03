#!/bin/bash
set -e

# Create working dir
mkdir -p revanced
cd revanced

# Download latest patches
echo "Fetching latest ReVanced patches..."
patches_url=$(curl -s https://api.github.com/repos/ReVanced/revanced-patches/releases/latest | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
wget -O patches.jar "$patches_url"

# Download latest CLI
echo "Fetching latest ReVanced CLI..."
cli_url=$(curl -s https://api.github.com/repos/ReVanced/revanced-cli/releases/latest | jq -r '.assets[] | select(.name | endswith(".jar")) | .browser_download_url')
wget -O cli.jar "$cli_url"

# Get suggested YouTube version
echo "Getting suggested YouTube version..."
yt_version=$(curl -s https://api.revanced.app/v2/patches | jq -r '.[] | select(.compatiblePackages[].name == "com.google.android.youtube") | .compatiblePackages[].versions[0]')
echo "Latest compatible YouTube version: $yt_version"

# Download YouTube APK from apkmirror (may require manual intervention)
echo "Downloading YouTube APK $yt_version..."
apk_file="youtube.apk"
wget -q "https://github.com/AlexW750/apkmirror-scraper/releases/latest/download/Youtube-${yt_version}.apk" -O "$apk_file" || {
    echo "Failed to download YouTube APK. You must provide it manually or use a custom scraper."
    exit 1
}

# Patch APK
echo "Patching YouTube APK..."
java -jar cli.jar patch \
  --patches patches.jar \
  --merge \
  --exclusive \
  --out ../patched.apk \
  "$apk_file"

cd ..
