#!/bin/bash
set -e

PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# =======================
# Build libxml2 (no python)
# =======================
if [ ! -d libxml2 ]; then
  echo "📦 Downloading libxml2..."
  curl -L -o libxml2.tar.gz https://gitlab.gnome.org/GNOME/libxml2/-/archive/v2.13.0/libxml2-v2.13.0.tar.gz
  tar xf libxml2.tar.gz
  mv libxml2-* libxml2
fi

cd libxml2
echo "⚙️ Building libxml2..."
make distclean >/dev/null 2>&1 || true
./autogen.sh --prefix="$PREFIX" --without-python --disable-python --enable-static --enable-shared
make -j"$(nproc)"
make install
cd ..

# =======================
# Build libxslt
# =======================
if [ ! -d libxslt ]; then
  echo "📦 Downloading libxslt..."
  curl -L -o libxslt.tar.gz https://gitlab.gnome.org/GNOME/libxslt/-/archive/v1.1.41/libxslt-v1.1.41.tar.gz
  tar xf libxslt.tar.gz
  mv libxslt-* libxslt
fi

cd libxslt
echo "⚙️ Building libxslt..."
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" \
CFLAGS="-I$PREFIX/include" \
LDFLAGS="-L$PREFIX/lib" \
./autogen.sh --prefix="$PREFIX" --with-libxml-prefix="$PREFIX" --enable-static --enable-shared
make -j"$(nproc)"
make install
cd ..

echo "✅ Installed libxml2 & libxslt into $PREFIX"
