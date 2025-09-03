#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.1.4"
URL="https://www.x.org/releases/individual/lib/libXmu-$VER.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libXmu-$VER.tar.xz" ]; then
  curl -LO "$URL"
fi

rm -rf "libXmu-$VER"
tar -xf "libXmu-$VER.tar.xz"
cd "libXmu-$VER"

./configure --prefix="$PREFIX" --disable-dependency-tracking
make -j"$(nproc)"
make install

echo "✅ Done! libXmu installed into $PREFIX"
