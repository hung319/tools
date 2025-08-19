#!/usr/bin/env bash
set -euo pipefail

# ========================
# Config
# ========================
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
XORGPROTO_VERSION="2024.1"   # headers
LIBICE_VERSION="1.1.1"
LIBSM_VERSION="1.2.4"
LIBXT_VERSION="1.3.0"
LIBXMU_VERSION="1.1.4"
XAUTH_VERSION="1.1.2"

mkdir -p "$PREFIX" "$SRC_DIR"

# ========================
# Helper: build package
# ========================
build_pkg() {
    local name=$1
    local version=$2
    local url=$3

    cd "$SRC_DIR"
    if [ ! -f "${name}-${version}.tar.xz" ]; then
        echo "⬇️ Downloading $name-$version..."
        curl -LO "$url"
    fi

    rm -rf "${name}-${version}"
    tar -xf "${name}-${version}.tar.xz"
    cd "${name}-${version}"

    echo "⚙️ Configuring $name..."
    ./configure --prefix="$PREFIX" \
        PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig" \
        CPPFLAGS="-I$PREFIX/include" \
        LDFLAGS="-L$PREFIX/lib"

    echo "🔨 Building $name..."
    make -j"$(nproc)"

    echo "📦 Installing $name..."
    make install

    echo "✅ Done! $name-$version installed"
}

# ========================
# Build deps if missing
# ========================

# xorgproto
if [ ! -f "$PREFIX/include/X11/X.h" ]; then
    echo "⚙️ Installing xorgproto-$XORGPROTO_VERSION..."
    cd "$SRC_DIR"
    if [ ! -f "xorgproto-$XORGPROTO_VERSION.tar.xz" ]; then
        curl -LO "https://www.x.org/releases/individual/proto/xorgproto-$XORGPROTO_VERSION.tar.xz"
    fi
    rm -rf "xorgproto-$XORGPROTO_VERSION"
    tar -xf "xorgproto-$XORGPROTO_VERSION.tar.xz"
    cd "xorgproto-$XORGPROTO_VERSION"
    ./configure --prefix="$PREFIX"
    make -j"$(nproc)"
    make install
else
    echo "✅ xorgproto already installed, skipping."
fi

# libICE
if [ ! -f "$PREFIX/lib/pkgconfig/ice.pc" ]; then
    build_pkg "libICE" "$LIBICE_VERSION" "https://www.x.org/releases/individual/lib/libICE-$LIBICE_VERSION.tar.xz"
else
    echo "✅ libICE already installed, skipping."
fi

# libSM
if [ ! -f "$PREFIX/lib/pkgconfig/sm.pc" ]; then
    build_pkg "libSM" "$LIBSM_VERSION" "https://www.x.org/releases/individual/lib/libSM-$LIBSM_VERSION.tar.xz"
else
    echo "✅ libSM already installed, skipping."
fi

# libXt
if [ ! -f "$PREFIX/lib/pkgconfig/xt.pc" ]; then
    build_pkg "libXt" "$LIBXT_VERSION" "https://www.x.org/releases/individual/lib/libXt-$LIBXT_VERSION.tar.xz"
else
    echo "✅ libXt already installed, skipping."
fi

# libXmu (có libXmuu)
if [ ! -f "$PREFIX/lib/pkgconfig/xmu.pc" ]; then
    build_pkg "libXmu" "$LIBXMU_VERSION" "https://www.x.org/releases/individual/lib/libXmu-$LIBXMU_VERSION.tar.xz"
else
    echo "✅ libXmu already installed, skipping."
fi

# ========================
# Build xauth
# ========================
if [ ! -f "$PREFIX/bin/xauth" ]; then
    build_pkg "xauth" "$XAUTH_VERSION" "https://www.x.org/releases/individual/app/xauth-$XAUTH_VERSION.tar.xz"
else
    echo "✅ xauth already installed, skipping."
fi

# ========================
# Add env to ~/.bashrc if missing
# ========================
BASHRC="$HOME/.bashrc"

add_if_missing() {
    local line=$1
    grep -qxF "$line" "$BASHRC" || echo "$line" >> "$BASHRC"
}

echo ""
echo "⚙️ Updating $BASHRC with environment variables..."

add_if_missing "export PATH=\"$PREFIX/bin:\$PATH\""
add_if_missing "export LD_LIBRARY_PATH=\"$PREFIX/lib:\$LD_LIBRARY_PATH\""
add_if_missing "export PKG_CONFIG_PATH=\"$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig:\$PKG_CONFIG_PATH\""

echo "✅ Environment variables added to $BASHRC"
echo "👉 Run: source ~/.bashrc  (or restart shell) to apply."
