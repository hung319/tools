#!/bin/bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
UTIL_LINUX_VERSION="2.40.2"
UTIL_LINUX_URL="https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v${UTIL_LINUX_VERSION%.*}/util-linux-$UTIL_LINUX_VERSION.tar.xz"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Download ---
if [ ! -f "util-linux-$UTIL_LINUX_VERSION.tar.xz" ]; then
    echo "⬇️  Downloading util-linux $UTIL_LINUX_VERSION..."
    curl -LO "$UTIL_LINUX_URL"
fi

# --- Extract ---
tar -xf "util-linux-$UTIL_LINUX_VERSION.tar.xz"
cd "util-linux-$UTIL_LINUX_VERSION"

# --- Build ---
mkdir -p build
cd build

echo "⚙️  Configuring..."
../configure --prefix="$PREFIX" --disable-all-programs --enable-libuuid

echo "🔨 Building..."
make -j"$(nproc)"

echo "📦 Installing into $PREFIX..."
make install

# --- Update ~/.bashrc ---
if ! grep -q 'export LD_LIBRARY_PATH=$HOME/.local/lib' ~/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo 'export PKG_CONFIG_PATH=$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH' >> ~/.bashrc
    echo "✨ Added libuuid paths to ~/.bashrc"
fi

echo "✅ libuuid installed into $PREFIX/lib"
