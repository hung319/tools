#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.18.2"
URL="https://github.com/strukturag/libheif/releases/download/v$VER/libheif-$VER.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libheif-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

# --- Extract ---
rm -rf "libheif-$VER"
tar -xf "libheif-$VER.tar.gz"
cd "libheif-$VER"

# --- Build with CMake ---
rm -rf build
mkdir build
cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"
make install

echo "✅ Done! libheif $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion libheif"
