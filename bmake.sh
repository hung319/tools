#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
URL="https://ftp.netbsd.org/pub/NetBSD/misc/sjg/bmake-20250804.tar.gz"
TARBALL="$SRC_DIR/bmake-20250804.tar.gz"

mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

echo "[*] Downloading bmake..."
curl -L "$URL" -o "$TARBALL"

echo "[*] Extracting..."
rm -rf bmake-20250804
tar xf "$TARBALL"
cd bmake

echo "[*] Bootstrapping..."
./boot-strap --prefix="$PREFIX" --install

echo
echo "✅ bmake installed to $PREFIX/bin/bmake"
echo "👉 Add to PATH if needed:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
