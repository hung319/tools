#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

VER="1.6.43"
URL="https://download.sourceforge.net/libpng/libpng-${VER}.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libpng-${VER}.tar.xz" ]; then
  curl -LO "$URL"
fi

rm -rf "libpng-${VER}"
tar -xf "libpng-${VER}.tar.xz"
cd "libpng-${VER}"

./configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libpng-${VER} installed into $PREFIX"
