#!/bin/bash

# --- CẤU HÌNH ---
# Thư mục đích: $HOME/.local/llvm-release
INSTALL_DIR="$HOME/.local/llvm-release"

# Chọn bản phát hành LLVM/Clang (Ví dụ: 17.0.6)
# Bạn nên kiểm tra trang tải xuống LLVM/Clang để tìm phiên bản mới nhất và phù hợp.
LLVM_VERSION="17.0.6"

# Tên file tải xuống (thường là gói dành cho Linux x86_64)
# Kiểm tra URL cụ thể trên trang tải xuống LLVM/Clang.
# Ví dụ: https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz
TAR_FILE="clang+llvm-${LLVM_VERSION}-x86_64-linux-gnu-ubuntu-22.04.tar.xz"
DOWNLOAD_URL="https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/${TAR_FILE}"
# -----------------

echo "🚀 Bắt đầu cài đặt libclang v${LLVM_VERSION} vào ${INSTALL_DIR}"

# 1. Tạo thư mục cài đặt nếu nó chưa tồn tại
mkdir -p "${INSTALL_DIR}"
echo "   - Đã tạo thư mục: ${INSTALL_DIR}"

# 2. Tải xuống gói nhị phân
echo "   - Đang tải xuống ${TAR_FILE}..."
# Sử dụng curl hoặc wget (cần có sẵn trên hệ thống)
if command -v curl &> /dev/null
then
    curl -L -o "${TAR_FILE}" "${DOWNLOAD_URL}"
elif command -v wget &> /dev/null
then
    wget -O "${TAR_FILE}" "${DOWNLOAD_URL}"
else
    echo "⚠️ Lỗi: Không tìm thấy 'curl' hoặc 'wget'. Vui lòng cài đặt một trong hai hoặc tải thủ công."
    exit 1
fi

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi tải xuống. Vui lòng kiểm tra lại URL: ${DOWNLOAD_URL}"
    exit 1
fi
echo "   - Tải xuống thành công."

# 3. Giải nén vào thư mục cài đặt
echo "   - Đang giải nén..."
# LLVM thường được đóng gói dưới dạng .tar.xz
tar -xJf "${TAR_FILE}" --strip-components=1 -C "${INSTALL_DIR}"

if [ $? -ne 0 ]; then
    echo "❌ Lỗi khi giải nén. Vui lòng kiểm tra file đã tải xuống."
    # Dọn dẹp file đã tải xuống
    rm -f "${TAR_FILE}"
    exit 1
fi
echo "   - Giải nén thành công!"

# 4. Dọn dẹp file tar đã tải
rm -f "${TAR_FILE}"
echo "   - Đã xóa file tạm: ${TAR_FILE}"

# 5. Cập nhật biến môi trường (PATH và LD_LIBRARY_PATH)
echo ""
echo "✅ CÀI ĐẶT HOÀN TẤT."
echo "Để sử dụng libclang và các công cụ khác, bạn cần cập nhật biến môi trường."
echo "Thêm các dòng sau vào tệp cấu hình shell của bạn (ví dụ: ~/.bashrc hoặc ~/.zshrc):"
echo ""
echo 'export PATH="'"${INSTALL_DIR}/bin"':$PATH"'
echo 'export LD_LIBRARY_PATH="'"${INSTALL_DIR}/lib"':$LD_LIBRARY_PATH"'
echo ""
echo "Sau đó, chạy lệnh: source ~/.bashrc (hoặc ~/.zshrc) để áp dụng."
echo ""
echo "Kiểm tra phiên bản clang:"
echo "${INSTALL_DIR}/bin/clang --version"
