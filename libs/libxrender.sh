#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="0.9.11"
URL="https://xorg.freedesktop.org/archive/individual/lib/libXrender-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libXrender-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXrender-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "libXrender-$VERSION"
tar -xf "libXrender-$VERSION.tar.gz"
cd "libXrender-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install

echo "✅ libXrender-$VERSION installed into $PREFIX"
