#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

VER="5.2.2"
URL="https://downloads.sourceforge.net/project/giflib/giflib-${VER}.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "giflib-${VER}.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "giflib-${VER}"
tar -xf "giflib-${VER}.tar.gz"
cd "giflib-${VER}"

# build chỉ lib và tools, bỏ qua doc
make -j"$(nproc)" libgif.a libutil.a giftext giftool

# cài thủ công
mkdir -p "$PREFIX/lib" "$PREFIX/include" "$PREFIX/bin"
cp -av libgif.a libutil.a "$PREFIX/lib/"
cp -av gif_lib.h "$PREFIX/include/"
cp -av giftext giftool "$PREFIX/bin/" 2>/dev/null || true

echo "✅ Done! giflib-${VER} installed into $PREFIX (docs skipped)"
