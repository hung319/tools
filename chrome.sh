#!/bin/bash

#================================================================
# Script cài đặt Google Chrome vào $HOME/.local cho người dùng không có quyền root.
# Tác giả: Gemini
# Ngày: 19/08/2025
#================================================================

# --- Cấu hình màu sắc cho output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Thiết lập các biến và thư mục cần thiết ---
SRC_DIR="$HOME/src"
INSTALL_DIR="$HOME/.local"
BIN_DIR="$INSTALL_DIR/bin"
SHARE_DIR="$INSTALL_DIR/share"
TEMP_DIR=$(mktemp -d) # Tạo thư mục tạm để giải nén

# --- Hàm dọn dẹp khi kết thúc hoặc có lỗi ---
cleanup() {
    echo -e "${YELLOW}Dọn dẹp thư mục tạm...${NC}"
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# --- Bắt đầu quá trình cài đặt ---
echo -e "${BLUE}Bắt đầu quá trình cài đặt Google Chrome (no-root)...${NC}"

# 1. Tạo các thư mục cần thiết nếu chưa tồn tại
echo -e "\n${GREEN}1. Kiểm tra và tạo các thư mục cần thiết...${NC}"
mkdir -p "$SRC_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$SHARE_DIR"/{applications,icons}
echo "   - Các thư mục đã sẵn sàng."

# 2. Tải về file .deb của Google Chrome
echo -e "\n${GREEN}2. Tải về Google Chrome stable phiên bản mới nhất...${NC}"
CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
CHROME_DEB_PATH="$SRC_DIR/google-chrome-stable_current_amd64.deb"

if wget -O "$CHROME_DEB_PATH" "$CHROME_DEB_URL"; then
    echo "   - Tải về thành công!"
else
    echo -e "${YELLOW}Lỗi: Không thể tải về file cài đặt. Vui lòng kiểm tra kết nối mạng.${NC}"
    exit 1
fi

# 3. Giải nén file .deb
echo -e "\n${GREEN}3. Giải nén file .deb mà không cần quyền root...${NC}"
cd "$TEMP_DIR"
ar x "$CHROME_DEB_PATH"
tar -xf data.tar.xz
echo "   - Giải nén thành công."

# 4. Di chuyển các file đã giải nén vào thư mục cài đặt
echo -e "\n${GREEN}4. Di chuyển các file của Chrome vào $INSTALL_DIR...${NC}"
# Di chuyển toàn bộ thư mục opt/google/chrome
mv "$TEMP_DIR/opt/google/chrome" "$SHARE_DIR/chrome"

# Tạo một symbolic link cho file thực thi
ln -sf "$SHARE_DIR/chrome/chrome" "$BIN_DIR/google-chrome-stable"

# Di chuyển các file .desktop và icons
mv "$TEMP_DIR/usr/share/applications/google-chrome.desktop" "$SHARE_DIR/applications/"
# Sửa lại đường dẫn trong file .desktop để trỏ đến đúng nơi
sed -i "s|/usr/bin/google-chrome-stable|$BIN_DIR/google-chrome-stable|g" "$SHARE_DIR/applications/google-chrome.desktop"
sed -i "s|/opt/google/chrome/|$SHARE_DIR/chrome/|g" "$SHARE_DIR/applications/google-chrome.desktop"

# Di chuyển các icon
cp -r "$TEMP_DIR/usr/share/icons/hicolor"/* "$SHARE_DIR/icons/"

echo "   - Di chuyển file hoàn tất."

# 5. Cập nhật môi trường (PATH)
echo -e "\n${GREEN}5. Cấu hình biến môi trường...${NC}"
SHELL_CONFIG_FILE=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.profile" ]; then
    SHELL_CONFIG_FILE="$HOME/.profile"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG_FILE"; then
        echo -e '\n# Thêm thư mục bin của người dùng vào PATH\nexport PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG_FILE"
        echo "   - Đã thêm '$HOME/.local/bin' vào PATH trong file $SHELL_CONFIG_FILE."
        echo -e "   - ${YELLOW}Vui lòng chạy 'source $SHELL_CONFIG_FILE' hoặc mở lại terminal để áp dụng thay đổi.${NC}"
    else
        echo "   - '$HOME/.local/bin' đã tồn tại trong PATH."
    fi
else
    echo -e "${YELLOW}   - Không tìm thấy file .bashrc, .zshrc hoặc .profile. Vui lòng tự thêm dòng sau vào file cấu hình shell của bạn:${NC}"
    echo -e '     export PATH="$HOME/.local/bin:$PATH"'
fi

echo -e "\n${BLUE}Hoàn tất! Google Chrome đã được cài đặt.${NC}"
echo "Bạn có thể khởi động bằng cách gõ lệnh: ${GREEN}google-chrome-stable${NC}"
echo "Hoặc tìm trong menu ứng dụng của bạn."
