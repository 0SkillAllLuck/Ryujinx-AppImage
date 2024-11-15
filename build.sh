#!/bin/sh
set -u

# Setup variables
APP="Ryujinx"
REPOSITORY="GreemDev/Ryujinx"

# Setup directories
buildDir="./build"
if [ -d "$buildDir" ]; then
  rm -rf "$buildDir"
fi
mkdir -p "$buildDir"

# Download appimagetool
wget -q https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage -O "$buildDir/appimagetool"
chmod a+x "$buildDir/appimagetool"

# Download ryujinx release information
echo "Downloading Ryujinx Release information"
releaseURL=$(wget -q https://api.github.com/repos/$REPOSITORY/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi "https:\/\/.*linux_x64\.tar\.gz$" | head -1)
version="$(echo "$releaseURL" | awk -F"/" '{print $(NF-1)}')"

# Download appimage release information
echo "Downloading AppImage Release information"
appImageReleaseURL=$(wget -q https://api.github.com/repos/0SkillAllLuck/Ryujinx-AppImage/releases -O - | sed 's/[()",{} ]/\n/g' | grep -oi "https:\/\/.*x86_64\.AppImage$" | head -1)
appImageVersion="$(echo "$appImageReleaseURL" | awk -F"/" '{print $(NF-1)}')"
# Check if the AppImage is the same version as the release
if [ "$appImageVersion" = "$version" ]; then
  echo "AppImage already up to date"
  exit 0
fi

# Download ryujinx release
echo "Downloading Ryujinx version: $version"
wget -q "$releaseURL" -O "$buildDir/ryujinx.tar.gz"
tar xf "$buildDir/ryujinx.tar.gz" -C "$buildDir"

# Create AppDir and download desktop and icon files
appDir="$buildDir/$APP.AppDir"
mkdir -p "$appDir/usr/bin"
mv "$buildDir/publish/"* "$appDir/usr/bin"

# Create desktop and icon files
echo "Downloading desktop and icon files"
wget -q https://raw.githubusercontent.com/$REPOSITORY/master/distribution/linux/Ryujinx.desktop -O "$appDir/$APP.desktop"
wget -q https://raw.githubusercontent.com/$REPOSITORY/master/src/Ryujinx/Ryujinx.ico -O "$appDir/Ryujinx.png"
ln -s "$appDir/Ryujinx.png" "$appDir/.DirIcon"

# Create AppRun
echo "Creating AppRun"
cat >> "$appDir/AppRun" << 'EOF'
#!/bin/sh
CURRENTDIR="$(readlink -f "$(dirname "$0")")"
exec "$CURRENTDIR"/usr/bin/Ryujinx.sh "$@"
EOF
chmod a+x "$appDir/AppRun"

# Build the AppImage
distDir="./dist"
appimageFile="$distDir/$APP-$version-x86_64.AppImage"
mkdir -p "$distDir"
echo "Building AppImage: $appimageFile"
./build/appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 \
  -u "gh-releases-zsync|0SkillAllLuck|Ryujinx-AppImage|latest|*x86_64.AppImage.zsync" \
  "$appDir" "$appimageFile"

# Save version to file
echo "VERSION=$version" > "$distDir/version"