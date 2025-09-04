#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
REPO="https://gitlab.gnome.org/GNOME/librsvg.git"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Clone or update repo ---
if [ ! -d librsvg ]; then
    git clone "$REPO"
fi
cd librsvg
git fetch origin
git checkout main
git pull origin main

# --- Ensure cargo in PATH ---
export PATH="$HOME/.cargo/bin:$PATH"

# --- Clean previous build ---
rm -rf _build

# --- Configure Meson ---
meson setup _build \
    --prefix="$PREFIX" \
    -Dintrospection=disabled \
    -Dtests=false \
    -Drust_backend=system

# --- Build & Install ---
meson compile -C _build -j"$(nproc)"
meson install -C _build

# --- Persist PKG_CONFIG_PATH and LD_LIBRARY_PATH ---
if ! grep -q 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig' ~/.bashrc; then
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
fi
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
fi
if ! grep -q 'export PATH=$HOME/.local/bin:$PATH' ~/.bashrc; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

echo "✅ Done! librsvg (main branch) installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion librsvg-2.0"
