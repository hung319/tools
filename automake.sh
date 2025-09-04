#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="1.16.5"
URL="https://ftp.gnu.org/gnu/automake/automake-$VER.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "automake-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "automake-$VER"
tar -xf "automake-$VER.tar.gz"
cd "automake-$VER"

./configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo "✅ automake-$VER installed into $PREFIX"
