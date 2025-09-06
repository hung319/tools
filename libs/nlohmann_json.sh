#!/usr/bin/env bash
set -e

# --- Config ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
REPO="https://github.com/nlohmann/json.git"
VERSION="v3.11.3"   # đổi version nếu muốn

# --- Prepare ---
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# --- Fetch source ---
if [ ! -d "json" ]; then
    git clone "$REPO"
fi

cd json
git fetch --all --tags
git checkout "$VERSION"

# --- Build & Install ---
cmake -B build -S . \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON

cmake --build build -j"$(nproc)"
cmake --install build
