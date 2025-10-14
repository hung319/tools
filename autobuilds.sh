#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

export PATH="$PREFIX/bin:$PATH"

# ===== Helper function =====
download_and_extract() {
  local url="$1"
  local name="$2"
  local file=$(basename "$url")
  echo "📦 Downloading $name..."
  curl -L -o "$file" "$url"
  tar xf "$file"
  cd $(tar tf "$file" | head -1 | cut -d/ -f1)
}

# ===== M4 =====
if [ ! -x "$PREFIX/bin/m4" ]; then
  download_and_extract https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.gz m4
  ./configure --prefix="$PREFIX"
  make -j"$(nproc)"
  make install
  cd "$SRC_DIR"
else
  echo "✅ m4 already installed."
fi

# ===== Autoconf =====
if [ ! -x "$PREFIX/bin/autoconf" ]; then
  download_and_extract https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.gz autoconf
  ./configure --prefix="$PREFIX"
  make -j"$(nproc)"
  make install
  cd "$SRC_DIR"
else
  echo "✅ autoconf already installed."
fi

# ===== Automake =====
if [ ! -x "$PREFIX/bin/automake" ]; then
  download_and_extract https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.gz automake
  ./configure --prefix="$PREFIX"
  make -j"$(nproc)"
  make install
  cd "$SRC_DIR"
else
  echo "✅ automake already installed."
fi

# ===== Libtool =====
if [ ! -x "$PREFIX/bin/libtool" ]; then
  download_and_extract https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.gz libtool
  ./configure --prefix="$PREFIX"
  make -j"$(nproc)"
  make install
  cd "$SRC_DIR"
else
  echo "✅ libtool already installed."
fi

echo "🎉 DONE! Installed m4, autoconf, automake, libtool into $PREFIX"
