#!/bin/bash

# Script cài đặt trình duyệt Chrome Stable và ChromeDriver tương ứng.
# Đảm bảo cả hai luôn khớp phiên bản với nhau.
# Tác giả: Gemini
# Phiên bản: 2.0

set -e # Thoát ngay khi có lỗi

# --- Cấu hình ---
DOWNLOAD_DIR="${HOME}/src"
CHROME_INSTALL_DIR="${HOME}/.local/share/chrome-stable"
BIN_DIR="${HOME}/.local/bin"

# --- Bắt đầu Script ---
echo "🚀 Bắt đầu cài đặt bộ đôi Chrome Stable + ChromeDriver..."
echo "--------------------------------------------------------"

# 1. Phát hiện kiến trúc
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
mkdir -p "$CHROME_INSTALL_DIR"
mkdir -p "$BIN_DIR"

# 3. Lấy số phiên bản Stable mới nhất (chỉ làm một lần)
echo "🔍 Đang tìm phiên bản Stable mới nhất..."
STABLE_VERSION_URL="https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_STABLE"
VERSION=$(curl -s "$STABLE_VERSION_URL")

if [ -z "$VERSION" ]; then
    echo "❌ Lỗi: Không thể lấy được thông tin phiên bản Stable."
    exit 1
fi
echo "✅ Tìm thấy phiên bản Stable chung: ${VERSION}"

# 4. Tải và cài đặt trình duyệt Chrome Stable
echo ""
echo "--- Cài đặt trình duyệt Chrome v${VERSION} ---"
CHROME_URL="https://storage.googleapis.com/chrome-for-testing-public/${VERSION}/${PLATFORM}/chrome-${PLATFORM}.zip"
CHROME_ZIP="${DOWNLOAD_DIR}/chrome-stable-${VERSION}.zip"
echo "⏳ Đang tải Chrome..."
wget -q --show-progress -O "$CHROME_ZIP" "$CHROME_URL"
echo "📦 Đang giải nén Chrome..."
unzip -o "$CHROME_ZIP" -d "$CHROME_INSTALL_DIR" > /dev/null
rm "$CHROME_ZIP"
echo "✅ Cài đặt Chrome Stable thành công vào: ${CHROME_INSTALL_DIR}"

# 5. Tải và cài đặt ChromeDriver tương ứng
echo ""
echo "--- Cài đặt ChromeDriver v${VERSION} ---"
DRIVER_URL="https://storage.googleapis.com/chrome-for-testing-public/${VERSION}/${PLATFORM}/chromedriver-${PLATFORM}.zip"
DRIVER_ZIP="${DOWNLOAD_DIR}/chromedriver-stable-${VERSION}.zip"
echo "⏳ Đang tải ChromeDriver..."
wget -q --show-progress -O "$DRIVER_ZIP" "$DRIVER_URL"
echo "📦 Đang giải nén và cài đặt ChromeDriver..."
EXTRACT_DIR=$(mktemp -d)
unzip -o "$DRIVER_ZIP" -d "$EXTRACT_DIR" > /dev/null
mv -f "${EXTRACT_DIR}/chromedriver-${PLATFORM}/chromedriver" "${BIN_DIR}/chromedriver"
chmod +x "${BIN_DIR}/chromedriver"
rm "$DRIVER_ZIP"
rm -r "$EXTRACT_DIR"
echo "✅ Cài đặt ChromeDriver thành công vào: ${BIN_DIR}"

# 6. Tạo lối tắt (launcher) cho Chrome Stable
LAUNCHER_PATH="${BIN_DIR}/chrome-stable"
CHROME_EXECUTABLE="${CHROME_INSTALL_DIR}/chrome-${PLATFORM}/chrome"
echo ""
echo "🚀 Tạo lối tắt khởi chạy cho trình duyệt tại: ${LAUNCHER_PATH}"
cat <<EOF > "$LAUNCHER_PATH"
#!/bin/bash
exec "${CHROME_EXECUTABLE}" "\$@"
EOF
chmod +x "$LAUNCHER_PATH"

# 7. Cấu hình PATH (nếu cần)
# Giữ nguyên phần này để đảm bảo các lệnh được nhận diện
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo "💡 Cấu hình PATH cho shell..."
    CURRENT_SHELL=$(basename "$SHELL")
    CONFIG_FILE=""
    if [ "$CURRENT_SHELL" = "bash" ]; then CONFIG_FILE="${HOME}/.bashrc"; fi
    if [ "$CURRENT_SHELL" = "zsh" ]; then CONFIG_FILE="${HOME}/.zshrc"; fi
    if [ -n "$CONFIG_FILE" ]; then
        PATH_STRING="export PATH=\"\$HOME/.local/bin:\$PATH\""
        if ! grep -qF -- "$PATH_STRING" "$CONFIG_FILE"; then
            echo "   Thêm '${BIN_DIR}' vào PATH trong file ${CONFIG_FILE}..."
            echo "" >> "$CONFIG_FILE"; echo "$PATH_STRING" >> "$CONFIG_FILE"
        fi
    fi
fi

# 8. Hoàn tất
echo ""
echo "--------------------------------------------------------"
echo "🎉 Cài đặt bộ đôi Chrome và ChromeDriver thành công! 🎉"
echo ""
echo "   Phiên bản chung: ${VERSION}"
echo "   Để chạy trình duyệt, gõ: chrome-stable"
echo "   Để kiểm tra driver, gõ:  chromedriver --version"
echo ""
echo "   Vui lòng mở lại terminal để các lệnh có hiệu lực."
echo "--------------------------------------------------------"
