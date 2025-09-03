#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
FONTCONFIG_VERSION="2.15.0"
FONTCONFIG_URL="https://www.freedesktop.org/software/fontconfig/release/fontconfig-$FONTCONFIG_VERSION.tar.xz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "fontconfig-$FONTCONFIG_VERSION.tar.xz" ]; then
    echo "⬇️ Downloading fontconfig $FONTCONFIG_VERSION..."
    curl -LO "$FONTCONFIG_URL"
fi

tar -xf "fontconfig-$FONTCONFIG_VERSION.tar.xz"
cd "fontconfig-$FONTCONFIG_VERSION"

mkdir -p build
cd build

../configure --prefix="$PREFIX" --disable-docs
make -j"$(nproc)"
make install
