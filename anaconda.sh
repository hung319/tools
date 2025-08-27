#!/bin-bash

# --- Cài đặt các biến ---
# Thay đổi thư mục cài đặt để không bị trùng với Miniconda
INSTALL_DIR="$HOME/.local/anaconda"
DOWNLOAD_DIR="$HOME/src"

# Dừng script ngay nếu có lỗi
set -e

# --- Bước 1: Dọn dẹp cài đặt cũ (nếu có) ---
echo "Kiểm tra và dọn dẹp thư mục cài đặt Anaconda cũ (nếu có) tại ${INSTALL_DIR}..."
rm -rf "${INSTALL_DIR}"

# --- Bước 2: Tạo thư mục download và di chuyển vào đó ---
echo "Đang tạo thư mục download ${DOWNLOAD_DIR}..."
mkdir -p "${DOWNLOAD_DIR}"
cd "${DOWNLOAD_DIR}"

# --- Bước 3: Tự động kiểm tra kiến trúc CPU ---
ARCH=$(uname -m)
echo "Kiến trúc CPU của bạn là: ${ARCH}"

case "$ARCH" in
    x86_64)
        # Tên file cài đặt cho Anaconda
        ANACONDA_FILE="Anaconda3-latest-Linux-x86_64.sh"
        ;;
    aarch64)
        ANACONDA_FILE="Anaconda3-latest-Linux-aarch64.sh"
        ;;
    *)
        echo "Lỗi: Kiến trúc CPU '${ARCH}' không được hỗ trợ."
        exit 1
        ;;
esac

# --- Bước 4: Tải xuống file cài đặt phù hợp ---
# URL tải của Anaconda khác với Miniconda
DOWNLOAD_URL="https://repo.anaconda.com/archive/${ANACONDA_FILE}"
echo "Đang tải xuống trình cài đặt Anaconda từ: ${DOWNLOAD_URL}"
echo "LƯU Ý: File cài đặt Anaconda rất lớn (vài GB), quá trình này có thể mất nhiều thời gian."
wget --quiet --show-progress -O "${ANACONDA_FILE}" "${DOWNLOAD_URL}"

# --- Bước 5: Cài đặt Anaconda một cách tự động ---
echo "Đang cài đặt Anaconda vào ${INSTALL_DIR}..."
bash "${ANACONDA_FILE}" -b -p "${INSTALL_DIR}"

# --- Bước 6: Dọn dẹp file cài đặt ---
echo "Đang dọn dẹp file cài đặt..."
rm "${ANACONDA_FILE}"

# --- Bước 7: Tự động phát hiện Shell và khởi tạo Conda ---
CONDA_EXEC="${INSTALL_DIR}/bin/conda"
SHELL_NAME=$(basename "$SHELL")
echo "Shell hiện tại của bạn là: ${SHELL_NAME}"

if [ -f "$CONDA_EXEC" ]; then
    echo "Đang khởi tạo Conda cho shell '${SHELL_NAME}'..."
    # Lệnh init sẽ tự động cấu hình file .bashrc, .zshrc, ...
    "$CONDA_EXEC" init "${SHELL_NAME}"
else
    echo "Lỗi: Không tìm thấy file thực thi của Conda tại ${CONDA_EXEC}."
    exit 1
fi

# --- Hoàn tất ---
echo ""
echo "✅ Cài đặt Anaconda hoàn tất!"
echo "Vui lòng KHỞI ĐỘNG LẠI TERMINAL để các thay đổi có hiệu lực."
