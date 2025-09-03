#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

CMAKE_VER="3.29.6"
URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}.tar.gz"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "cmake-${CMAKE_VER}.tar.gz" ]; then
  curl -LO "$URL"
fi

rm -rf "cmake-${CMAKE_VER}"
tar -xf "cmake-${CMAKE_VER}.tar.gz"
cd "cmake-${CMAKE_VER}"

./bootstrap --prefix="$PREFIX"
make -j"$(nproc)"
make install

echo "✅ Done! Installed CMake ${CMAKE_VER} into $PREFIX"
echo "   → Check with: $PREFIX/bin/cmake --version"
