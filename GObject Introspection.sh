#!/bin/bash

# --- CẤU HÌNH GOBJECT INTROSPECTION ---
GI_VERSION="1.86.0" 
GI_TARBALL="gobject-introspection-$GI_VERSION.tar.xz"
DOWNLOAD_URL="https://download.gnome.org/sources/gobject-introspection/1.86/$GI_TARBALL"
GI_DIR="gobject-introspection-$GI_VERSION"
BUILD_DIR="build"

# Các biến đã được thiết lập từ script Python trước đó
export DEPS_PREFIX="$HOME/.local" 
export PYTHON_PREFIX="$HOME/.local/python"
export PYTHON_MAJOR="3.12"
export SRC_DIR="$HOME/src/py-build-deps"
export PREFIX="${DEPS_PREFIX}"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT GOBJECT INTROSPECTION (Sửa chữa File) ---${NC}"

## 1. THIẾT LẬP BIẾN MÔI TRƯỜNG
echo -e "\n${YELLOW}--- THIẾT LẬP BIẾN MÔI TRƯỜNG ---${NC}"

# Cấu hình PATH, PKG_CONFIG_PATH, LDFLAGS
export PATH="${PYTHON_PREFIX}/bin:${DEPS_PREFIX}/bin:${PATH}"
export PKG_CONFIG_PATH="${DEPS_PREFIX}/lib/pkgconfig:${DEPS_PREFIX}/lib64/pkgconfig:${PKG_CONFIG_PATH}"
export LDFLAGS="-L${DEPS_PREFIX}/lib -L${DEPS_PREFIX}/lib64 -Wl,-rpath,${DEPS_PREFIX}/lib -Wl,-rpath,${DEPS_PREFIX}/lib64 ${LDFLAGS}"

# **GIẢM CƯỜNG CPPFLAGS:** Giữ nguyên các cờ để phòng hờ, nhưng lỗi Macro được giải quyết bằng cách include trực tiếp.
export CPPFLAGS="-I${DEPS_PREFIX}/include -I${PYTHON_PREFIX}/include/python${PYTHON_MAJOR} -D_POSIX_C_SOURCE=200809L -D_GNU_SOURCE ${CPPFLAGS}"
export CPATH="${PYTHON_PREFIX}/include/python${PYTHON_MAJOR}:${CPATH}"

## 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN
echo -e "\n${YELLOW}--- TẢI VÀ GIẢI NÉN GOBJECT INTROSPECTION ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
# ... (Tải và giải nén) ...
if [ ! -f "$GI_TARBALL" ]; then wget "$DOWNLOAD_URL"; fi
if [ -d "$GI_DIR" ]; then rm -rf "$GI_DIR"; fi
tar xf "$GI_TARBALL"
cd "$GI_DIR"

## 3. CẤU HÌNH MESON (Phải chạy CẤU HÌNH trước để tạo config.h)
echo "Đang CẤU HÌNH Meson (tạo config.h)..."
if ! meson setup --prefix="$PREFIX" \
                 --buildtype=release \
                 -Dgtk_doc=false \
                 -Dcairo=disabled \
                 "$BUILD_DIR"; then
    echo -e "${RED}❌ LỖI CẤU HÌNH MESON. Vui lòng kiểm tra dependencies (GLib).${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cấu hình Meson thành công. config.h đã được tạo.${NC}"

## 4. CHỈNH SỬA FILE MÃ NGUỒN ĐỂ KHẮC PHỤC LỖI
echo -e "\n${YELLOW}--- SỬA CHỮA MÃ NGUỒN TỰ ĐỘNG KHẮC PHỤC LỖI BIÊN DỊCH ---${NC}"

# Khắc phục LỖI MACRO (GIR_SUFFIX, GOBJECT_INTROSPECTION_DATADIR)
echo "   -> Thêm include config.h vào girepository/girparser.c và girepository.c"
sed -i 's/#include "girepository-internals.h"/#include "girepository-internals.h"\n#include "../build/config.h"/' girepository/girparser.c
sed -i 's/#include "girepository-private.h"/#include "girepository-private.h"\n#include "../build/config.h"/' girepository/girepository.c

# Khắc phục LỖI PYTHON HEADER (PyObject*)
echo "   -> Thêm define _POSIX_C_SOURCE vào giscanner/giscannermodule.c"
sed -i '1i#define _POSIX_C_SOURCE 200809L' giscanner/giscannermodule.c

echo -e "${GREEN}✅ Sửa chữa file hoàn tất.${NC}"

## 5. BIÊN DỊCH VÀ CÀI ĐẶT
cd "$BUILD_DIR"
echo -e "\n${YELLOW}--- BIÊN DỊCH LẠI VỚI SỬA CHỮA ---${NC}"

echo "Đang biên dịch với Ninja..."
if ! ninja -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH. Lỗi có thể do thiếu dependency lõi GLib/libffi.${NC}"
    exit 1
fi

echo "Đang cài đặt vào $PREFIX..."
if ! ninja install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"
    exit 1
fi

## 6. KIỂM TRA KẾT QUẢ
echo -e "\n${YELLOW}--- KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
if pkg-config --modversion gobject-introspection-1.0 &> /dev/null; then
    echo -e "${GREEN}✅ Cài đặt GObject Introspection $GI_VERSION THÀNH CÔNG!${NC}"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'gobject-introspection-1.0.pc' sau khi cài đặt.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
