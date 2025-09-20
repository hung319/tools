#!/bin/bash

# Script cài đặt GNU Nano vào thư mục local (~/.local)
# Phiên bản này tự động biên dịch và cài đặt thư viện phụ thuộc ncurses.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
# Phiên bản của các thành phần.
NCURSES_VERSION="6.5"
NANO_VERSION="8.1"

# Thư mục cài đặt chung.
INSTALL_DIR="${HOME}/.local"
# --- KẾT THÚC CẤU HÌNH ---

# --- SCRIPT THỰC THI ---
echo " Bắt đầu quá trình cài đặt GNU Nano và các thư viện phụ thuộc..."
echo " Thư mục cài đặt: ${INSTALL_DIR}"

# 1. Kiểm tra các công cụ build cơ bản
echo " Kiểm tra các công cụ build (gcc, make)..."
PACKAGES_NEEDED=()
command -v gcc >/dev/null 2>&1 || PACKAGES_NEEDED+=("build-essential")
command -v make >/dev/null 2>&1 || PACKAGES_NEEDED+=("build-essential")

if [ ${#PACKAGES_NEEDED[@]} -ne 0 ]; then
    echo " LỖI: Thiếu các công cụ build cơ bản."
    echo " Vui lòng chạy lệnh sau với quyền sudo để cài đặt chúng:"
    echo " sudo apt update && sudo apt install -y build-essential wget"
    exit 1
fi
echo "✅ Các công cụ build cơ bản đã có."

# Tạo các thư mục cần thiết
mkdir -p "${INSTALL_DIR}"
TEMP_DIR=$(mktemp -d)

# --- BUILD NCURSES ---
# Kiểm tra xem thư viện đã tồn tại chưa để không build lại
if [ -f "${INSTALL_DIR}/lib/libncursesw.a" ]; then
    echo " Thư viện Ncurses đã được cài đặt tại ${INSTALL_DIR}. Bỏ qua..."
else
    echo "--- Bắt đầu build Ncurses v${NCURSES_VERSION} (cần thiết cho Nano) ---"
    cd "${TEMP_DIR}"
    wget -q https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz
    tar -xzf ncurses-${NCURSES_VERSION}.tar.gz
    cd ncurses-${NCURSES_VERSION}
    # Cấu hình để hỗ trợ ký tự Unicode (wide-character)
    ./configure --prefix="${INSTALL_DIR}" --with-shared --enable-widec --without-debug --enable-pc-files --with-pkg-config-libdir="${INSTALL_DIR}/lib/pkgconfig"
    make -j$(nproc)
    make install
    echo "--- Build Ncurses hoàn tất ---"
fi

# --- BUILD NANO ---
echo "--- Bắt đầu build Nano v${NANO_VERSION} ---"

# Thiết lập các biến môi trường để configure của Nano tìm thấy ncurses vừa build
export LDFLAGS="-L${INSTALL_DIR}/lib"
export CPPFLAGS="-I${INSTALL_DIR}/include"
export PKG_CONFIG_PATH="${INSTALL_DIR}/lib/pkgconfig"

cd "${TEMP_DIR}"
NANO_MAJOR_VERSION=$(echo "$NANO_VERSION" | cut -d. -f1)
wget -q https://www.nano-editor.org/dist/v${NANO_MAJOR_VERSION}/nano-${NANO_VERSION}.tar.xz
tar -xJf nano-${NANO_VERSION}.tar.xz
cd nano-${NANO_VERSION}

echo " Cấu hình Nano để sử dụng Ncurses tại ${INSTALL_DIR}..."
./configure --prefix="${INSTALL_DIR}" --enable-utf8

echo " Biên dịch và cài đặt Nano..."
make -j$(nproc)
make install
echo "--- Build Nano hoàn tất ---"

# Hủy các biến môi trường để không ảnh hưởng đến session shell của người dùng
unset LDFLAGS CPPFLAGS PKG_CONFIG_PATH

# Dọn dẹp
echo " Dọn dẹp thư mục tạm..."
rm -rf "${TEMP_DIR}"

# --- CẤU HÌNH SAU KHI BUILD ---
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    EXPORT_PATH="export PATH=\"${INSTALL_DIR}/bin:\$PATH\""
    if ! grep -qF -- "$EXPORT_PATH" "$SHELL_CONFIG_FILE"; then
        echo " Thêm biến môi trường PATH vào ${SHELL_CONFIG_FILE}..."
        echo -e "\n# Thêm các chương trình cài đặt local vào PATH\n${EXPORT_PATH}" >> "$SHELL_CONFIG_FILE"
    fi
fi

# --- HOÀN TẤT ---
echo -e "\n✅ HOÀN TẤT! GNU Nano và thư viện ncurses đã được cài đặt thành công."
echo " ========================================================================="
echo -e "\n CÁC BƯỚC TIẾP THEO:"
echo -e "\n 1. Tải lại cấu hình shell của bạn (quan trọng!):"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo -e "\n 2. Kiểm tra phiên bản nano vừa cài đặt:"
echo "    nano --version"
echo -e "\n 3. Kiểm tra đường dẫn của nano:"
echo "    which nano"
echo "    (Kết quả phải là '${INSTALL_DIR}/bin/nano')"
echo " ========================================================================="
