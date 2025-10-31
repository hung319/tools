#!/bin/bash

# --- CẤU HÌNH FREETYPE 2 ---
FT_VERSION="2.13.2" # Phiên bản ổn định mới nhất
FT_TARBALL="freetype-$FT_VERSION.tar.xz"
DOWNLOAD_URL="https://download.savannah.gnu.org/releases/freetype/freetype-$FT_VERSION.tar.xz"
FT_DIR="freetype-$FT_VERSION"
BUILD_DIR="build-ft"

# Đường dẫn cài đặt (Sử dụng chung PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT FREETYPE 2 ${FT_VERSION} vào $PREFIX ---${NC}"
set -e 

## 1. THIẾT LẬP BIẾN MÔI TRƯỜNG
echo -e "\n${YELLOW}--- THIẾT LẬP BIẾN MÔI TRƯỜNG ---${NC}"

# Đảm bảo PATH, PKG_CONFIG_PATH, LDFLAGS đã được thiết lập từ các bước trước
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Kiểm tra công cụ cần thiết (FreeType vẫn dùng Autotools cho configure)
for tool in gcc make wget tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt. Vui lòng cài đặt nó.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Các công cụ build cơ bản đã sẵn sàng.${NC}"

## 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN
echo -e "\n${YELLOW}--- TẢI VÀ GIẢI NÉN FREETYPE ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$FT_TARBALL" ]; then
    echo "Đang tải $FT_TARBALL từ $DOWNLOAD_URL..."
    if ! wget "$DOWNLOAD_URL"; then
        echo -e "${RED}❌ LỖI: Không thể tải file. Kiểm tra URL/kết nối mạng.${NC}"
        exit 1
    fi
else
    echo "File $FT_TARBALL đã tồn tại, bỏ qua bước tải."
fi

if [ -d "$FT_DIR" ]; then
    rm -rf "$FT_DIR"
fi

echo "Đang giải nén..."
tar xf "$FT_TARBALL"
cd "$FT_DIR"

## 3. BIÊN DỊCH VÀ CÀI ĐẶT
echo -e "\n${YELLOW}--- BIÊN DỊCH VÀ CÀI ĐẶT FREETYPE (Sử dụng Autotools) ---${NC}"

# Autotools configure: sử dụng --prefix=$PREFIX và --libdir=$PREFIX/lib
echo "Đang cấu hình..."
# Cờ quan trọng: --with-harfbuzz=no (để tránh dependency vòng lặp nếu HarfBuzz chưa cài)
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static \
                 --with-harfbuzz=no; then
    echo -e "${RED}❌ LỖI CẤU HÌNH FREETYPE. Vui lòng kiểm tra log configure.${NC}"
    exit 1
fi

echo "Đang biên dịch với Make..."
if ! make -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH.${NC}"
    exit 1
fi

echo "Đang cài đặt vào $PREFIX..."
if ! make install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"
    exit 1
fi

## 4. KIỂM TRA KẾT QUẢ
echo -e "\n${YELLOW}--- KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"

# Cần chạy lệnh export PKG_CONFIG_PATH để kiểm tra ngay lập tức
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion freetype2 &> /dev/null; then
    echo -e "${GREEN}✅ Cài đặt FreeType 2 $FT_VERSION THÀNH CÔNG!${NC}"
    echo "Phiên bản được cài đặt: $(pkg-config --modversion freetype2)"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'freetype2.pc' sau khi cài đặt.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
