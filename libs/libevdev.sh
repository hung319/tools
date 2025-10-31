#!/bin/bash

# --- CẤU HÌNH LIBEVDEV ---
EVDEV_VERSION="1.11.0" 
EVDEV_TARBALL="libevdev-$EVDEV_VERSION.tar.xz"
DOWNLOAD_URL="https://www.freedesktop.org/software/libevdev/$EVDEV_TARBALL"
EVDEV_DIR="libevdev-$EVDEV_VERSION"

# Đường dẫn cài đặt (Sử dụng chung PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT LIBEVDEV ${EVDEV_VERSION} vào $PREFIX ---${NC}"
set -e 

# --- 1. THIẾT LẬP VÀ KIỂM TRA MÔI TRƯỜNG ---
echo -e "\n${YELLOW}--- 1. CẤU HÌNH BIẾN MÔI TRƯỜNG & KIỂM TRA TOOLS ---${NC}"

# Cấu hình biến môi trường
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CFLAGS="-I${PREFIX}/include ${CFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

# Kiểm tra công cụ cần thiết
for tool in gcc make wget tar pkg-config; do
    if ! command -v $tool &> /dev/null; then echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt.${NC}"; exit 1; fi
done
echo -e "${GREEN}✅ Các công cụ build cơ bản đã sẵn sàng.${NC}"

# --- 2. TẢI VÀ GIẢI NÉN MÃ NGUỒN ---
echo -e "\n${YELLOW}--- 2. TẢI VÀ GIẢI NÉN LIBEVDEV ---${NC}"
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

if [ ! -f "$EVDEV_TARBALL" ]; then
    echo "Đang tải $EVDEV_TARBALL từ $DOWNLOAD_URL..."
    if ! wget "$DOWNLOAD_URL"; then
        echo -e "${RED}❌ LỖI: Không thể tải file.${NC}"; exit 1
    fi
else
    echo "File $EVDEV_TARBALL đã tồn tại."
fi

if [ -d "$EVDEV_DIR" ]; then rm -rf "$EVDEV_DIR"; fi
echo "Đang giải nén..."
# Libevdev dùng .tar.xz nên cần cờ J (hoặc a)
tar xJf "$EVDEV_TARBALL"
cd "$EVDEV_DIR"

# --- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT ---
echo -e "\n${YELLOW}--- 3. CẤU HÌNH, BIÊN DỊCH VÀ CÀI ĐẶT LIBEVDEV ---${NC}"

# 3.1. Cấu hình
echo "Đang chạy ./configure..."
# Tắt docs, test và static libraries
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static \
                 --disable-silent-rules \
                 --disable-documentation \
                 --disable-tests \
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
echo -e "${GREEN}✅ Cài đặt Libevdev $EVDEV_VERSION hoàn tất.${NC}"

# --- 4. KIỂM TRA KẾT QUẢ ---
echo -e "\n${YELLOW}--- 4. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"
if pkg-config --modversion libevdev &> /dev/null; then
    echo -e "${GREEN}✅ Libevdev đã được tìm thấy qua pkg-config: $(pkg-config --modversion libevdev)${NC}"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'libevdev.pc'.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
