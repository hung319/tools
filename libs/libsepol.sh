#!/bin/bash
# Script để build libsepol từ source (sử dụng phương pháp Staging Install)

set -e

# --- Các biến ---
LIBSEPOL_VERSION="3.6"
SOURCE_DIR="$HOME/src"
INSTALL_PREFIX="$HOME/.local"

# --- Bắt đầu ---
echo "--- 🔍 Kiểm tra các công cụ build ---"
if ! command -v gcc &> /dev/null || ! command -v make &> /dev/null; then
    echo "❌ Lỗi: Vui lòng cài đặt 'build-essential'."
    exit 1
fi

echo "--- 🧱 Chuẩn bị môi trường cho libsepol ---"
mkdir -p "$SOURCE_DIR" "$INSTALL_PREFIX/lib" "$INSTALL_PREFIX/include"
cd "$SOURCE_DIR"

echo "--- 🌐 Tải và giải nén libsepol $LIBSEPOL_VERSION ---"
if [ ! -f "libsepol-$LIBSEPOL_VERSION.tar.gz" ]; then
    wget "https://github.com/SELinuxProject/selinux/releases/download/$LIBSEPOL_VERSION/libsepol-$LIBSEPOL_VERSION.tar.gz"
fi
rm -rf "libsepol-$LIBSEPOL_VERSION"
tar -xf "libsepol-$LIBSEPOL_VERSION.tar.gz"
cd "libsepol-$LIBSEPOL_VERSION"

echo "--- ⚙️  Biên dịch mã nguồn ---"
make -j$(nproc)

# ==============================================================================
# SỬA LỖI TRIỆT ĐỂ: Dùng Staging Install
# ==============================================================================
echo "--- 🚀 Cài đặt vào thư mục tạm (staging) ---"
# Tạo một thư mục tạm an toàn
STAGE_DIR=$(mktemp -d)

# Cho phép make cài đặt vào thư mục tạm này.
# Nó sẽ tạo các thư mục con như /lib, /usr/lib bên trong STAGE_DIR.
make install DESTDIR="$STAGE_DIR" PREFIX="/usr" LIBDIR="/lib"

echo "--- 🚚 Sao chép file từ thư mục tạm vào ~/.local ---"

# Sao chép các thư viện (.a, .so) từ các vị trí có thể vào ~/.local/lib
if [ -d "$STAGE_DIR/lib/" ]; then
    echo "Sao chép từ $STAGE_DIR/lib/..."
    cp -av "$STAGE_DIR/lib/"* "$INSTALL_PREFIX/lib/"
fi
if [ -d "$STAGE_DIR/usr/lib/" ]; then
    echo "Sao chép từ $STAGE_DIR/usr/lib/..."
    cp -av "$STAGE_DIR/usr/lib/"* "$INSTALL_PREFIX/lib/"
fi

# Sao chép các file header (.h) vào ~/.local/include
if [ -d "$STAGE_DIR/usr/include/" ]; then
    echo "Sao chép từ $STAGE_DIR/usr/include/..."
    cp -av "$STAGE_DIR/usr/include/"* "$INSTALL_PREFIX/include/"
fi

# Dọn dẹp thư mục tạm
echo "--- 🧹 Dọn dẹp thư mục tạm ---"
rm -rf "$STAGE_DIR"

echo ""
echo "✅ Cài đặt libsepol $LIBSEPOL_VERSION thành công bằng phương pháp Staging Install!"
