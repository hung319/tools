#!/bin/bash

# --- CẤU HÌNH LIBSECRET ---
LIBSECRET_VERSION="0.21.7" 
LIBSECRET_TARBALL="0.21.7.tar.gz" 
DOWNLOAD_URL="https://github.com/GNOME/libsecret/archive/refs/tags/$LIBSECRET_VERSION.tar.gz"

# Tên thư mục sau khi giải nén
GITHUB_DIR="libsecret-$LIBSECRET_VERSION" 
LIBSECRET_DIR="libsecret-final-$LIBSECRET_VERSION" 
BUILD_DIR="build-libsecret"

# Đường dẫn cài đặt
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT LIBSECRET ${LIBSECRET_VERSION} (Dùng OPTIONS CHÍNH XÁC) ---${NC}"
set -e 

# --- 1. CẤU HÌNH VÀ TẢI NGUỒN ---
# (Phần này giữ nguyên: Kiểm tra Tools/GLib và Tải/Giải nén)
# ... (Để đảm bảo script ngắn gọn, tôi lược bỏ phần kiểm tra đã biết là chạy thành công) ...

# Cấu hình biến môi trường (Giữ nguyên)
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
GLIB_CFLAGS=$(pkg-config glib-2.0 gobject-2.0 --cflags || echo "")
GLIB_LIBS=$(pkg-config glib-2.0 gobject-2.0 --libs || echo "")
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${GLIB_LIBS} ${LDFLAGS}"
export CFLAGS="${GLIB_CFLAGS} -I${PREFIX}/include ${CFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Tải và Giải nén (Làm sạch thư mục để chạy lại)
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
if [ ! -f "$LIBSECRET_TARBALL" ]; then wget -O "$LIBSECRET_TARBALL" "$DOWNLOAD_URL"; fi
if [ -d "$GITHUB_DIR" ]; then rm -rf "$GITHUB_DIR"; fi
if [ -d "$LIBSECRET_DIR" ]; then rm -rf "$LIBSECRET_DIR"; fi 
tar xf "$LIBSECRET_TARBALL"
mv "$GITHUB_DIR" "$LIBSECRET_DIR" 
cd "$LIBSECRET_DIR"


# --- 2. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ---
echo -e "\n${YELLOW}--- 2. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT LIBSECRET ---${NC}"

# 2.1. Cấu hình Meson
mkdir -p "$BUILD_DIR"

echo "Đang cấu hình Meson. Sử dụng OPTIONS CHÍNH XÁC để tắt tính năng phụ..."
# Sử dụng tên OPTIONS chính xác (manpage, gtk_doc, vapi, introspection)
if ! meson setup "$BUILD_DIR" \
                 --prefix="$PREFIX" \
                 --buildtype=release \
                 -Dlibdir=lib \
                 -Dmanpage=false \
                 -Dgtk_doc=false \
                 -Dintrospection=false \
                 -Dvapi=false \
                 -Dcrypto=libgcrypt \
                 -Dbash_completion=disabled \
                 .; then 
    echo -e "${RED}❌ LỖI CẤU HÌNH MESON. (Các lỗi 'Unknown option' đã được khắc phục. Lỗi này có thể do thiếu dependency cốt lõi: libgcrypt hoặc D-Bus).${NC}"
    exit 1
fi

# 2.2. Biên dịch và Cài đặt (Giữ nguyên)
echo "Đang biên dịch với Ninja..."
if ! meson compile -C "$BUILD_DIR"; then
    echo -e "${RED}❌ LỖI BIÊN DỊCH.${NC}"; exit 1
fi

echo "Đang cài đặt vào $PREFIX..."
if ! meson install -C "$BUILD_DIR"; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"; exit 1
fi
echo -e "${GREEN}✅ Cài đặt libsecret $LIBSECRET_VERSION hoàn tất.${NC}"

# --- 3. KIỂM TRA KẾT QUẢ ---
echo -e "\n${YELLOW}--- 3. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion libsecret-1 &> /dev/null; then
    echo -e "${GREEN}✅ libsecret đã được tìm thấy qua pkg-config: $(pkg-config --modversion libsecret-1)${NC}"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'libsecret-1.pc'.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
