#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="1.17.0"
URL="https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "xcb-proto-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading xcb-proto-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "xcb-proto-$VERSION"
tar -xf "xcb-proto-$VERSION.tar.gz"
cd "xcb-proto-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install

echo "✅ xcb-proto-$VERSION installed into $PREFIX"
