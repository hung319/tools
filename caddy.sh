#!/bin/bash

# Script tự động tải Caddy vào ~/src và cài đặt vào ~/.local/caddy

# --- Các biến cấu hình ---
SRC_DIR="$HOME/src"
INSTALL_DIR="$HOME/.local/caddy"
CADDY_DOWNLOAD_TARGET="$SRC_DIR/caddy"
CADDY_INSTALL_TARGET="$INSTALL_DIR/caddy"
CADDY_DOWNLOAD_API="https://caddyserver.com/api/download"

# --- Hàm thông báo ---
info() {
    echo "✅  $1"
}

warn() {
    echo "⚠️  $1"
}

# --- Bắt đầu thực thi ---
echo "Bắt đầu quá trình cài đặt Caddy cho người dùng cục bộ..."

# 1. Tạo các thư mục cần thiết
info "Đang tạo thư mục nguồn tại $SRC_DIR..."
mkdir -p "$SRC_DIR"
info "Đang tạo thư mục cài đặt tại $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# 2. Xác định kiến trúc hệ thống
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        CADDY_ARCH="amd64"
        ;;
    aarch64 | arm64)
        CADDY_ARCH="arm64"
        ;;
    armv7l)
        CADDY_ARCH="armv7"
        ;;
    *)
        warn "Không thể tự động xác định kiến trúc CPU ($ARCH). Đang thử tải bản amd64."
        CADDY_ARCH="amd64"
        ;;
esac
info "Kiến trúc CPU của bạn là: $CADDY_ARCH"

# 3. Tải Caddy vào ~/src
DOWNLOAD_URL="${CADDY_DOWNLOAD_API}?os=linux&arch=${CADDY_ARCH}"

info "Đang tải phiên bản Caddy mới nhất vào $CADDY_DOWNLOAD_TARGET..."
if curl -L "$DOWNLOAD_URL" -o "$CADDY_DOWNLOAD_TARGET"; then
    info "Tải Caddy thành công."
else
    warn "Tải Caddy thất bại. Vui lòng kiểm tra lại kết nối mạng hoặc URL."
    exit 1
fi

# Cấp quyền thực thi cho file nguồn
chmod +x "$CADDY_DOWNLOAD_TARGET"

# 4. Cài đặt bằng cách tạo symlink
info "Đang cài đặt Caddy bằng cách tạo symlink từ $CADDY_DOWNLOAD_TARGET đến $CADDY_INSTALL_TARGET..."
ln -sf "$CADDY_DOWNLOAD_TARGET" "$CADDY_INSTALL_TARGET"

# 5. Phát hiện shell và cập nhật PATH
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    warn "Không nhận diện được shell ($CURRENT_SHELL). Vui lòng tự thêm dòng sau vào file cấu hình shell của bạn:"
    echo "export PATH=\"\$HOME/.local/caddy:\$PATH\""
    exit 0
fi

info "Phát hiện shell: $CURRENT_SHELL. Sẽ kiểm tra file: $SHELL_CONFIG_FILE"

# 6. Kiểm tra và thêm PATH nếu cần
PATH_TO_ADD="export PATH=\"$INSTALL_DIR:\$PATH\""

if ! grep -q ".local/caddy" "$SHELL_CONFIG_FILE"; then
    info "Đang thêm Caddy vào PATH trong file $SHELL_CONFIG_FILE..."
    echo "" >> "$SHELL_CONFIG_FILE"
    echo "# Thêm Caddy vào PATH" >> "$SHELL_CONFIG_FILE"
    echo "$PATH_TO_ADD" >> "$SHELL_CONFIG_FILE"
    info "Đã thêm thành công."
else
    info "Đường dẫn Caddy đã tồn tại trong $SHELL_CONFIG_FILE. Bỏ qua."
fi

# --- Hoàn tất ---
echo ""
echo "🎉 Cài đặt Caddy hoàn tất! 🎉"
echo ""
echo "Để sử dụng lệnh 'caddy', hãy làm một trong hai việc sau:"
echo "1. Khởi động lại terminal của bạn."
echo "2. Hoặc chạy lệnh sau ngay bây giờ:"
echo "   source $SHELL_CONFIG_FILE"
echo ""
echo "Sau đó, bạn có thể kiểm tra bằng cách chạy: caddy version"
