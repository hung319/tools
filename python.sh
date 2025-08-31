#!/bin/bash

# --- Cấu hình ---
# Phiên bản các thành phần
PYTHON_VERSION="3.12.8"
PYTHON_MAJOR="3.12"
OPENSSL_VERSION="3.3.1"
ZLIB_VERSION="1.3.1"
LIBFFI_VERSION="3.4.6"
BZIP2_VERSION="1.0.8"
XZ_VERSION="5.6.2" # liblzma
SQLITE_VERSION="3460000" # Version 3.46.0

# Đường dẫn
DEPS_PREFIX="$HOME/.local"                 # Nơi cài đặt các thư viện phụ thuộc (zlib, openssl...)
PYTHON_PREFIX="$HOME/.local/python"        # Nơi cài đặt Python riêng biệt
SRC_DIR="$HOME/src/py-build-deps"

# Biến môi trường để build
# Hướng dẫn trình biên dịch tìm headers và libs trong thư mục cài đặt thư viện phụ thuộc
export PKG_CONFIG_PATH="${DEPS_PREFIX}/lib/pkgconfig:${DEPS_PREFIX}/lib64/pkgconfig"
export CPPFLAGS="-I${DEPS_PREFIX}/include"
export LDFLAGS="-L${DEPS_PREFIX}/lib -L${DEPS_PREFIX}/lib64 -Wl,-rpath,${DEPS_PREFIX}/lib -Wl,-rpath,${DEPS_PREFIX}/lib64"


# --- Màu sắc để thông báo ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- Bắt đầu Script ---
set -e # Thoát ngay nếu có lỗi
clear

echo -e "${GREEN}Bắt đầu quá trình cài đặt Python ${PYTHON_VERSION} (Không cần root, có kiểm tra thư viện).${NC}"


# --- Bước 0: Kiểm tra công cụ cơ bản và tạo thư mục ---
echo -e "\n${YELLOW}Bước 0: Kiểm tra công cụ và chuẩn bị thư mục...${NC}"
for tool in gcc make wget curl tar; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}Lỗi: Không tìm thấy công cụ '$tool'. Vui lòng cài đặt nó trước.${NC}"
        exit 1
    fi
done

mkdir -p "${SRC_DIR}"
mkdir -p "${DEPS_PREFIX}/bin"
mkdir -p "${PYTHON_PREFIX}"
cd "${SRC_DIR}"


# --- Bước 1: Biên dịch các thư viện phụ thuộc (nếu cần) ---
echo -e "\n${YELLOW}Bước 1: Kiểm tra và biên dịch các thư viện phụ thuộc...${NC}"

# Hàm trợ giúp để tải và giải nén
download_and_extract() {
    url=$1
    filename=$(basename "$url")
    dirname=${filename%.tar.gz}
    dirname=${dirname%.tgz}
    dirname=${dirname%.tar.xz}
    dirname=${dirname%.tar.bz2}

    if [ ! -d "$dirname" ]; then
        if [ ! -f "$filename" ]; then
            echo "   -> Đang tải $filename..."
            wget -q --show-progress "$url"
        fi
        echo "   -> Đang giải nén $filename..."
        tar -xf "$filename"
    fi
    cd "$dirname"
}

# 1.1. zlib
if [ -f "${DEPS_PREFIX}/lib/libz.so" ]; then
    echo -e "${CYAN}- Zlib đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build ZLIB...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
    ./configure --prefix="${DEPS_PREFIX}"
    make -j$(nproc) > /dev/null 2>&1 && make install > /dev/null 2>&1
    echo -e "${GREEN}  ==> Build ZLIB thành công!${NC}"
fi

# 1.2. OpenSSL
if [ -f "${DEPS_PREFIX}/lib/libssl.so" ]; then
    echo -e "${CYAN}- OpenSSL đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build OPENSSL (quan trọng cho pip)...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
    # Build shared library (bỏ no-shared), thêm zlib để nén
    ./config shared --prefix="${DEPS_PREFIX}" --openssldir="${DEPS_PREFIX}" zlib
    make -j$(nproc)
    make install_sw
    echo -e "${GREEN}  ==> Build OPENSSL thành công!${NC}"
fi

# 1.3. libffi
if [ -f "${DEPS_PREFIX}/lib/libffi.so" ]; then
    echo -e "${CYAN}- libffi đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build LIBFFI (quan trọng cho ctypes)...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz"
    ./configure --prefix="${DEPS_PREFIX}" --disable-static
    make -j$(nproc) && make install
    echo -e "${GREEN}  ==> Build LIBFFI thành công!${NC}"
fi

# 1.4. bzip2
if [ -f "${DEPS_PREFIX}/lib/libbz2.so" ]; then
    echo -e "${CYAN}- bzip2 đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build BZIP2...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://sourceware.org/pub/bzip2/bzip2-${BZIP2_VERSION}.tar.gz"
    # === SỬA LỖI: Thêm CFLAGS="-fPIC" để tạo Position-Independent Code ===
    make CFLAGS="-fPIC" -j$(nproc)
    make install CFLAGS="-fPIC" PREFIX="${DEPS_PREFIX}"
    # ====================================================================
    echo -e "${GREEN}  ==> Build BZIP2 thành công!${NC}"
