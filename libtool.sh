#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="2.4.7"
URL="https://ftp.gnu.org/gnu/libtool/libtool-$VER.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libtool-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "libtool-$VER"
tar -xf "libtool-$VER.tar.gz"
cd "libtool-$VER"

./configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo "✅ libtool-$VER installed into $PREFIX"
