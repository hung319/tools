#!/bin/bash

# --- CẤU HÌNH LIBCRYPT DEPENDENCY ---
GPG_ERROR_VERSION="1.47" 
GPG_ERROR_TARBALL="libgpg-error-$GPG_ERROR_VERSION.tar.bz2"
GPG_ERROR_URL="https://gnupg.org/ftp/gcrypt/libgpg-error/$GPG_ERROR_TARBALL"
GPG_ERROR_DIR="libgpg-error-$GPG_ERROR_VERSION"

# --- CẤU HÌNH LIBCRYPT ---
GCRYPT_VERSION="1.10.0" 
GCRYPT_TARBALL="libgcrypt-$GCRYPT_VERSION.tar.bz2"
GCRYPT_URL="https://gnupg.org/ftp/gcrypt/libgcrypt/$GCRYPT_TARBALL"
GCRYPT_DIR="libgcrypt-$GCRYPT_VERSION"

# Đường dẫn cài đặt (Sử dụng chung PREFIX)
export PREFIX="$HOME/.local" 
export SRC_DIR="$HOME/src/py-build-deps"

# --- Màu sắc ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${YELLOW}--- BẮT ĐẦU CÀI ĐẶT LIBGPG-ERROR VÀ LIBCRYPT vào $PREFIX ---${NC}"
set -e 

# --- CẤU HÌNH BAN ĐẦU ---
echo -e "\n${YELLOW}--- 1. CẤU HÌNH BIẾN MÔI TRƯỜNG ---${NC}"
export PATH="${PREFIX}/bin:$PATH"
export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PREFIX}/lib64/pkgconfig:$PKG_CONFIG_PATH"
# Cần CFLAGS/LDFLAGS để GCC tìm thấy các thư viện đã cài đặt
export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64 -Wl,-rpath,${PREFIX}/lib -Wl,-rpath,${PREFIX}/lib64 ${LDFLAGS}"
export CFLAGS="-I${PREFIX}/include ${CFLAGS}"
export CPPFLAGS="-I${PREFIX}/include ${CPPFLAGS}"

for tool in gcc make wget tar pkg-config; do
    if ! command -v $tool &> /dev/null; then echo -e "${RED}❌ Lỗi: Công cụ '$tool' chưa được cài đặt.${NC}"; exit 1; fi
done


## BƯỚC A: CÀI ĐẶT LIBGPG-ERROR
echo -e "\n${YELLOW}--- 2. CÀI ĐẶT LIBGPG-ERROR (DEPENDENCY CỦA LIBCRYPT) ---${NC}"
cd "$SRC_DIR"
echo "Tải $GPG_ERROR_TARBALL..."
if [ ! -f "$GPG_ERROR_TARBALL" ]; then wget "$GPG_ERROR_URL"; fi
if [ -d "$GPG_ERROR_DIR" ]; then rm -rf "$GPG_ERROR_DIR"; fi
tar xf "$GPG_ERROR_TARBALL"
cd "$GPG_ERROR_DIR"

echo "Chạy ./configure cho Libgpg-error..."
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static; then
    echo -e "${RED}❌ LỖI CẤU HÌNH LIBGPG-ERROR.${NC}"; exit 1
fi
echo "Biên dịch và cài đặt Libgpg-error..."
make -j$(nproc) && make install
echo -e "${GREEN}✅ Cài đặt Libgpg-error hoàn tất!${NC}"


## BƯỚC B: CÀI ĐẶT LIBCRYPT
echo -e "\n${YELLOW}--- 3. CÀI ĐẶT LIBCRYPT ${GCRYPT_VERSION} ---${NC}"
cd "$SRC_DIR"
echo "Tải $GCRYPT_TARBALL..."
if [ ! -f "$GCRYPT_TARBALL" ]; then wget "$GCRYPT_URL"; fi
if [ -d "$GCRYPT_DIR" ]; then rm -rf "$GCRYPT_DIR"; fi
tar xf "$GCRYPT_TARBALL"
cd "$GCRYPT_DIR"

echo "Chạy ./configure cho Libgcrypt..."
# Cờ quan trọng: Tắt các tính năng không cần thiết (tests, man)
if ! ./configure --prefix="$PREFIX" \
                 --libdir="$PREFIX/lib" \
                 --disable-static \
                 --disable-asm \
                 --disable-padlock-support \
                 --disable-doc ; then
    echo -e "${RED}❌ LỖI CẤU HÌNH LIBGCRYPT. Kiểm tra xem libgpg-error đã được tìm thấy chưa.${NC}"; exit 1
fi
echo "Biên dịch và cài đặt Libgcrypt..."
make -j$(nproc) && make install
echo -e "${GREEN}✅ Cài đặt Libgcrypt hoàn tất!${NC}"


## BƯỚC C: KIỂM TRA KẾT QUẢ
echo -e "\n${YELLOW}--- 4. KIỂM TRA KẾT QUẢ CÀI ĐẶT ---${NC}"
export PKG_CONFIG_PATH="$HOME/.local/lib/pkgconfig:$PKG_CONFIG_PATH"

if pkg-config --modversion libgcrypt &> /dev/null; then
    echo -e "${GREEN}✅ Libgcrypt đã được tìm thấy qua pkg-config: $(pkg-config --modversion libgcrypt)${NC}"
else
    echo -e "${RED}❌ LỖI: Không tìm thấy 'libgcrypt.pc'.${NC}"
fi
echo -e "------------------------------------------------------------------${NC}"
