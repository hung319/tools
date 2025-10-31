#!/bin/bash

# --- CẤU HÌNH LIBHYPHEN TỪ GIT ---
REPO_URL="https://github.com/hunspell/hyphen.git"
HYPHEN_DIR="hyphen" # Thư mục sau khi clone

# Đường dẫn cài đặt (Sử dụng chung PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT LIBHYPHEN TỪ GIT (FIX LỖI .pc) ---${NC}"
set -e 

# --- 1. CẤU HÌNH VÀ KIỂM TRA MÔI TRƯỜNG ---
echo -e "\n${YELLOW}--- 1. CẤU HÌNH BIẾN MÔI TRƯỜNG & KIỂM TRA TOOLS ---${NC}"

# Cấu hình biến môi trường
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CFLAGS="-I${PREFIX}/include ${CFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Kiểm tra công cụ cần thiết (Thêm autopoint để đảm bảo gettext sẵn sàng)
for tool in gcc make wget tar pkg-config git autoreconf autopoint; do
    if ! command -v $tool &> /dev/null; then 
        echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt. Vui lòng cài đặt nó (ví dụ: gettext, autoconf).${NC}"; 
        exit 1
    fi
done
echo -e "${GREEN}✅ Các công cụ build và Git đã sẵn sàng.${NC}"

# --- 2. CLONE MÃ NGUỒN VÀ THIẾT LẬP AUTOTOOLS ---
echo -e "\n${YELLOW}--- 2. CLONE MÃ NGUỒN VÀ CHẠY AUTOCONF ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ -d "$HYPHEN_DIR" ]; then 
    echo "Thư mục $HYPHEN_DIR đã tồn tại, xóa để clone lại..."
    rm -rf "$HYPHEN_DIR"
fi

echo "Đang clone repository..."
git clone "$REPO_URL" "$HYPHEN_DIR"
cd "$HYPHEN_DIR"

# Chạy autoreconf để tạo file configure
echo "Chạy autoreconf -fi để tạo file configure..."
if ! autoreconf -fi; then
    echo -e "${RED}❌ LỖI: autoreconf thất bại. Nguyên nhân thường là do thiếu Gettext (autopoint).${NC}"
    exit 1
fi
echo -e "${GREEN}✅ autoreconf hoàn tất. File configure đã được tạo.${NC}"


# --- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ---
echo -e "\n${YELLOW}--- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT LIBHYPHEN ---${NC}"

# 3.1. Cấu hình
echo "Đang chạy ./configure với --disable-nls và --libdir=lib..."
# Cờ quan trọng: --disable-nls: Tắt NLS/gettext để tránh lỗi (thường liên quan đến việc không tạo .pc)
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static \
                 --disable-nls \
                 --disable-rpath \
                 ; then
    echo -e "${RED}❌ LỖI CẤU HÌNH (Configure).${NC}"; exit 1
fi

# 3.2. Biên dịch và Cài đặt
echo "Đang biên dịch với Make..."
if ! make -j$(nproc); then
    echo -e "${RED}❌ LỖI BIÊN DỊCH (Make).${NC}"; exit 1
fi

echo "Đang cài đặt vào $PREFIX..."
if ! make install; then
    echo -e "${RED}❌ LỖI CÀI ĐẶT.${NC}"; exit 1
fi
echo -e "${GREEN}✅ Cài đặt LibHyphen hoàn tất.${NC}"

# --- 4. KIỂM TRA KẾT QUẢ VÀ LÀM SẠCH ---
echo -e "\n${YELLOW}--- 4. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"

if pkg-config --exists hyphen; then
    echo -e "${GREEN}✅ LibHyphen đã được tìm thấy qua pkg-config: $(pkg-config --modversion hyphen)${NC}"
else
    # Nếu vẫn không tìm thấy, cố gắng tìm file .pc thủ công để xác nhận tên
    FOUND_PC=$(find "$PREFIX/lib" -name "*.pc" | grep -i "hyphen")
    if [ -n "$FOUND_PC" ]; then
        echo -e "${CYAN}💡 LibHyphen có thể đã được tìm thấy nhưng với tên khác:${NC}"
        echo "$FOUND_PC"
    else
        echo -e "${RED}❌ LỖI: Không tìm thấy file '.pc' nào cho LibHyphen.${NC}"
    fi
fi
echo -e "------------------------------------------------------------------${NC}"
