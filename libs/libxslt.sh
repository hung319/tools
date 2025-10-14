#!/usr/bin/env bash
set -e

PREFIX="$HOME/.local"
SRC="$HOME/src"
mkdir -p "$SRC" "$PREFIX/lib/pkgconfig"

export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"

# =========================
# 🧱 Build libxml2
# =========================
cd "$SRC"
if [ ! -d libxml2 ]; then
  git clone --depth=1 https://gitlab.gnome.org/GNOME/libxml2.git
fi
cd libxml2
./autogen.sh --prefix="$PREFIX" --with-python=no
make -j$(nproc)
make install

# =========================
# 🧱 Build libxslt (disable Python)
# =========================
cd "$SRC"
if [ ! -d libxslt ]; then
  git clone --depth=1 https://gitlab.gnome.org/GNOME/libxslt.git
fi
cd libxslt

# Nếu không có autogen.sh thì tự sinh ra
if [ ! -f ./autogen.sh ]; then
  echo "⚙️ autogen.sh not found — generating with autoreconf..."
  autoreconf -fi
  ./configure --prefix="$PREFIX" \
    --with-libxml-prefix="$PREFIX" \
    --without-python
else
  ./autogen.sh --prefix="$PREFIX" \
    --with-libxml-prefix="$PREFIX" \
    --without-python
fi

make -j$(nproc)
make install

echo "✅ Done! Installed libxml2 and libxslt (no Python) into $PREFIX"
