#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

VER="2.15"
URL="https://downloads.sourceforge.net/project/lcms/lcms/${VER}/lcms2-${VER}.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "lcms2-${VER}.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "lcms2-${VER}"
tar -xf "lcms2-${VER}.tar.gz"
cd "lcms2-${VER}"

./configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! lcms2-${VER} installed into $PREFIX"
