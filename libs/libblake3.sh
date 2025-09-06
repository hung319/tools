#!/usr/bin/env bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
REPO="https://github.com/BLAKE3-team/BLAKE3.git"
BUILD_DIR="$SRC_DIR/BLAKE3/c/build"

# --- Prepare ---
mkdir -p "$PREFIX" "$SRC_DIR"

# --- Fetch source ---
if [ ! -d "$SRC_DIR/BLAKE3" ]; then
    git clone "$REPO" "$SRC_DIR/BLAKE3"
else
    cd "$SRC_DIR/BLAKE3"
    git pull
fi

# --- Build with CMake ---
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
make -j"$(nproc)"
make install

echo "✅ libblake3 installed to $PREFIX"
echo "👉 Remember to add:"
echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH'
echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH'
