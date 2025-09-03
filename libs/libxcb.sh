#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="1.16"
URL="https://xorg.freedesktop.org/archive/individual/lib/libxcb-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libxcb-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libxcb-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "libxcb-$VERSION"
tar -xf "libxcb-$VERSION.tar.gz"
cd "libxcb-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib" \
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
make -j"$(nproc)"
make install

echo "✅ libxcb-$VERSION installed into $PREFIX"
