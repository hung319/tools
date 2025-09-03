#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.2.4"
URL="https://www.x.org/releases/individual/lib/libSM-$VER.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libSM-$VER.tar.xz" ]; then
  curl -LO "$URL"
fi

# --- Extract ---
rm -rf "libSM-$VER"
tar -xf "libSM-$VER.tar.xz"
cd "libSM-$VER"

# --- Build in separate folder ---
rm -rf build
mkdir build
cd build

../configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libSM $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion sm"
