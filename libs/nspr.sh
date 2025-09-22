#!/bin/bash

# Script để cài đặt thư viện NSPR (Netscape Portable Runtime) vào thư mục local
# mà không cần quyền root.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
NSPR_VERSION="4.35"
INSTALL_DIR="${HOME}/.local"
# --- KẾT THÚC CẤU HÌNH ---


# --- SCRIPT THỰC THI ---
echo " Bắt đầu quá trình cài đặt NSPR (Netscape Portable Runtime)..."

# 1. Kiểm tra các gói phụ thuộc cần thiết
echo " Kiểm tra các công cụ build (build-essential)..."
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo " LỖI: Thiếu các công cụ build cơ bản."
    echo " Vui lòng chạy lệnh sau với quyền sudo để cài đặt chúng:"
    echo " sudo apt update && sudo apt install -y build-essential wget"
    exit 1
fi
echo "✅ Các công cụ build cơ bản đã có."


# 2. Tải xuống và giải nén mã nguồn
NSPR_TARBALL="nspr-${NSPR_VERSION}.tar.gz"
NSPR_URL="https://archive.mozilla.org/pub/nspr/releases/v${NSPR_VERSION}/src/${NSPR_TARBALL}"
TEMP_DIR=$(mktemp -d)

echo " Tải xuống NSPR phiên bản ${NSPR_VERSION}..."
wget -q --show-progress -O "${TEMP_DIR}/${NSPR_TARBALL}" "${NSPR_URL}"

echo " Giải nén mã nguồn..."
tar -xzf "${TEMP_DIR}/${NSPR_TARBALL}" -C "${TEMP_DIR}"
# Lưu ý: Cần phải cd vào thư mục con 'nspr' bên trong
cd "${TEMP_DIR}/nspr-${NSPR_VERSION}/nspr"


# 3. Biên dịch và cài đặt
echo " Cấu hình NSPR cho hệ thống 64-bit..."
# --enable-64bit là quan trọng cho các hệ thống hiện đại
./configure --prefix="${INSTALL_DIR}" --enable-64bit --with-pthreads

echo " Biên dịch mã nguồn..."
make -j$(nproc)

echo " Cài đặt vào thư mục đích ${INSTALL_DIR}..."
make install


echo " Dọn dẹp file tạm..."
cd ~
rm -rf "${TEMP_DIR}"


# 4. Kiểm tra shell và cập nhật các biến môi trường
SHELL_CONFIG_FILE=""
if [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
elif [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    # Kiểm tra bằng một comment duy nhất để tránh thêm nhiều lần
    if ! grep -q "# --- NSPR Environment Variables ---" "$SHELL_CONFIG_FILE"; then
        echo " Thêm các biến môi trường cho NSPR vào ${SHELL_CONFIG_FILE}..."
        # Ghi một khối vào file config
        cat >> "$SHELL_CONFIG_FILE" <<'EOL'

# --- NSPR Environment Variables ---
# Cần thiết để các trình biên dịch và linker khác có thể tìm thấy NSPR
export PKG_CONFIG_PATH="${HOME}/.local/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH="${HOME}/.local/lib:${LD_LIBRARY_PATH}"
# Thêm /bin vào PATH cho các công cụ như nspr-config
export PATH="${HOME}/.local/bin:${PATH}"
EOL
        echo "✅ Đã thêm biến môi trường."
    else
        echo " Biến môi trường NSPR đã được cấu hình."
    fi
fi


# --- HOÀN TẤT ---
echo ""
echo "✅ HOÀN TẤT! Thư viện NSPR đã được cài đặt thành công."
echo " ========================================================================="
echo ""
echo " CÁC BƯỚC TIẾP THEO:"
echo ""
echo " 1. Tải lại cấu hình shell của bạn (rất quan trọng!):"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo ""
echo " 2. Kiểm tra phiên bản NSPR vừa cài đặt:"
echo "    nspr-config --version"
echo ""
echo " 3. Kiểm tra xem thư viện đã được cài đặt đúng chỗ chưa:"
echo "    ls -l ${INSTALL_DIR}/lib/libnspr4.so"
echo ""
echo " ➡️  Môi trường của bạn đã sẵn sàng để biên dịch các chương trình khác phụ thuộc vào NSPR."
echo " ========================================================================="
