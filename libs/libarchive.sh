#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
ARCHIVE_SRC="$SRC_DIR/libarchive"
ARCHIVE_REPO="https://github.com/libarchive/libarchive.git"

mkdir -p "$SRC_DIR" "$PREFIX"

# Clone libarchive
if [ ! -d "$ARCHIVE_SRC" ]; then
  echo "📥 Cloning libarchive..."
  git clone "$ARCHIVE_REPO" "$ARCHIVE_SRC"
else
  echo "✅ libarchive source already exists at $ARCHIVE_SRC"
fi

cd "$ARCHIVE_SRC"

# Build & install
./build/autogen.sh || true
./configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo "🎉 libarchive installed to $PREFIX/lib"
