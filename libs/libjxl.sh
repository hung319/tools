#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="0.11.1"
REPO="https://github.com/libjxl/libjxl.git"

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Clone with submodules ---
if [ ! -d "libjxl" ]; then
  echo "⬇️  Cloning libjxl $VER..."
  git clone --recursive -b v$VER "$REPO" libjxl
else
  echo "🔄 Updating existing libjxl repo..."
  cd libjxl
  git fetch --all
  git checkout v$VER
  git submodule update --init --recursive
  cd ..
fi

cd libjxl

# --- Fetch & build third_party deps ---
echo "⚙️  Running deps.sh..."
chmod +x deps.sh
./deps.sh

# --- Build ---
rm -rf build
mkdir build
cd build

cmake .. \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_TESTING=OFF

make -j"$(nproc)"
make install

echo "✅ Done! libjxl $VER installed into $PREFIX"
echo "   → check with: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --modversion libjxl"
