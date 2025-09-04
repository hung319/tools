#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="2.72"
URL="https://ftp.gnu.org/gnu/autoconf/autoconf-$VER.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "autoconf-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "autoconf-$VER"
tar -xf "autoconf-$VER.tar.gz"
cd "autoconf-$VER"

./configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo "✅ autoconf-$VER installed into $PREFIX"
