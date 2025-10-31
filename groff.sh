#!/bin/bash

# --- CẤU HÌNH GROFF ---
GROFF_VERSION="1.23.0" # Phiên bản mới nhất
GROFF_TARBALL="groff-$GROFF_VERSION.tar.gz"
DOWNLOAD_URL="https://ftp.gnu.org/gnu/groff/$GROFF_TARBALL"
GROFF_DIR="groff-$GROFF_VERSION"

# Đường dẫn cài đặt (Sử dụng chung PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT GROFF ${GROFF_VERSION} vào $PREFIX ---${NC}"
set -e 

# --- 1. THIẾT LẬP VÀ KIỂM TRA MÔI TRƯỜNG ---
echo -e "\n${YELLOW}--- 1. CẤU HÌNH BIẾN MÔI TRƯỜNG ---${NC}"

# Đảm bảo PATH được cập nhật để sử dụng lệnh 'groff' sau khi cài đặt
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Kiểm tra công cụ cần thiết (Autotools)
for tool in gcc make wget tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt. Vui lòng cài đặt nó.${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✅ Các công cụ build cơ bản đã sẵn sàng.${NC}"

# --- 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN ---
echo -e "\n${YELLOW}--- 2. TẢI VÀ GIẢI NÉN GROFF ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$GROFF_TARBALL" ]; then
    echo "Đang tải $GROFF_TARBALL từ $DOWNLOAD_URL..."
    if ! wget "$DOWNLOAD_URL"; then
        echo -e "${RED}❌ LỖI: Không thể tải file. Kiểm tra URL/kết nối mạng.${NC}"
        exit 1
    fi
else
    echo "File $GROFF_TARBALL đã tồn tại, làm sạch và giải nén lại."
fi

if [ -d "$GROFF_DIR" ]; then
    rm -rf "$GROFF_DIR"
fi

echo "Đang giải nén..."
tar xf "$GROFF_TARBALL"
cd "$GROFF_DIR"

# --- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ---
echo -e "\n${YELLOW}--- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT GROFF ---${NC}"

# Configure: Sử dụng --prefix và --libdir để cài đặt vào thư mục cục bộ
echo "Đang chạy ./configure..."
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static \
                 --without-x ; then # Tắt các tính năng GUI không cần thiết
    echo -e "${RED}❌ LỖI CẤU HÌNH (Configure).${NC}"
    exit 1
fi

# Biên dịch
echo "Đang biên dịch với Make..."
if ! make -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH (Make).${NC}"
    exit 1
fi

# Cài đặt
echo "Đang cài đặt vào $PREFIX..."
if ! make install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Cài đặt Groff $GROFF_VERSION hoàn tất.${NC}"

# --- 4. KIỂM TRA KẾT QUẢ ---
echo -e "\n${YELLOW}--- 4. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
# Cần chạy lệnh export PATH để kiểm tra ngay lập tức
export PATH="$HOME/.local/bin:$PATH"
if command -v groff &> /dev/null; then
    echo -e "${GREEN}✅ Lệnh 'groff' đã được tìm thấy tại: $(which groff)${NC}"
    echo "Bây giờ bạn có thể thử chạy lại script cài đặt libenchant."
else
    echo -e "${RED}❌ LỖI: Không tìm thấy lệnh 'groff' sau khi cài đặt. Vui lòng kiểm tra lại quá trình build.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
