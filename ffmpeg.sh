#!/bin/bash

# --- CẤU HÌNH ---
INSTALL_DIR="$HOME/.local/bin"
BUSYBOX_URL="https://github.com/hung319/tools/raw/refs/heads/non-root/busybox"
FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
TMP_DIR="ffmpeg_install_tmp"

echo "--- Bắt đầu cài đặt FFmpeg (Fix Permission Denied) ---"

# 1. Hàm tải file
download_file() {
    local url=$1
    local dest=$2
    echo " -> Đang tải: $dest"
    if command -v curl >/dev/null 2>&1; then
        curl -L --retry 3 --connect-timeout 60 -C - -o "$dest" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -c -t 3 -O "$dest" "$url"
    else
        echo "Lỗi: Không tìm thấy curl/wget."
        exit 1
    fi
}

# 2. Chuẩn bị
mkdir -p "$INSTALL_DIR"
mkdir -p "$TMP_DIR"

# 3. Tải công cụ
echo "[1/4] Tải BusyBox..."
download_file "$BUSYBOX_URL" "$TMP_DIR/busybox"
chmod +x "$TMP_DIR/busybox"

echo "[2/4] Tải FFmpeg Archive..."
download_file "$FFMPEG_URL" "$TMP_DIR/ffmpeg.tar.xz"

# 4. Trích xuất trực tiếp (Bypass giải nén thư mục)
echo "[3/4] Đang trích xuất (Bỏ qua lỗi permission)..."

# Bước 4a: Liệt kê file bên trong để tìm đúng đường dẫn
# Chúng ta cần tìm đường dẫn kiểu: ffmpeg-*-static/ffmpeg
echo " -> Đang đọc cấu trúc file..."
FFMPEG_INTERNAL_PATH=$("$TMP_DIR/busybox" tar -tf "$TMP_DIR/ffmpeg.tar.xz" | grep "/ffmpeg$" | head -n 1)
FFPROBE_INTERNAL_PATH=$("$TMP_DIR/busybox" tar -tf "$TMP_DIR/ffmpeg.tar.xz" | grep "/ffprobe$" | head -n 1)

if [ -z "$FFMPEG_INTERNAL_PATH" ]; then
    echo "LỖI: Không đọc được file nén. File tải về có thể bị lỗi."
    rm -rf "$TMP_DIR"
    exit 1
fi

echo " -> Tìm thấy: $FFMPEG_INTERNAL_PATH"

# Bước 4b: Giải nén thẳng ra file đích (Dùng flag -O để in ra stdout và ghi vào file)
# Cách này giúp bỏ qua việc tạo thư mục cha gây lỗi permission
echo " -> Đang ghi file ffmpeg..."
"$TMP_DIR/busybox" tar -xOf "$TMP_DIR/ffmpeg.tar.xz" "$FFMPEG_INTERNAL_PATH" > "$INSTALL_DIR/ffmpeg"

echo " -> Đang ghi file ffprobe..."
"$TMP_DIR/busybox" tar -xOf "$TMP_DIR/ffmpeg.tar.xz" "$FFPROBE_INTERNAL_PATH" > "$INSTALL_DIR/ffprobe"

# 5. Cấp quyền chạy
chmod +x "$INSTALL_DIR/ffmpeg"
chmod +x "$INSTALL_DIR/ffprobe"

# 6. Dọn dẹp
rm -rf "$TMP_DIR"

# 7. Cấu hình PATH (Giữ nguyên logic cũ)
echo "--- Cấu hình Shell ---"
CURRENT_SHELL=$(basename "$SHELL")
SHELL_CONFIG=""
case "$CURRENT_SHELL" in
    zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
    bash) SHELL_CONFIG="$HOME/.bashrc" ;;
    *) SHELL_CONFIG="$HOME/.profile" ;;
esac

# Tạo file nếu chưa có để tránh lỗi
touch "$SHELL_CONFIG"

if grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_CONFIG"; then
    echo " -> PATH đã tồn tại."
else
    echo " -> Thêm PATH vào $SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
fi

echo "--- HOÀN TẤT ---"
echo "Chạy lệnh sau để hoàn thành:"
echo "source $SHELL_CONFIG"
echo "ffmpeg -version"
