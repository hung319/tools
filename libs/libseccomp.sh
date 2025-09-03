#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="2.5.5"
URL="https://github.com/seccomp/libseccomp/releases/download/v$VER/libseccomp-$VER.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libseccomp-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

# --- Extract ---
rm -rf "libseccomp-$VER"
tar -xf "libseccomp-$VER.tar.gz"
cd "libseccomp-$VER"

# --- Build ---
rm -rf build
mkdir build
cd build

../configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libseccomp $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion libseccomp"
