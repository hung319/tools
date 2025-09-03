#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.3.0"
URL="https://www.x.org/releases/individual/lib/libXt-$VER.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libXt-$VER.tar.xz" ]; then
  curl -LO "$URL"
fi

# --- Extract ---
rm -rf "libXt-$VER"
tar -xf "libXt-$VER.tar.xz"
cd "libXt-$VER"

# --- Build in separate folder ---
rm -rf build
mkdir build
cd build

../configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libXt $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion xt"
