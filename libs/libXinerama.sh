#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBXINERAMA_VERSION="1.1.5"
LIBXINERAMA_URL="https://www.x.org/releases/individual/lib/libXinerama-$LIBXINERAMA_VERSION.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libXinerama-$LIBXINERAMA_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXinerama-$LIBXINERAMA_VERSION..."
    curl -LO "$LIBXINERAMA_URL"
fi

# --- Extract ---
tar -xf "libXinerama-$LIBXINERAMA_VERSION.tar.gz"
cd "libXinerama-$LIBXINERAMA_VERSION"

# --- Build & Install ---
echo "⚙️  Configuring..."
./configure --prefix="$PREFIX"

echo "🔨 Building..."
make -j"$(nproc)"

echo "📦 Installing into $PREFIX..."
make install

# --- Update LD_LIBRARY_PATH ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo "✨ Added LD_LIBRARY_PATH to ~/.bashrc"
fi

echo "✅ Done! libXinerama.so.1 should now be in $PREFIX/lib"
