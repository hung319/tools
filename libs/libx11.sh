#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VERSION="1.8.9"
URL="https://www.x.org/releases/individual/lib/libX11-$VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libX11-$VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libX11-$VERSION..."
    curl -LO "$URL"
fi

rm -rf "libX11-$VERSION"
tar -xf "libX11-$VERSION.tar.gz"
cd "libX11-$VERSION"

mkdir -p build && cd build
../configure --prefix="$PREFIX" --libdir="$PREFIX/lib" \
    PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
make -j"$(nproc)"
make install

echo "✅ libX11-$VERSION installed into $PREFIX"
