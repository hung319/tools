#!/bin/bash

# Script cài đặt ChromeDriver phiên bản Stable mới nhất.
# Phiên bản 1.2: Sử dụng endpoint đơn giản và đáng tin cậy hơn để lấy phiên bản.
# Tác giả: Gemini

set -e # Thoát ngay khi có lỗi

# --- Cấu hình ---
DOWNLOAD_DIR="${HOME}/src"
INSTALL_DIR="${HOME}/.local/bin"

# --- Bắt đầu Script ---
echo "🚀 Bắt đầu cài đặt ChromeDriver (phiên bản Stable)..."
echo "--------------------------------------------------------"

# 1. Tự động phát hiện kiến trúc CPU
echo "🔍 Đang phát hiện kiến trúc hệ thống..."
ARCH=$(uname -m)
case "$ARCH" in
    x86_64 | aarch64)
        PLATFORM="linux64"
        echo "✅ Hệ thống là ${ARCH}. Sử dụng platform '${PLATFORM}'."
        ;;
    *)
        echo "❌ Lỗi: Kiến trúc '${ARCH}' không được hỗ trợ."
        exit 1
        ;;
esac

# 2. Tạo các thư mục cần thiết
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$INSTALL_DIR"

# 3. Lấy số phiên bản Stable mới nhất (Cách mới, đáng tin cậy)
echo "🔍 Đang tìm phiên bản ChromeDriver Stable mới nhất..."
STABLE_VERSION_URL="https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE"
VERSION=$(curl -s "$STABLE_VERSION_URL")

if [ -z "$VERSION" ]; then
    echo "❌ Lỗi: Không thể lấy được thông tin phiên bản Stable mới nhất."
    exit 1
fi
echo "✅ Tìm thấy phiên bản mới nhất: ${VERSION}"

# 4. Xây dựng URL tải về và tiến hành tải
DOWNLOAD_URL="https://storage.googleapis.com/chrome-for-testing-public/${VERSION}/${PLATFORM}/chromedriver-${PLATFORM}.zip"
ZIP_FILE="${DOWNLOAD_DIR}/chromedriver-${PLATFORM}-${VERSION}.zip"

echo "⏳ Đang tải ChromeDriver v${VERSION}..."
wget -q --show-progress -O "$ZIP_FILE" "$DOWNLOAD_URL"

# 5. Giải nén và cài đặt
echo "📦 Đang giải nén và cài đặt vào ${INSTALL_DIR}..."
EXTRACT_DIR=$(mktemp -d)
unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR" > /dev/null
mv -f "${EXTRACT_DIR}/chromedriver-${PLATFORM}/chromedriver" "${INSTALL_DIR}/chromedriver"
chmod +x "${INSTALL_DIR}/chromedriver"

# Dọn dẹp
rm "$ZIP_FILE"
rm -r "$EXTRACT_DIR"
echo "🧹 Đã dọn dẹp các file tạm."

# 6. Tự động cấu hình PATH (nếu cần)
# ... (Phần này giữ nguyên và không có lỗi) ...
echo "💡 Đang kiểm tra và cấu hình biến môi trường PATH..."
CURRENT_SHELL=$(basename "$SHELL")
CONFIG_FILE=""
if [ "$CURRENT_SHELL" = "bash" ]; then CONFIG_FILE="${HOME}/.bashrc"; fi
if [ "$CURRENT_SHELL" = "zsh" ]; then CONFIG_FILE="${HOME}/.zshrc"; fi

if [ -n "$CONFIG_FILE" ]; then
    PATH_STRING="export PATH=\"\$HOME/.local/bin:\$PATH\""
    if ! grep -qF -- "$PATH_STRING" "$CONFIG_FILE"; then
        echo "   Thêm '${INSTALL_DIR}' vào PATH trong file ${CONFIG_FILE}..."
        echo "" >> "$CONFIG_FILE"
        echo "# Thêm thư mục bin cục bộ vào PATH" >> "$CONFIG_FILE"
        echo "$PATH_STRING" >> "$CONFIG_FILE"
        echo "   Đã cập nhật PATH. Vui lòng chạy 'source ${CONFIG_FILE}' hoặc mở lại terminal."
    else
        echo "✅ Biến PATH đã được cấu hình từ trước."
    fi
fi

# 7. Hoàn tất
echo ""
echo "--------------------------------------------------------"
echo "🎉 Cài đặt ChromeDriver v${VERSION} thành công! 🎉"
echo ""
echo "   Để kiểm tra, hãy mở terminal mới và chạy lệnh:"
echo "   chromedriver --version"
echo "--------------------------------------------------------"

exit 0
