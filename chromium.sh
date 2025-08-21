#!/bin/bash

# Script cài đặt Chromium thông minh, tự động phát hiện kiến trúc và cấu hình shell.
# Phiên bản 1.3: Tải file vào ~/src
# Tác giả: Gemini

set -e # Thoát ngay khi có lỗi

# --- Cấu hình ---
# Thư mục tải file về
DOWNLOAD_DIR="${HOME}/src"
# Thư mục cài đặt ứng dụng
INSTALL_DIR="${HOME}/.local/share/chromium"
# Thư mục chứa các file thực thi của người dùng
BIN_DIR="${HOME}/.local/bin"

# --- Bắt đầu Script ---
echo "🚀 Bắt đầu cài đặt Chromium..."
echo "--------------------------------------------------------"

# 1. Tự động phát hiện kiến trúc CPU (Arch)
echo "🔍 Đang phát hiện kiến trúc hệ thống..."
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        ARCH_DIR="Linux_x64"
        echo "✅ Hệ thống là x86_64 (64-bit Intel/AMD)."
        ;;
    aarch64)
        ARCH_DIR="Linux_ARM64"
        echo "✅ Hệ thống là aarch64 (ARM 64-bit)."
        ;;
    *)
        echo "❌ Lỗi: Kiến trúc '${ARCH}' không được hỗ trợ bởi script này."
        exit 1
        ;;
esac

# 2. Tạo các thư mục cần thiết
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# 3. Tìm mã phiên bản mới nhất cho kiến trúc phù hợp
echo "🔍 Đang tìm phiên bản Chromium mới nhất cho ${ARCH}..."
LAST_CHANGE_URL="https://storage.googleapis.com/chromium-browser-snapshots/${ARCH_DIR}/LAST_CHANGE"
BUILD_NUMBER=$(curl -s "$LAST_CHANGE_URL")

if [ -z "$BUILD_NUMBER" ]; then
    echo "❌ Lỗi: Không thể lấy được mã phiên bản mới nhất. Vui lòng kiểm tra kết nối mạng."
    exit 1
fi
echo "✅ Tìm thấy phiên bản mới nhất: ${BUILD_NUMBER}"

# 4. Tải Chromium về
ZIP_FILE="${DOWNLOAD_DIR}/chrome-linux-${ARCH}.zip"
DOWNLOAD_URL="https://storage.googleapis.com/chromium-browser-snapshots/${ARCH_DIR}/${BUILD_NUMBER}/chrome-linux.zip"

echo "⏳ Đang tải Chromium (phiên bản ${BUILD_NUMBER}) về thư mục ${DOWNLOAD_DIR}..."
wget -q --show-progress -O "$ZIP_FILE" "$DOWNLOAD_URL"

# 5. Giải nén file đã tải
echo "📦 Đang giải nén vào ${INSTALL_DIR}..."
rm -rf "${INSTALL_DIR}/chrome-linux" # Xóa cài đặt cũ nếu có
unzip -o "$ZIP_FILE" -d "$INSTALL_DIR"
rm "$ZIP_FILE" # Dọn dẹp file zip
echo "🧹 Đã dọn dẹp file .zip."

# 6. Tạo script khởi chạy
LAUNCHER_PATH="${BIN_DIR}/chromium"
CHROME_EXECUTABLE="${INSTALL_DIR}/chrome-linux/chrome"

echo "🚀 Tạo lối tắt khởi chạy tại: ${LAUNCHER_PATH}"
cat <<EOF > "$LAUNCHER_PATH"
#!/bin/bash
# Script khởi chạy Chromium được cài đặt tại ${INSTALL_DIR}
exec "${CHROME_EXECUTABLE}" "\$@"
EOF
chmod +x "$LAUNCHER_PATH"

# 7. Tự động cấu hình PATH cho shell
echo "💡 Đang kiểm tra và cấu hình biến môi trường PATH..."
CURRENT_SHELL=$(basename "$SHELL")
CONFIG_FILE=""
PATH_CONFIGURED=false

if [ "$CURRENT_SHELL" = "bash" ]; then
    CONFIG_FILE="${HOME}/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    CONFIG_FILE="${HOME}/.zshrc"
fi

PATH_STRING="export PATH=\"\$HOME/.local/bin:\$PATH\""

if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    if ! grep -qF -- "$PATH_STRING" "$CONFIG_FILE"; then
        echo "   Thêm '${BIN_DIR}' vào PATH trong file ${CONFIG_FILE}..."
        echo "" >> "$CONFIG_FILE"
        echo "# Thêm thư mục bin cục bộ vào PATH để chạy các ứng dụng như Chromium" >> "$CONFIG_FILE"
        echo "$PATH_STRING" >> "$CONFIG_FILE"
        PATH_CONFIGURED=true
    else
        echo "✅ Biến PATH trong ${CONFIG_FILE} đã được cấu hình từ trước."
    fi
else
    echo "⚠️ Không tìm thấy file cấu hình cho shell '${CURRENT_SHELL}'. Bạn cần tự thêm PATH."
fi

# 8. Hoàn tất và hướng dẫn
echo ""
echo "--------------------------------------------------------"
echo "🎉 Cài đặt Chromium thành công! 🎉"
echo ""
echo "   Đã cài đặt tại:  ${INSTALL_DIR}"
echo "   Lối tắt tại:     ${LAUNCHER_PATH}"
echo ""

if [ "$PATH_CONFIGURED" = true ]; then
    echo "   Đã tự động cập nhật file cấu hình shell của bạn."
    echo "   Vui lòng KHỞI ĐỘNG LẠI TERMINAL hoặc chạy lệnh sau để áp dụng thay đổi:"
    echo "   source ${CONFIG_FILE}"
else
    echo "   Bây giờ bạn có thể mở terminal và gõ lệnh sau để chạy:"
    echo "   chromium"
fi
echo "--------------------------------------------------------"

exit 0
