#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="0.22.5"
URL="https://ftp.gnu.org/gnu/gettext/gettext-$VER.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Download
if [ ! -f "gettext-$VER.tar.gz" ]; then
  curl -LO "$URL"
fi

# Extract
rm -rf "gettext-$VER"
tar -xf "gettext-$VER.tar.gz"
cd "gettext-$VER"

# Build
./configure --prefix="$PREFIX" --disable-dependency-tracking --disable-silent-rules
make -j"$(nproc)"
make install

echo "✅ Done! gettext $VER installed."
echo "   → msgfmt path: $PREFIX/bin/msgfmt"
