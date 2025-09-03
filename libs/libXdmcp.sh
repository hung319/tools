#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
XDMCP_VERSION="1.1.4"
XDMCP_URL="https://www.x.org/releases/individual/lib/libXdmcp-$XDMCP_VERSION.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "libXdmcp-$XDMCP_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXdmcp $XDMCP_VERSION..."
    curl -LO "$XDMCP_URL"
fi

rm -rf "libXdmcp-$XDMCP_VERSION"
tar -xf "libXdmcp-$XDMCP_VERSION.tar.gz"
cd "libXdmcp-$XDMCP_VERSION"

./configure --prefix="$PREFIX" --libdir="$PREFIX/lib"
make -j"$(nproc)"
make install
