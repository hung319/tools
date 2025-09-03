#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
XORGPROTO_VERSION="2024.1"
XORGPROTO_URL="https://xorg.freedesktop.org/archive/individual/proto/xorgproto-$XORGPROTO_VERSION.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "xorgproto-$XORGPROTO_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading xorgproto $XORGPROTO_VERSION..."
    curl -LO "$XORGPROTO_URL"
fi

# --- Extract ---
rm -rf "xorgproto-$XORGPROTO_VERSION"
tar -xf "xorgproto-$XORGPROTO_VERSION.tar.gz"
cd "xorgproto-$XORGPROTO_VERSION"

# --- Out-of-tree build ---
mkdir -p build
cd build

echo "⚙️  Configuring xorgproto..."
../configure --prefix="$PREFIX"

echo "🔨 Building xorgproto..."
make -j"$(nproc)"

echo "📦 Installing xorgproto into $PREFIX..."
make install

echo "✅ xorgproto $XORGPROTO_VERSION installed successfully in $PREFIX"
