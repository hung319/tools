#!/bin/bash
set -e
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

echo "⚙️  Building dependencies for GObject Introspection..."

# --- Build GLib (nếu chưa có) ---
if [ ! -f "$PREFIX/lib/libglib-2.0.so" ]; then
    GLIB_VER="2.80.4"
    curl -LO "https://download.gnome.org/sources/glib/${GLIB_VER%.*}/glib-$GLIB_VER.tar.xz"
    tar -xf "glib-$GLIB_VER.tar.xz"
    cd "glib-$GLIB_VER"
    meson setup _build --prefix="$PREFIX"
    ninja -C _build -j"$(nproc)"
    ninja -C _build install
    cd "$SRC_DIR"
fi

# --- Build libffi ---
if [ ! -f "$PREFIX/lib/libffi.so" ]; then
    LIBFFI_VER="3.4.2"
    curl -LO "https://github.com/libffi/libffi/releases/download/v$LIBFFI_VER/libffi-$LIBFFI_VER.tar.gz"
    tar -xf "libffi-$LIBFFI_VER.tar.gz"
    cd "libffi-$LIBFFI_VER"
    ./configure --prefix="$PREFIX" --disable-static
    make -j"$(nproc)"
    make install
    cd "$SRC_DIR"
fi

# --- Build Pkg-config ---
if [ ! -f "$PREFIX/bin/pkg-config" ]; then
    PKG_VER="0.29.2"
    curl -LO "https://pkg-config.freedesktop.org/releases/pkg-config-$PKG_VER.tar.gz"
    tar -xf "pkg-config-$PKG_VER.tar.gz"
    cd "pkg-config-$PKG_VER"
    ./configure --prefix="$PREFIX" --with-internal-glib
    make -j"$(nproc)"
    make install
    cd "$SRC_DIR"
fi

# --- Build GObject Introspection ---
if [ ! -f "$PREFIX/bin/g-ir-scanner" ]; then
    GI_VER="1.78.0"
    curl -LO "https://download.gnome.org/sources/gobject-introspection/${GI_VER%.*}/gobject-introspection-$GI_VER.tar.xz"
    tar -xf "gobject-introspection-$GI_VER.tar.xz"
    cd "gobject-introspection-$GI_VER"
    ./configure --prefix="$PREFIX" PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PKG_CONFIG_PATH" \
                --disable-gtk-doc
    make -j"$(nproc)"
    make install
    cd "$SRC_DIR"
fi

echo "✅ Done! GObject Introspection installed into $PREFIX"
echo "   → Check with: $PREFIX/bin/g-ir-scanner --version"
