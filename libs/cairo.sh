#!/bin/bash

# Dừng script nếu gặp lỗi
set -e

# --- 1. Cấu hình thông số ---
export PREFIX="$HOME/.local"
BUILD_DIR="$HOME/cairo_build_temp"
SHELL_CONFIG="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_CONFIG="$HOME/.zshrc"

# Các phiên bản
GPERF_VER="3.1"
ZLIB_VER="1.3.1"
EXPAT_VER="2.6.2"
PIXMAN_VER="0.46.4"
FREETYPE_VER="2.13.2"
FONTCONFIG_VER="2.15.0"
CAIRO_VER="1.18.4"

echo "🚀 Đang cài đặt bộ công cụ bổ sung và Cairo..."

# Tạo thư mục
mkdir -p "$BUILD_DIR"
mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include" "$PREFIX/lib/pkgconfig"

# Hàm dọn dẹp
cleanup() {
    if [ $? -eq 0 ]; then
        echo "✅ Cài đặt thành công!"
        rm -rf "$BUILD_DIR"
    else
        echo "❌ Thất bại. Kiểm tra lỗi tại $BUILD_DIR"
    fi
}
trap cleanup EXIT

# Thiết lập PATH để các bước sau tìm thấy gperf vừa cài
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$PREFIX/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

cd "$BUILD_DIR"

# --- 2. Cài đặt Gperf (MỚI - Sửa lỗi bạn gặp) ---
echo "📦 1/7: Cài đặt Gperf..."
curl -L "https://ftp.gnu.org/pub/gnu/gperf/gperf-$GPERF_VER.tar.gz" -o gperf.tar.gz
tar -xf gperf.tar.gz && cd "gperf-$GPERF_VER"
./configure --prefix="$PREFIX"
make -j$(nproc) install
cd ..

# --- 3. Cài đặt Zlib ---
echo "📦 2/7: Cài đặt Zlib..."
curl -L "https://www.zlib.net/zlib-$ZLIB_VER.tar.gz" -o zlib.tar.gz
tar -xf zlib.tar.gz && cd "zlib-$ZLIB_VER"
CFLAGS="-fPIC" ./configure --prefix="$PREFIX"
make -j$(nproc) install
cd ..

# --- 4. Cài đặt Expat ---
echo "📦 3/7: Cài đặt Expat..."
curl -L "https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VER//./_}/expat-$EXPAT_VER.tar.xz" -o expat.tar.xz
tar -xf expat.tar.xz && cd "expat-$EXPAT_VER"
./configure --prefix="$PREFIX" --disable-static
make -j$(nproc) install
cd ..

# --- 5. Cài đặt Pixman ---
echo "📦 4/7: Cài đặt Pixman..."
curl -L "https://www.cairographics.org/releases/pixman-$PIXMAN_VER.tar.xz" -o pixman.tar.xz
tar -xf pixman.tar.xz && cd "pixman-$PIXMAN_VER"
meson setup builddir --prefix="$PREFIX" --buildtype=release -Dgtk=disabled -Dtests=disabled
ninja -C builddir install
cd ..

# --- 6. Cài đặt FreeType ---
echo "📦 5/7: Cài đặt FreeType..."
curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VER.tar.xz" -o freetype.tar.xz
tar -xf freetype.tar.xz && cd "freetype-$FREETYPE_VER"
./configure --prefix="$PREFIX" --without-harfbuzz
make -j$(nproc) install
cd ..

# --- 7. Cài đặt Fontconfig (Bây giờ đã có gperf) ---
echo "📦 6/7: Cài đặt Fontconfig..."
curl -L "https://www.freedesktop.org/software/fontconfig/release/fontconfig-$FONTCONFIG_VER.tar.xz" -o fontconfig.tar.xz
tar -xf fontconfig.tar.xz && cd "fontconfig-$FONTCONFIG_VER"
./configure --prefix="$PREFIX" \
            --disable-docs \
            --with-default-fonts=/usr/share/fonts \
            --with-expat-includes="$PREFIX/include" \
            --with-expat-lib="$PREFIX/lib"
make -j$(nproc) install
cd ..

# --- 8. Cài đặt Cairo ---
echo "📦 7/7: Cài đặt Cairo..."
curl -L "https://www.cairographics.org/releases/cairo-$CAIRO_VER.tar.xz" -o cairo.tar.xz
tar -xf cairo.tar.xz && cd "cairo-$CAIRO_VER"
rm -rf builddir
meson setup builddir --prefix="$PREFIX" --buildtype=release \
    -Dtests=disabled -Dglib=disabled -Dfontconfig=enabled -Dfreetype=enabled \
    -Dpng=enabled -Dzlib=enabled -Dxcb=disabled -Dxlib=disabled -Dgtk_doc=false
ninja -C builddir install
cd ..

# --- 9. Cập nhật ENV ---
echo "🔧 Cấu hình biến môi trường..."
ENV_LINES=(
    "export PATH=\"\$HOME/.local/bin:\$PATH\""
    "export PKG_CONFIG_PATH=\"\$HOME/.local/lib/pkgconfig:\$HOME/.local/lib/x86_64-linux-gnu/pkgconfig:\$PKG_CONFIG_PATH\""
    "export LD_LIBRARY_PATH=\"\$HOME/.local/lib:\$HOME/.local/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH\""
)
for line in "${ENV_LINES[@]}"; do
    CLEAN_LINE=$(echo "$line" | sed 's/\\//g')
    if ! grep -Fq "$CLEAN_LINE" "$SHELL_CONFIG"; then
        echo "$line" >> "$SHELL_CONFIG"
    fi
done

echo "🎉 Xong! Chạy 'source $SHELL_CONFIG' và cài lại canvas là được."
