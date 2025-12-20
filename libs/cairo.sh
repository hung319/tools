#!/bin/bash
set -e

# --- 1. Cấu hình thông số ---
export PREFIX="$HOME/.local"
BUILD_DIR="$HOME/cairo_build_temp"
SHELL_CONFIG="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_CONFIG="$HOME/.zshrc"

# Các phiên bản
GPERF_VER="3.1"
ZLIB_VER="1.3.1"
LIBPNG_VER="1.6.44"
EXPAT_VER="2.6.2"
PIXMAN_VER="0.46.4"
FREETYPE_VER="2.13.2"
FONTCONFIG_VER="2.15.0"
CAIRO_VER="1.18.4"

echo "🚀 Bắt đầu cài đặt Cairo v5 (Sửa lỗi đa kiến trúc)..."

mkdir -p "$BUILD_DIR"
mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include" "$PREFIX/lib/pkgconfig"

# Hàm dọn dẹp khi kết thúc
cleanup() {
    [ $? -eq 0 ] && echo "✅ Hoàn tất thành công!" && rm -rf "$BUILD_DIR" || echo "❌ Cài đặt thất bại."
}
trap cleanup EXIT

# 2. THIẾT LẬP MÔI TRƯỜNG CỰC ĐOAN (Đảm bảo các thư viện thấy nhau)
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$PREFIX/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

# Ép trình biên dịch ưu tiên tìm ở .local trước hệ thống
export CPPFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib -L$PREFIX/lib/x86_64-linux-gnu -Wl,-rpath,$PREFIX/lib"
export CFLAGS="-I$PREFIX/include -fPIC"

# Hàm quan trọng: Gom tất cả .so về thư mục gốc .local/lib
fix_lib_paths() {
    if [ -d "$PREFIX/lib/x86_64-linux-gnu" ]; then
        echo "🔧 Đang di chuyển thư viện từ x86_64-linux-gnu về lib..."
        cp -rs "$PREFIX/lib/x86_64-linux-gnu/"* "$PREFIX/lib/" 2>/dev/null || true
    fi
}

cd "$BUILD_DIR"

echo "📦 1/8: Gperf..."
curl -L "https://ftp.gnu.org/pub/gnu/gperf/gperf-$GPERF_VER.tar.gz" -o gperf.tar.gz
tar -xf gperf.tar.gz && cd "gperf-$GPERF_VER"
./configure --prefix="$PREFIX" && make -j$(nproc) install
cd ..

echo "📦 2/8: Zlib..."
curl -L "https://www.zlib.net/zlib-$ZLIB_VER.tar.gz" -o zlib.tar.gz
tar -xf zlib.tar.gz && cd "zlib-$ZLIB_VER"
./configure --prefix="$PREFIX" && make -j$(nproc) install
cd ..
fix_lib_paths

echo "📦 3/8: Libpng..."
curl -L "https://download.sourceforge.net/libpng/libpng-$LIBPNG_VER.tar.xz" -o libpng.tar.xz
tar -xf libpng.tar.xz && cd "libpng-$LIBPNG_VER"
./configure --prefix="$PREFIX" --disable-static && make -j$(nproc) install
cd ..
fix_lib_paths

echo "📦 4/8: Expat..."
curl -L "https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VER//./_}/expat-$EXPAT_VER.tar.xz" -o expat.tar.xz
tar -xf expat.tar.xz && cd "expat-$EXPAT_VER"
./configure --prefix="$PREFIX" --disable-static && make -j$(nproc) install
cd ..
fix_lib_paths

echo "📦 5/8: Pixman..."
curl -L "https://www.cairographics.org/releases/pixman-$PIXMAN_VER.tar.xz" -o pixman.tar.xz
tar -xf pixman.tar.xz && cd "pixman-$PIXMAN_VER"
meson setup builddir --prefix="$PREFIX" --buildtype=release -Dgtk=disabled -Dtests=disabled --libdir=lib
ninja -C builddir install
cd ..
fix_lib_paths

echo "📦 6/8: FreeType..."
curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VER.tar.xz" -o freetype.tar.xz
tar -xf freetype.tar.xz && cd "freetype-$FREETYPE_VER"
./configure --prefix="$PREFIX" --without-harfbuzz --libdir="$PREFIX/lib"
make -j$(nproc) install
cd ..
fix_lib_paths

echo "📦 7/8: Fontconfig..."
curl -L "https://www.freedesktop.org/software/fontconfig/release/fontconfig-$FONTCONFIG_VER.tar.xz" -o fontconfig.tar.xz
tar -xf fontconfig.tar.xz && cd "fontconfig-$FONTCONFIG_VER"
# Ép Fontconfig dùng đúng đường dẫn FreeType vừa build
./configure --prefix="$PREFIX" --disable-docs --with-default-fonts=/usr/share/fonts \
            --libdir="$PREFIX/lib" \
            FREETYPE_CFLAGS="-I$PREFIX/include/freetype2" \
            FREETYPE_LIBS="-L$PREFIX/lib -lfreetype"
make -j$(nproc) install
cd ..
fix_lib_paths

echo "📦 8/8: Cairo..."
curl -L "https://www.cairographics.org/releases/cairo-$CAIRO_VER.tar.xz" -o cairo.tar.xz
tar -xf cairo.tar.xz && cd "cairo-$CAIRO_VER"
rm -rf builddir
meson setup builddir --prefix="$PREFIX" --buildtype=release --libdir=lib \
    -Dtests=disabled -Dglib=disabled -Dfontconfig=enabled -Dfreetype=enabled \
    -Dpng=enabled -Dzlib=enabled -Dxcb=disabled -Dxlib=disabled -Dgtk_doc=false
ninja -C builddir install
cd ..

# Cập nhật Shell config
ENV_LINES=(
    "export PATH=\"\$HOME/.local/bin:\$PATH\""
    "export PKG_CONFIG_PATH=\"\$HOME/.local/lib/pkgconfig:\$PKG_CONFIG_PATH\""
    "export LD_LIBRARY_PATH=\"\$HOME/.local/lib:\$LD_LIBRARY_PATH\""
)
for line in "${ENV_LINES[@]}"; do
    CLEAN_LINE=$(echo "$line" | sed 's/\\//g')
    grep -Fq "$CLEAN_LINE" "$SHELL_CONFIG" || echo "$line" >> "$SHELL_CONFIG"
done

echo "🎉 CHÚC MỪNG! Toàn bộ thư viện đã được build xong."
echo "👉 Hãy chạy lệnh cuối cùng: source $SHELL_CONFIG"
echo "👉 Sau đó vào project và chạy: rm -rf node_modules/canvas && npm install canvas --build-from-source"
