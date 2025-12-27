#!/bin/bash

# --- CẤU HÌNH ---
INSTALL_DIR="$HOME/.local/bin"
# Tạo thư mục tạm ngay tại thư mục Home của user
TMP_DIR="$HOME/ffmpeg_tmp_install_$(date +%s)"

echo "--- Bắt đầu cài đặt FFmpeg (Auto Arch - Safe Temp) ---"

# 1. Tự động kiểm tra kiến trúc CPU (Arch Detection)
ARCH=$(uname -m)
echo " -> Phát hiện kiến trúc hệ thống: $ARCH"

case "$ARCH" in
    x86_64)
        FF_ARCH="amd64"
        # Busybox cho Intel/AMD 64bit
        BUSYBOX_URL="https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64"
        ;;
    aarch64)
        FF_ARCH="arm64"
        # Busybox cho ARM 64bit (Raspberry Pi 4, Oracle Cloud ARM...)
        BUSYBOX_URL="https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-armv8l"
        ;;
    *)
        echo "LỖI: Kiến trúc $ARCH chưa được script này hỗ trợ tự động."
        exit 1
        ;;
esac

FFMPEG_URL="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-${FF_ARCH}-static.tar.xz"
echo " -> Đã chọn phiên bản: $FF_ARCH"

# 2. Hàm tải file thông minh
download_file() {
    local url=$1
    local dest=$2
    echo " -> Đang tải: $dest"
    
    # Kiểm tra xem file đã tồn tại và có dung lượng > 0 chưa (Hỗ trợ resume thủ công)
    if [ -s "$dest" ]; then
        echo "    (File đã tồn tại, sẽ thử tải tiếp...)"
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -L --retry 3 --connect-timeout 60 -C - -o "$dest" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -c -t 3 -O "$dest" "$url"
    else
        echo "Lỗi: Cần có 'curl' hoặc 'wget'."
        exit 1
    fi
    
    # Verify file tải về
    if [ ! -s "$dest" ]; then
        echo "Lỗi: File tải về bị rỗng ($dest)."
        rm -f "$dest"
        exit 1
    fi
}

# 3. Chuẩn bị thư mục
echo "[1/5] Tạo thư mục làm việc..."
# Đảm bảo thư mục bin tồn tại
mkdir -p "$INSTALL_DIR"
# Tạo thư mục tạm tại Home
mkdir -p "$TMP_DIR"
echo " -> Thư mục tạm: $TMP_DIR"

# 4. Tải công cụ giải nén (BusyBox)
echo "[2/5] Đang tải BusyBox ($ARCH)..."
download_file "$BUSYBOX_URL" "$TMP_DIR/busybox"
chmod +x "$TMP_DIR/busybox"

# Test thử BusyBox
if ! "$TMP_DIR/busybox" true >/dev/null 2>&1; then
    echo "LỖI: BusyBox tải về không chạy được trên kiến trúc này."
    exit 1
fi

# 5. Tải FFmpeg
echo "[3/5] Đang tải FFmpeg Static ($FF_ARCH)..."
download_file "$FFMPEG_URL" "$TMP_DIR/ffmpeg.tar.xz"

# 6. Trích xuất (Bypass Permission)
echo "[4/5] Đang trích xuất file..."

# Lấy đường dẫn nội bộ trong file nén
# (Vì tên folder bên trong thay đổi theo version nên phải grep tìm)
FFMPEG_INTERNAL=$("$TMP_DIR/busybox" tar -tf "$TMP_DIR/ffmpeg.tar.xz" | grep "/ffmpeg$" | head -n 1)
FFPROBE_INTERNAL=$("$TMP_DIR/busybox" tar -tf "$TMP_DIR/ffmpeg.tar.xz" | grep "/ffprobe$" | head -n 1)

if [ -z "$FFMPEG_INTERNAL" ]; then
    echo "LỖI: Không đọc được cấu trúc file nén."
    exit 1
fi

echo " -> Tìm thấy: $FFMPEG_INTERNAL"

# Giải nén thẳng luồng dữ liệu ra file đích (Không tạo folder)
"$TMP_DIR/busybox" tar -xOf "$TMP_DIR/ffmpeg.tar.xz" "$FFMPEG_INTERNAL" > "$INSTALL_DIR/ffmpeg"
"$TMP_DIR/busybox" tar -xOf "$TMP_DIR/ffmpeg.tar.xz" "$FFPROBE_INTERNAL" > "$INSTALL_DIR/ffprobe"

chmod +x "$INSTALL_DIR/ffmpeg"
chmod +x "$INSTALL_DIR/ffprobe"

# 7. Dọn dẹp
echo " -> Đang dọn dẹp thư mục tạm..."
rm -rf "$TMP_DIR"

# 8. Cấu hình PATH
echo "[5/5] Cấu hình biến môi trường..."
CURRENT_SHELL=$(basename "$SHELL")
SHELL_CONFIG=""

case "$CURRENT_SHELL" in
    zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
    bash) SHELL_CONFIG="$HOME/.bashrc" ;;
    *) SHELL_CONFIG="$HOME/.profile" ;; # Fallback cho sh, ash
esac

touch "$SHELL_CONFIG"

if grep -q "export PATH=\"$INSTALL_DIR:\$PATH\"" "$SHELL_CONFIG"; then
    echo " -> PATH đã được cấu hình trước đó."
else
    echo " -> Thêm $INSTALL_DIR vào $SHELL_CONFIG"
    echo "" >> "$SHELL_CONFIG"
    echo "# FFmpeg User Install" >> "$SHELL_CONFIG"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
fi

echo "--- THÀNH CÔNG RỰC RỠ ---"
echo "Chạy lệnh sau để hoàn tất:"
echo "source $SHELL_CONFIG"
echo "ffmpeg -version"
