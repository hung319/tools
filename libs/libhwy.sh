#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.1.0"
URL="https://github.com/google/highway/archive/refs/tags/$VER.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "hwy-$VER.tar.gz" ]; then
  curl -L -o "hwy-$VER.tar.gz" "$URL"
fi

# --- Extract ---
rm -rf "highway-$VER"
tar -xf "hwy-$VER.tar.gz"
cd "highway-$VER"

# --- Build ---
rm -rf build
mkdir build
cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTING=OFF

make -j"$(nproc)"
make install

echo "✅ Done! libhwy $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion hwy"
