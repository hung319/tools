#!/bin/bash

# --- CẤU HÌNH ---
# Thư mục đích: Thư mục con riêng biệt để giữ cho .local gọn gàng
INSTALL_DIR="$HOME/.local/llvm-release"

# Chọn bản phát hành LLVM/Clang (Ví dụ: 17.0.6). Vui lòng kiểm tra lại URL/phiên bản.
LLVM_VERSION="17.0.6"

# Tên file tải xuống (phù hợp với Linux x86_64, Ubuntu 22.04 là một bản dựng phổ biến)
TAR_FILE="clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-22.04.tar.xz"
DOWNLOAD_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${TAR_FILE}"
# -----------------

echo "📂 Đang cài đặt libclang v${LLVM_VERSION} vào thư mục riêng biệt: ${INSTALL_DIR}"
echo "-------------------------------------"

# 1. Tải xuống và Giải nén
# Đảm bảo thư mục tồn tại
mkdir -p "${INSTALL_DIR}"

echo "   - Đang tải xuống ${TAR_FILE}..."
if command -v curl &> /dev/null; then
    curl -L -o "${TAR_FILE}" "${DOWNLOAD_URL}"
elif command -v wget &> /dev/null; then
    wget -O "${TAR_FILE}" "${DOWNLOAD_URL}"
else
    echo "⚠️ Lỗi: Không tìm thấy 'curl' hoặc 'wget'. Vui lòng cài đặt một trong hai."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi tải xuống. Vui lòng kiểm tra lại URL."
    exit 1
fi

echo "   - Đang giải nén..."
# Giải nén nội dung vào thư mục INSTALL_DIR
tar -xJf "${TAR_FILE}" --strip-components=1 -C "${INSTALL_DIR}"

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi giải nén."
    rm -f "${TAR_FILE}"
    exit 1
fi

# Dọn dẹp
rm -f "${TAR_FILE}"
echo "   - Cài đặt nhị phân hoàn tất."
echo "-------------------------------------"


# 2. Tự động Cập nhật Shell Config
# Xác định tệp cấu hình shell
if [ -f "$HOME/.zshrc" ]; then
    CONFIG_FILE="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -f "$HOME/.bashrc" ]; then
    CONFIG_FILE="$HOME/.bashrc"
    SHELL_NAME="bash"
else
    echo "⚠️ Không tìm thấy ~/.bashrc hoặc ~/.zshrc. Bạn sẽ phải cập nhật biến môi trường thủ công."
    exit 0
fi

echo "⚙️ Đang cập nhật tệp cấu hình shell: ${CONFIG_FILE} (${SHELL_NAME})"

# Các dòng cần thêm (sử dụng đường dẫn INSTALL_DIR mới)
EXPORT_PATH='export PATH="'"$INSTALL_DIR/bin"':$PATH"'
EXPORT_LIB='export LD_LIBRARY_PATH="'"$INSTALL_DIR/lib"':$LD_LIBRARY_PATH"'

# Hàm kiểm tra và thêm dòng vào file config
add_if_not_present() {
    local line_to_add="$1"
    local file="$2"
    local line_desc="$3"

    if grep -qF -- "$line_to_add" "$file"; then
        echo "   - Dòng ${line_desc} đã tồn tại."
    else
        echo "   - Thêm dòng ${line_desc} vào ${file}"
        echo "" >> "$file" # Thêm dòng trống cho dễ nhìn
        echo "# Cấu hình cho Clang/LLVM được cài đặt tại ${INSTALL_DIR}" >> "$file"
        echo "$line_to_add" >> "$file"
    fi
}

# Thêm biến PATH
add_if_not_present "$EXPORT_PATH" "$CONFIG_FILE" "PATH"

# Thêm biến LD_LIBRARY_PATH
add_if_not_present "$EXPORT_LIB" "$CONFIG_FILE" "LD_LIBRARY_PATH"

echo "-------------------------------------"
echo "✅ CÀI ĐẶT VÀ CẬP NHẬT HOÀN TẤT."
echo "❗️ LƯU Ý QUAN TRỌNG:"
echo "Biến môi trường đã được thêm vào ${CONFIG_FILE}, nhưng **chưa có hiệu lực** trong cửa sổ terminal hiện tại."
echo ""
echo "Vui lòng chạy lệnh sau để áp dụng ngay lập tức:"
echo "**source ${CONFIG_FILE}**"
echo ""
echo "Bạn có muốn tôi giúp bạn kiểm tra URL tải xuống LLVM mới nhất không?"
