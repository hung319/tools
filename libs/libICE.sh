#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.1.1"
URL="https://www.x.org/releases/individual/lib/libICE-$VER.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libICE-$VER.tar.xz" ]; then
  curl -LO "$URL"
fi

# --- Extract ---
rm -rf "libICE-$VER"
tar -xf "libICE-$VER.tar.xz"
cd "libICE-$VER"

# --- Build in separate folder ---
rm -rf build
mkdir build
cd build

../configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libICE $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion ice"
