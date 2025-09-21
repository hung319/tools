#!/bin/bash

# Script để cài đặt Info-ZIP (unzip) vào thư mục local (~/.local)
# mà không cần quyền root.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
UNZIP_VERSION="6.0"
INSTALL_DIR="${HOME}/.local"
# --- KẾT THÚC CẤU HÌNH ---


# --- SCRIPT THỰC THI ---
echo " Bắt đầu quá trình cài đặt Info-ZIP (unzip) vào thư mục local..."

# 1. Kiểm tra các gói phụ thuộc cần thiết
echo " Kiểm tra các công cụ build (build-essential)..."
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


# 2. Tải xuống và giải nén mã nguồn
UNZIP_TARBALL="unzip${UNZIP_VERSION//.}.tar.gz" # Chuyển 6.0 thành 60
UNZIP_URL="https://downloads.sourceforge.net/project/infozip/UnZip%206.x%20%28latest%29/UnZip%206.0/${UNZIP_TARBALL}"
TEMP_DIR=$(mktemp -d)

echo " Tải xuống UnZip phiên bản ${UNZIP_VERSION}..."
wget -q -O "${TEMP_DIR}/${UNZIP_TARBALL}" "${UNZIP_URL}"


echo " Giải nén mã nguồn..."
tar -xzf "${TEMP_DIR}/${UNZIP_TARBALL}" -C "${TEMP_DIR}"
cd "${TEMP_DIR}/unzip${UNZIP_VERSION//.}"


# 3. Biên dịch và cài đặt
# Info-ZIP không dùng ./configure, mà dùng Makefile trực tiếp
echo " Biên dịch mã nguồn..."
# Sử dụng target 'generic' cho khả năng tương thích cao
make -f unix/Makefile generic

echo " Cài đặt vào thư mục đích ${INSTALL_DIR}..."
# Biến 'prefix' được định nghĩa trong Makefile để chỉ định thư mục cài đặt
make -f unix/Makefile install prefix="${INSTALL_DIR}"


echo " Dọn dẹp file tạm..."
cd ~
rm -rf "${TEMP_DIR}"


# 4. Kiểm tra shell và cập nhật PATH
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    EXPORT_PATH="export PATH=\"${INSTALL_DIR}/bin:\$PATH\""
    # Chỉ thêm vào nếu dòng đó chưa tồn tại
    if ! grep -qF -- "$EXPORT_PATH" "$SHELL_CONFIG_FILE"; then
        echo " Thêm biến môi trường PATH vào ${SHELL_CONFIG_FILE}..."
        echo "" >> "$SHELL_CONFIG_FILE"
        echo "# Thêm các chương trình cài đặt local vào PATH" >> "$SHELL_CONFIG_FILE"
        echo "$EXPORT_PATH" >> "$SHELL_CONFIG_FILE"
    else
        echo " Biến môi trường PATH đã được cấu hình."
    fi
fi


# --- HOÀN TẤT ---
echo ""
echo "✅ HOÀN TẤT! Info-ZIP (unzip) đã được cài đặt thành công."
echo " ========================================================================="
echo ""
echo " CÁC BƯỚC TIẾP THEO:"
echo ""
echo " 1. Tải lại cấu hình shell của bạn để nhận lệnh 'unzip' mới:"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo ""
echo " 2. Kiểm tra xem lệnh unzip đã đúng chưa:"
echo "    which unzip"
echo "    (Kết quả phải là '${INSTALL_DIR}/bin/unzip')"
echo ""
echo " 3. Xem thông tin phiên bản:"
echo "    unzip -v"
echo ""
echo " ========================================================================="
