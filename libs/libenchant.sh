#!/bin/bash

# --- CẤU HÌNH ENCHANT 2.8.12 ---
ENCHANT_VERSION="2.8.12" 
ENCHANT_TARBALL="enchant-$ENCHANT_VERSION.tar.gz"
DOWNLOAD_URL="https://github.com/rrthomas/enchant/releases/download/v$ENCHANT_VERSION/$ENCHANT_TARBALL"
ENCHANT_DIR="enchant-$ENCHANT_VERSION"

# Đường dẫn cài đặt
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"
ENCHANT_PLUGIN_DIR="${PREFIX}/lib/enchant-2" # Đường dẫn gây lỗi

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU LẠI CÀI ĐẶT LIBENCHANT ${ENCHANT_VERSION} (Khắc phục Lỗi Thư mục Plugin) ---${NC}"
set -e 

# --- 1. THIẾT LẬP VÀ CẤU HÌNH BIẾN ---
echo -e "\n${YELLOW}--- 1. CẤU HÌNH BIẾN MÔI TRƯỜNG & KIỂM TRA GLIB ---${NC}"

# Cấu hình biến môi trường (Giữ nguyên)
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
GLIB_CFLAGS=$(pkg-config glib-2.0 gobject-2.0 --cflags || echo "")
GLIB_LIBS=$(pkg-config glib-2.0 gobject-2.0 --libs || echo "")
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${GLIB_LIBS} ${LDFLAGS}"
export CFLAGS="${GLIB_CFLAGS} -I${PREFIX}/include ${CFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Kiểm tra công cụ và GLib (Giữ nguyên)
for tool in gcc make wget tar pkg-config; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt.${NC}"
        exit 1
    fi
done
if ! pkg-config --exists glib-2.0; then
    echo -e "${RED}❌ Lỗi: Không tìm thấy GLib-2.0. Không thể tiếp tục.${NC}"
    exit 1
fi


# --- 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN ---
echo -e "\n${YELLOW}--- 2. TẢI VÀ GIẢI NÉN ENCHANT ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
if [ ! -f "$ENCHANT_TARBALL" ]; then wget "$DOWNLOAD_URL"; fi
if [ -d "$ENCHANT_DIR" ]; then rm -rf "$ENCHANT_DIR"; fi
tar xf "$ENCHANT_TARBALL"
cd "$ENCHANT_DIR"


# --- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ---
echo -e "\n${YELLOW}--- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ENCHANT ---${NC}"

# Cấu hình (Giữ nguyên)
echo "Đang chạy ./configure..."
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --enable-relocatable \
                 --disable-static \
                 --disable-hunspell \
                 --disable-aspell \
                 --disable-doc \
                 --disable-man \
                 --disable-introspection \
                 ; then
    echo -e "${RED}❌ LỖI CẤU HÌNH (Configure). Vui lòng kiểm tra log.${NC}"
    exit 1
fi

# Biên dịch
echo "Đang biên dịch với Make..."
if ! make -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH (Make).${NC}"
    exit 1
fi

# TẠO THƯ MỤC PLUGIN TRƯỚC KHI CÀI ĐẶT (Giải pháp cho lỗi No such file or directory)
echo -e "\n${CYAN}Tạo thư mục plugin Enchant: $ENCHANT_PLUGIN_DIR${NC}"
mkdir -p "$ENCHANT_PLUGIN_DIR"

# Cài đặt
echo "Đang cài đặt vào $PREFIX..."
if ! make install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cài đặt libenchant $ENCHANT_VERSION hoàn tất.${NC}"


# --- 4. KIỂM TRA KẾT QUẢ ---
echo -e "\n${YELLOW}--- 4. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion enchant-2 &> /dev/null; then
    echo -e "${GREEN}✅ libenchant (Enchant 2) đã được tìm thấy qua pkg-config: $(pkg-config --modversion enchant-2)${NC}"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'enchant-2.pc'. Vui lòng kiểm tra lại quá trình build.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
