#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
HARFBUZZ_VERSION="8.5.0"
HARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/$HARFBUZZ_VERSION/harfbuzz-$HARFBUZZ_VERSION.tar.xz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "harfbuzz-$HARFBUZZ_VERSION.tar.xz" ]; then
    echo "⬇️  Downloading Harfbuzz $HARFBUZZ_VERSION..."
    curl -LO "$HARFBUZZ_URL"
fi

# --- Extract ---
rm -rf "harfbuzz-$HARFBUZZ_VERSION"
tar -xf "harfbuzz-$HARFBUZZ_VERSION.tar.xz"
cd "harfbuzz-$HARFBUZZ_VERSION"

# --- Build & Install ---
echo "⚙️  Configuring Harfbuzz (with gobject)..."
meson setup _build --prefix="$PREFIX" --libdir=lib \
    -Dglib=enabled \
    -Dgobject=enabled

echo "🔨 Building Harfbuzz..."
ninja -C _build

echo "📦 Installing Harfbuzz into $PREFIX..."
ninja -C _build install

# --- Update env vars ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
fi
if ! grep -q 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig' ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
fi

echo "✅ Harfbuzz $HARFBUZZ_VERSION installed successfully in $PREFIX"
echo "   → Check with: pkg-config --modversion harfbuzz-gobject"
