#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="1.3.6"
URL="https://xorg.freedesktop.org/archive/individual/lib/libXext-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libXext-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXext-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "libXext-$VERSION"
tar -xf "libXext-$VERSION.tar.gz"
cd "libXext-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install

echo "✅ libXext-$VERSION installed into $PREFIX"
