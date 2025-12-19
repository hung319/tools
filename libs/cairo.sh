#!/bin/bash

# Dừng script nếu gặp lỗi
set -e

# --- 1. Cấu hình thông số ---
export PREFIX="$HOME/.local"
BUILD_DIR="$HOME/cairo_build_temp"
SHELL_CONFIG="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_CONFIG="$HOME/.zshrc"

# Các phiên bản
ZLIB_VER="1.3.1"
PIXMAN_VER="0.46.4"
FREETYPE_VER="2.13.2"
CAIRO_VER="1.18.4"

echo "🚀 Bắt đầu quá trình cài đặt Cairo vào $PREFIX..."

# Tạo thư mục tạm
mkdir -p "$BUILD_DIR"
mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include"

# Hàm dọn dẹp khi hoàn tất hoặc lỗi
cleanup() {
    if [ $? -eq 0 ]; then
        echo "✅ Cài đặt thành công! Đang dọn dẹp thư mục tạm..."
        rm -rf "$BUILD_DIR"
    else
        echo "❌ Có lỗi xảy ra. Bạn có thể kiểm tra log tại $BUILD_DIR"
    fi
}
trap cleanup EXIT

# Thiết lập môi trường tạm thời để các bước build sau nhận diện được bước trước
export PATH="$PREFIX/bin:$PATH"
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$PREFIX/lib:$PREFIX/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"

cd "$BUILD_DIR"

# --- 2. Cài đặt Zlib (với -fPIC) ---
echo "📦 Đang cài đặt Zlib..."
curl -L "https://www.zlib.net/zlib-$ZLIB_VER.tar.gz" -o zlib.tar.gz
tar -xf zlib.tar.gz && cd "zlib-$ZLIB_VER"
CFLAGS="-fPIC" ./configure --prefix="$PREFIX"
make -j$(nproc) install
cd ..

# --- 3. Cài đặt Pixman ---
echo "📦 Đang cài đặt Pixman..."
curl -L "https://www.cairographics.org/releases/pixman-$PIXMAN_VER.tar.xz" -o pixman.tar.xz
tar -xf pixman.tar.xz && cd "pixman-$PIXMAN_VER"
meson setup builddir --prefix="$PREFIX" --buildtype=release -Dgtk=disabled -Dtests=disabled
ninja -C builddir install
cd ..

# --- 4. Cài đặt FreeType ---
echo "📦 Đang cài đặt FreeType..."
curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VER.tar.xz" -o freetype.tar.xz
tar -xf freetype.tar.xz && cd "freetype-$FREETYPE_VER"
./configure --prefix="$PREFIX" --without-harfbuzz
make -j$(nproc) install
cd ..

# --- 5. Cài đặt Cairo ---
echo "📦 Đang cài đặt Cairo..."
curl -L "https://www.cairographics.org/releases/cairo-$CAIRO_VER.tar.xz" -o cairo.tar.xz
tar -xf cairo.tar.xz && cd "cairo-$CAIRO_VER"
meson setup builddir --prefix="$PREFIX" --buildtype=release \
    -Dtests=disabled -Dglib=disabled -Dfontconfig=disabled \
    -Dfreetype=enabled -Dpng=enabled -Dxcb=disabled \
    -Dxlib=disabled -Dzlib=enabled -Dgtk_doc=false
ninja -C builddir install
cd ..

# --- 6. Tự động thêm ENV vào Shell Config ---
echo "🔧 Đang kiểm tra và cấu hình biến môi trường..."

# Mảng các dòng cần thêm
ENV_LINES=(
    "export PATH=\"\$HOME/.local/bin:\$PATH\""
    "export PKG_CONFIG_PATH=\"\$HOME/.local/lib/pkgconfig:\$HOME/.local/lib/x86_64-linux-gnu/pkgconfig:\$PKG_CONFIG_PATH\""
    "export LD_LIBRARY_PATH=\"\$HOME/.local/lib:\$HOME/.local/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH\""
)

for line in "${ENV_LINES[@]}"; do
    # Kiểm tra xem chuỗi đã tồn tại trong file chưa (không tính dấu quote)
    CLEAN_LINE=$(echo "$line" | sed 's/\\//g')
    if ! grep -Fq "$CLEAN_LINE" "$SHELL_CONFIG"; then
        echo "$line" >> "$SHELL_CONFIG"
        echo "➕ Đã thêm vào $SHELL_CONFIG: $line"
    else
        echo "⏭️ Đã tồn tại trong $SHELL_CONFIG, bỏ qua."
    fi
done

echo "🎉 Mọi thứ đã sẵn sẵn sàng! Hãy chạy lệnh: source $SHELL_CONFIG"
