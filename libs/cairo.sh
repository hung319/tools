#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
CAIRO_VERSION="1.18.0"
CAIRO_URL="https://www.cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "cairo-$CAIRO_VERSION.tar.xz" ]; then
    echo "⬇️  Downloading Cairo $CAIRO_VERSION..."
    curl -LO "$CAIRO_URL"
fi

# --- Extract ---
rm -rf "cairo-$CAIRO_VERSION"
tar -xf "cairo-$CAIRO_VERSION.tar.xz"
cd "cairo-$CAIRO_VERSION"

# --- Build & Install ---
echo "⚙️  Configuring Cairo..."
meson setup _build --prefix="$PREFIX" --libdir=lib \
    -Dzlib=enabled \
    -Dpng=enabled \
    -Dfreetype=enabled \
    -Dfontconfig=enabled \
    -Dxlib=enabled

echo "🔨 Building Cairo..."
ninja -C _build

echo "📦 Installing Cairo into $PREFIX..."
ninja -C _build install

# --- Update env vars ---
if ! grep -q 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig' ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
fi
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
fi

echo "✅ Cairo $CAIRO_VERSION installed successfully in $PREFIX"
echo "   → Check with: pkg-config --modversion cairo"
