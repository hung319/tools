#!/bin/bash

# Script để cài đặt Info-ZIP vào thư mục local (~/.local)
# mà không cần quyền root.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
ZIP_VERSION="3.0"
INSTALL_DIR="${HOME}/.local"
# --- KẾT THÚC CẤU HÌNH ---


# --- SCRIPT THỰC THI ---
echo " Bắt đầu quá trình cài đặt Info-ZIP (zip) vào thư mục local..."

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
ZIP_TARBALL="zip${ZIP_VERSION//.}.tar.gz" # Chuyển 3.0 thành 30
ZIP_URL="https://downloads.sourceforge.net/project/infozip/Zip%203.x%20%28latest%29/${ZIP_VERSION}/${ZIP_TARBALL}"
TEMP_DIR=$(mktemp -d)

echo " Tải xuống Zip phiên bản ${ZIP_VERSION}..."
#wget -q -O "${TEMP_DIR}/${ZIP_TARBALL}" "${ZIP_URL}" # URL của SourceForge đôi khi không ổn định
# Dùng link dự phòng nếu link trên lỗi
wget -q -O "${TEMP_DIR}/${ZIP_TARBALL}" "https://versaweb.dl.sourceforge.net/project/infozip/Zip%203.x%20(latest)/3.0/zip30.tar.gz"


echo " Giải nén mã nguồn..."
tar -xzf "${TEMP_DIR}/${ZIP_TARBALL}" -C "${TEMP_DIR}"
cd "${TEMP_DIR}/zip${ZIP_VERSION//.}"


# 3. Biên dịch và cài đặt
# Info-ZIP không dùng ./configure, mà dùng Makefile trực tiếp
echo " Biên dịch mã nguồn..."
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
echo "✅ HOÀN TẤT! Info-ZIP đã được cài đặt thành công."
echo " ========================================================================="
echo ""
echo " CÁC BƯỚC TIẾP THEO:"
echo ""
echo " 1. Tải lại cấu hình shell của bạn để nhận lệnh 'zip' mới:"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo ""
echo " 2. Kiểm tra xem lệnh zip đã đúng chưa:"
echo "    which zip"
echo "    (Kết quả phải là '${INSTALL_DIR}/bin/zip')"
echo ""
echo " 3. Sử dụng lệnh zip:"
echo "    zip my_archive.zip file1.txt file2.txt"
echo ""
echo " ========================================================================="
