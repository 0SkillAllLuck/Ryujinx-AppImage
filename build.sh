#!/bin/sh
set -u

# Setup variables
APP="Ryujinx"
REPOSITORY="GreemDev/Ryujinx"

# Setup directories
buildDir="./build"
appDir="$buildDir/$APP.AppDir"
distDir="./dist"
if [ -d "$buildDir" ]; then
  rm -rf "$buildDir"
fi
mkdir -p "$buildDir"
mkdir -p "$appDir/usr/bin"
mkdir -p "$distDir"

# Download ryujinx release information
echo "Downloading Ryujinx Release information"
releaseURL=$(wget -q https://api.github.com/repos/$REPOSITORY/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi "https:\/\/.*linux_x64\.tar\.gz$" | head -1)
releaseVersion="$(echo "$releaseURL" | awk -F"/" '{print $(NF-1)}')"

# Download appimage release information
echo "Downloading AppImage Release information"
appImageReleaseURL=$(wget -q https://api.github.com/repos/0SkillAllLuck/Ryujinx-AppImage/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi "https:\/\/.*x86_64\.AppImage$" | head -1)
appImageVersion="$(echo "$appImageReleaseURL" | awk -F"/" '{print $(NF-1)}')"

# Check if the AppImage is the same version as the release
if [ "$appImageVersion" = "$releaseVersion" ]; then
  echo "AppImage already up to date"
  exit 0
fi

# Download Ryujinx release
echo "Downloading Ryujinx version: $releaseVersion"
wget -q "$releaseURL" -O "$buildDir/ryujinx.tar.gz"
tar xf "$buildDir/ryujinx.tar.gz" -C "$buildDir"

# Downloading AppImage files
echo "Downloading desktop and icon files"
wget -q https://raw.githubusercontent.com/$REPOSITORY/master/distribution/linux/appimage/AppRun -O "$appDir/AppRun"
wget -q https://raw.githubusercontent.com/$REPOSITORY/master/distribution/linux/Ryujinx.desktop -O "$appDir/$APP.desktop"
wget -q https://raw.githubusercontent.com/$REPOSITORY/master/src/Ryujinx.UI.Common/Resources/Logo_Ryujinx.png -O "$appDir/Ryujinx.png"
chmod +x "$appDir/AppRun"

# Download appimagetool
echo "Downloading appimagetool"
wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O "$buildDir/appimagetool"
chmod a+x "$buildDir/appimagetool"

# Build the AppImage
echo "Building AppImage"
mv "$buildDir/publish/"* "$appDir/usr/bin"
./build/appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 21 \
  -u "gh-releases-zsync|0SkillAllLuck|Ryujinx-AppImage|latest|*x86_64.AppImage.zsync" \
  "$appDir" "$distDir/$APP-$releaseVersion-x86_64.AppImage"

# Save version to file
echo "VERSION=$releaseVersion" > "$distDir/version"