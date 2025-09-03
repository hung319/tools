#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
XAU_VERSION="1.0.11"
XAU_URL="https://www.x.org/releases/individual/lib/libXau-$XAU_VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libXau-$XAU_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXau $XAU_VERSION..."
    curl -LO "$XAU_URL"
fi

rm -rf "libXau-$XAU_VERSION"
tar -xf "libXau-$XAU_VERSION.tar.gz"
cd "libXau-$XAU_VERSION"

./configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install
