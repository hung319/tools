#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
LIBXDAMAGE_VERSION="1.1.5"
LIBXDAMAGE_URL="https://www.x.org/releases/individual/lib/libXdamage-$LIBXDAMAGE_VERSION.tar.gz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download source ---
if [ ! -f "libXdamage-$LIBXDAMAGE_VERSION.tar.gz" ]; then
    echo "⬇️  Downloading libXdamage-$LIBXDAMAGE_VERSION..."
    curl -LO "$LIBXDAMAGE_URL"
fi

# --- Extract ---
tar -xf "libXdamage-$LIBXDAMAGE_VERSION.tar.gz"
cd "libXdamage-$LIBXDAMAGE_VERSION"

# --- Build & Install ---
echo "⚙️  Configuring..."
./configure --prefix="$PREFIX"

echo "🔨 Building..."
make -j"$(nproc)"

echo "📦 Installing into $PREFIX..."
make install

# --- Update LD_LIBRARY_PATH ---
if ! grep -q 'export LD_LIBRARY_PATH' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo "✨ Added LD_LIBRARY_PATH to ~/.bashrc"
fi

echo "✅ Done! libXdamage.so.1 should now be in $PREFIX/lib"
