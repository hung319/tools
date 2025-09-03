#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.1.0"
URL="https://github.com/google/brotli/archive/refs/tags/v$VER.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "brotli-$VER.tar.gz" ]; then
  curl -L -o "brotli-$VER.tar.gz" "$URL"
fi

# --- Extract ---
rm -rf "brotli-$VER"
tar -xf "brotli-$VER.tar.gz"
cd "brotli-$VER"

# --- Build ---
rm -rf build
mkdir build
cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_TESTING=OFF

make -j"$(nproc)"
make install

echo "✅ Done! Brotli $VER installed into $PREFIX"
echo "   → libs: libbrotlienc, libbrotlicommon, libbrotlidec"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --list-all | grep brotli"
