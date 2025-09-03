#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
PANGO_VERSION="1.90.0"
PANGO_URL="https://download.gnome.org/sources/pango/1.90/pango-$PANGO_VERSION.tar.xz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "pango-$PANGO_VERSION.tar.xz" ]; then
    echo "⬇️  Downloading Pango $PANGO_VERSION..."
    curl -LO "$PANGO_URL"
fi

# --- Extract ---
rm -rf "pango-$PANGO_VERSION"
tar -xf "pango-$PANGO_VERSION.tar.xz"
cd "pango-$PANGO_VERSION"

# --- Env (ưu tiên .local) ---
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export PATH="$PREFIX/bin:$PATH"

# --- Build & Install ---
echo "⚙️  Configuring with meson (using .local first)..."
meson setup _build --prefix="$PREFIX" --libdir=lib \
    --buildtype=release \
    --wrap-mode=nodownload

echo "🔨 Building..."
ninja -C _build -j"$(nproc)"

echo "📦 Installing into $PREFIX..."
ninja -C _build install

# --- Persist env ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
fi
if ! grep -q 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig' ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
fi
if ! grep -q 'export PATH=$HOME/.local/bin:$PATH' ~/.bashrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

echo "✅ Done! Pango $PANGO_VERSION installed into $PREFIX/lib"
echo "   → Check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion pango"
