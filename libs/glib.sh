#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
GLIB_VERSION="2.85.4"
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

# --- Clean old build ---
rm -rf _build

# --- Config ---
echo "⚙️  Configuring with meson..."
meson setup _build --prefix="$PREFIX" --wipe \
                   -Dintrospection=enabled \
                   -Dbuildtype=release

# --- Build (ép dùng lib trong _build/glib để tránh xung đột .local cũ) ---
echo "🔨 Building..."
LD_LIBRARY_PATH="$PWD/_build/glib:$LD_LIBRARY_PATH" \
    ninja -C _build

# --- Install ---
echo "📦 Installing into $PREFIX..."
ninja -C _build install

# --- Update ~/.bashrc ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
    echo "✨ Added GLib paths to ~/.bashrc"
fi

echo "✅ GLib $GLIB_VERSION updated and installed into $PREFIX/lib"