fi

# 1.5. xz (liblzma)
if [ -f "${DEPS_PREFIX}/lib/liblzma.so" ]; then
    echo -e "${CYAN}- xz (liblzma) đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build XZ (liblzma)...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://github.com/tukaani-project/xz/releases/download/v${XZ_VERSION}/xz-${XZ_VERSION}.tar.gz"
    ./configure --prefix="${DEPS_PREFIX}" --disable-static
    make -j$(nproc) && make install
    echo -e "${GREEN}  ==> Build XZ thành công!${NC}"
fi

# 1.6. SQLite3
if [ -f "${DEPS_PREFIX}/lib/libsqlite3.so" ]; then
    echo -e "${CYAN}- SQLite3 đã được cài đặt, bỏ qua.${NC}"
else
    echo -e "${CYAN}- Bắt đầu build SQLITE3...${NC}"
    cd "${SRC_DIR}"
    download_and_extract "https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_VERSION}.tar.gz"
    # Thêm CFLAGS="-fPIC" để đảm bảo tính tương thích
    CFLAGS="-fPIC" ./configure --prefix="${DEPS_PREFIX}"
    make -j$(nproc) && make install
    echo -e "${GREEN}  ==> Build SQLITE3 thành công!${NC}"
fi


# --- Bước 2: Biên dịch và cài đặt Python ---
echo -e "\n${YELLOW}Bước 2: Biên dịch và cài đặt Python vào ${PYTHON_PREFIX}...${NC}"
cd "${SRC_DIR}"
download_and_extract "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"

# Cấu hình với prefix của Python, nhưng vẫn dùng các biến env để link tới prefix của thư viện
./configure --prefix="${PYTHON_PREFIX}" \
            --enable-optimizations \
            --with-openssl="${DEPS_PREFIX}" \
            --with-ensurepip=install

make -j$(nproc)
make altinstall
echo -e "${GREEN}==> Cài đặt Python thành công!${NC}"


# --- Bước 3: Tạo symbolic links và cấu hình môi trường ---
echo -e "\n${YELLOW}Bước 3: Tạo symbolic links và cấu hình Shell...${NC}"

# Tạo links trong thư mục bin của Python
ln -sf "${PYTHON_PREFIX}/bin/python${PYTHON_MAJOR}" "${PYTHON_PREFIX}/bin/python"
ln -sf "${PYTHON_PREFIX}/bin/pip${PYTHON_MAJOR}" "${PYTHON_PREFIX}/bin/pip"
echo "Đã tạo links trong ${PYTHON_PREFIX}/bin"

# Cấu hình shell
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" = "bash" ]; then SHELL_CONFIG_FILE="$HOME/.bashrc";
elif [ "$CURRENT_SHELL" = "zsh" ]; then SHELL_CONFIG_FILE="$HOME/.zshrc";
fi

NEW_PATH_STR="export PATH=\"${PYTHON_PREFIX}/bin:\$PATH\""
if [ -n "$SHELL_CONFIG_FILE" ]; then
    echo "Phát hiện shell: $CURRENT_SHELL. Cập nhật file: $SHELL_CONFIG_FILE"
    if ! grep -q "${PYTHON_PREFIX}/bin" "$SHELL_CONFIG_FILE"; then
        echo -e "\n# Thêm Python local vào PATH" >> "$SHELL_CONFIG_FILE"
        echo "$NEW_PATH_STR" >> "$SHELL_CONFIG_FILE"
        echo "Đã thêm đường dẫn vào $SHELL_CONFIG_FILE."
    else
        echo "Đường dẫn Python đã có trong $SHELL_CONFIG_FILE."
    fi
else
    echo "Không thể tự động phát hiện file cấu hình cho shell: $CURRENT_SHELL"
    echo "Vui lòng tự thêm dòng sau vào file cấu hình của bạn:"
    echo -e "\n  ${NEW_PATH_STR}\n"
fi
echo -e "${GREEN}==> Cấu hình môi trường thành công!${NC}"


# --- Hoàn tất ---
echo -e "\n\n${GREEN}**************************************************${NC}"
echo -e "${GREEN}  CÀI ĐẶT PYTHON ${PYTHON_VERSION} HOÀN TẤT! 🎉${NC}"
echo -e "${GREEN}**************************************************${NC}"
echo -e "\nVui lòng ${YELLOW}khởi động lại terminal${NC} hoặc chạy lệnh sau để cập nhật:"
echo -e "  ${YELLOW}source ${SHELL_CONFIG_FILE}${NC}"
echo -e "\nSau đó, kiểm tra phiên bản:"
echo -e "  ${YELLOW}python --version${NC}"
echo -e "  ${YELLOW}pip --version${NC}"
echo -e "  ${YELLOW}which python${NC} # Phải trỏ tới ${PYTHON_PREFIX}/bin/python"
