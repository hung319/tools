#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
GLIB_VERSION="2.80.4"
GLIB_URL="https://download.gnome.org/sources/glib/${GLIB_VERSION%.*}/glib-$GLIB_VERSION.tar.xz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "glib-$GLIB_VERSION.tar.xz" ]; then
    echo "⬇️  Downloading GLib $GLIB_VERSION..."
    curl -LO "$GLIB_URL"
fi

# --- Extract ---
tar -xf "glib-$GLIB_VERSION.tar.xz"
cd "glib-$GLIB_VERSION"

# --- Build & Install ---
echo "⚙️  Configuring with meson..."
meson setup _build --prefix="$PREFIX"

echo "🔨 Building..."
ninja -C _build

echo "📦 Installing into $PREFIX..."
ninja -C _build install

# --- Update LD_LIBRARY_PATH & PKG_CONFIG_PATH ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
    echo "✨ Added GLib paths to ~/.bashrc"
fi

echo "✅ Done! gobject-2.0 (libgobject-2.0.so) is now in $PREFIX/lib"
