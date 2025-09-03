#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="1.5.0"
URL="https://xorg.freedesktop.org/archive/individual/lib/xtrans-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "xtrans-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading xtrans-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "xtrans-$VERSION"
tar -xf "xtrans-$VERSION.tar.gz"
cd "xtrans-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install

echo "✅ xtrans-$VERSION installed into $PREFIX"
