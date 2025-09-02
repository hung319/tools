#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBXCOMPOSITE_VERSION="0.4.6"
LIBXCOMPOSITE_URL="https://www.x.org/releases/individual/lib/libXcomposite-$LIBXCOMPOSITE_VERSION.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "libXcomposite-$LIBXCOMPOSITE_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXcomposite-$LIBXCOMPOSITE_VERSION..."
    curl -LO "$LIBXCOMPOSITE_URL"
fi

# --- Extract ---
tar -xf "libXcomposite-$LIBXCOMPOSITE_VERSION.tar.gz"
cd "libXcomposite-$LIBXCOMPOSITE_VERSION"

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

echo "✅ Done! libXcomposite.so.1 should now be in $PREFIX/lib"
