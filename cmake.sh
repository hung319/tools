#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Cấu hình ---
# Bạn có thể thay đổi phiên bản CMake tại đây
# Truy cập https://cmake.org/download/ để xem phiên bản mới nhất
CMAKE_VERSION="3.30.1" 
# -----------------

# Nơi cài đặt (chuẩn FHS cho user-space)
INSTALL_PREFIX="$HOME/.local"

# Tự động xác định kiến trúc hệ thống
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
    CMAKE_ARCH="aarch64"
elif [[ "$ARCH" == "x86_64" ]]; then
    CMAKE_ARCH="x86_64"
else
    echo "Lỗi: Kiến trúc '$ARCH' không được hỗ trợ bởi script này."
    exit 1
fi

# Tạo thư mục tạm để làm việc, script sẽ tự xoá khi kết thúc
WORK_DIR=$(mktemp -d)
trap 'echo "Đang dọn dẹp thư mục tạm..."; rm -rf "$WORK_DIR"' EXIT

# Trích xuất phiên bản chính và phụ (ví dụ: 3.30 từ 3.30.1)
CMAKE_MAJOR_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f1,2)
CMAKE_PACKAGE_NAME="cmake-${CMAKE_VERSION}-linux-${CMAKE_ARCH}"
DOWNLOAD_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_PACKAGE_NAME}.tar.gz"

echo "=========================================================="
echo "Cài đặt CMake phiên bản: ${CMAKE_VERSION} (dùng cp)"
echo "Kiến trúc hệ thống:     ${ARCH}"
echo "Thư mục cài đặt:        ${INSTALL_PREFIX}"
echo "URL tải về:             ${DOWNLOAD_URL}"
echo "=========================================================="

# Tạo thư mục cài đặt nếu chưa có
mkdir -p "$INSTALL_PREFIX"

cd "$WORK_DIR"

echo ""
echo "⏳ Đang tải CMake..."
wget -q --show-progress -O cmake.tar.gz "${DOWNLOAD_URL}"

echo ""
echo "📦 Đang giải nén..."
tar -zxf cmake.tar.gz

echo ""
echo "🚀 Đang cài đặt vào ${INSTALL_PREFIX}..."
# Sử dụng 'cp -a' (archive) để sao chép đệ quy, giữ nguyên thuộc tính file.
# Đây là phương án thay thế cho rsync, có sẵn trên mọi hệ thống.
# Dấu '.' ở cuối source path đảm bảo sao chép nội dung bên trong thư mục.
cp -a "${CMAKE_PACKAGE_NAME}/." "${INSTALL_PREFIX}/"

echo ""
echo "🔧 Cấu hình môi trường (PATH)..."

# Kiểm tra xem ~/.local/bin đã có trong PATH chưa
# và thêm vào file cấu hình shell phù hợp nếu cần
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [[ "$CURRENT_SHELL" == "bash" ]]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
elif [[ "$CURRENT_SHELL" == "zsh" ]]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
else
    # Fallback cho các shell khác (sh, dash, etc.)
    SHELL_CONFIG_FILE="$HOME/.profile"
fi

EXPORT_PATH_CMD='export PATH="$HOME/.local/bin:$PATH"'

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_CONFIG_FILE"; then
    echo "Thêm '$HOME/.local/bin' vào PATH trong file $SHELL_CONFIG_FILE"
    echo "" >> "$SHELL_CONFIG_FILE"
    echo "# Add local binaries to PATH" >> "$SHELL_CONFIG_FILE"
    echo "$EXPORT_PATH_CMD" >> "$SHELL_CONFIG_FILE"
    echo "Cấu hình PATH đã được thêm. Vui lòng chạy lệnh sau hoặc mở lại terminal:"
    echo "  source ${SHELL_CONFIG_FILE}"
else
    echo "Cấu hình PATH đã tồn tại. Không cần thay đổi."
fi

echo ""
echo "✅ Cài đặt CMake thành công!"
echo "Phiên bản vừa cài đặt:"
# Trỏ trực tiếp đến binary vừa cài để xác nhận
"${INSTALL_PREFIX}/bin/cmake" --version
echo "=========================================================="
