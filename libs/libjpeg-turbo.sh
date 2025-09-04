#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

VER="3.0.1"
URL="https://downloads.sourceforge.net/libjpeg-turbo/libjpeg-turbo-${VER}.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libjpeg-turbo-${VER}.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "libjpeg-turbo-${VER}"
tar -xf "libjpeg-turbo-${VER}.tar.gz"
cd "libjpeg-turbo-${VER}"

cmake -B build -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build -j"$(nproc)"
cmake --install build

echo "✅ Done! libjpeg-turbo-${VER} installed into $PREFIX"
