#!/bin/bash

# --- CẤU HÌNH HARFBUZZ ---
HB_VERSION="12.1.0" # Phiên bản mới nhất được tìm thấy trong log (sử dụng 12.1.0)
HB_TARBALL="harfbuzz-$HB_VERSION.tar.xz"
DOWNLOAD_URL="https://github.com/harfbuzz/harfbuzz/releases/download/$HB_VERSION/$HB_TARBALL"
HB_DIR="harfbuzz-$HB_VERSION"
BUILD_DIR="build-hb"

# Đường dẫn cài đặt (Sử dụng chung DEPS_PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT HARFBUZZ ${HB_VERSION} vào $PREFIX ---${NC}"
set -e # Thoát nếu có lỗi

## 1. THIẾT LẬP BIẾN MÔI TRƯỜNG
echo -e "\n${YELLOW}--- THIẾT LẬP BIẾN MÔI TRƯỜNG ---${NC}"

# Đảm bảo PATH, PKG_CONFIG_PATH, LDFLAGS được cấu hình đầy đủ từ GLib/Python
# Rất quan trọng: Bạn cần đảm bảo đã chạy 'source' file cấu hình shell sau khi cài GLib/Python!
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
# Nếu bạn cài GLib vào đường dẫn x86_64-linux-gnu, hãy thêm nó vào PKG_CONFIG_PATH và LD_LIBRARY_PATH
# Ví dụ: export PKG_CONFIG_PATH="$HOME/.local/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"


# Kiểm tra công cụ cần thiết (Meson/Ninja)
for tool in meson ninja wget tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt. Vui lòng cài đặt nó.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Các công cụ build (Meson/Ninja) đã sẵn sàng.${NC}"

## 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN
echo -e "\n${YELLOW}--- TẢI VÀ GIẢI NÉN HARFBUZZ ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$HB_TARBALL" ]; then
    echo "Đang tải $HB_TARBALL từ $DOWNLOAD_URL..."
    if ! wget "$DOWNLOAD_URL"; then
        echo -e "${RED}❌ LỖI: Không thể tải file. Kiểm tra URL/kết nối mạng.${NC}"
        exit 1
    fi
else
    echo "File $HB_TARBALL đã tồn tại, bỏ qua bước tải."
fi

if [ -d "$HB_DIR" ]; then
    rm -rf "$HB_DIR"
fi

echo "Đang giải nén..."
tar xf "$HB_TARBALL"
cd "$HB_DIR"

## 3. BIÊN DỊCH VÀ CÀI ĐẶT
echo -e "\n${YELLOW}--- BIÊN DỊCH VÀ CÀI ĐẶT HARFBUZZ ---${NC}"

# Tạo thư mục build
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Đang cấu hình Meson. Sử dụng -Dlibdir=lib và TẮT DEPENDENCY không bắt buộc..."
# Tùy chọn quan trọng:
# -Dlibdir=lib: Đảm bảo cài đặt vào $PREFIX/lib
# -Dcoretext=disabled: Tắt nếu không phải macOS
# -Dicu=disabled: Tắt hỗ trợ ICU (dependency lớn)
# -Dgraphite2=disabled: Tắt Graphite2 (dependency không bắt buộc)
# -Ddocs=disabled: Tắt build tài liệu
if ! meson setup --prefix="$PREFIX" \
                 --buildtype=release \
                 -Dlibdir=lib \
                 -Dcoretext=disabled \
                 -Dicu=disabled \
                 -Dgraphite2=disabled \
                 -Ddocs=disabled \
                 ..; then
    echo -e "${RED}❌ LỖI CẤU HÌNH MESON.${NC}"
    echo "HarfBuzz RẤT CẦN FREETYPE. Vui lòng đảm bảo thư viện FreeType đã được cài đặt và pkg-config tìm thấy (freetype2.pc)."
    exit 1
fi

echo "Đang biên dịch với Ninja..."
if ! ninja -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH.${NC}"
    exit 1
fi

echo "Đang cài đặt vào $PREFIX..."
if ! ninja install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"
    exit 1
fi

## 4. KIỂM TRA KẾT QUẢ
echo -e "\n${YELLOW}--- KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
# Cần chạy lệnh export PKG_CONFIG_PATH để kiểm tra ngay lập tức
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion harfbuzz &> /dev/null; then
    echo -e "${GREEN}✅ Cài đặt HarfBuzz $HB_VERSION THÀNH CÔNG!${NC}"
    echo "Phiên bản được cài đặt: $(pkg-config --modversion harfbuzz)"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'harfbuzz.pc' sau khi cài đặt.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
