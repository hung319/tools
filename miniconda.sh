#!/bin/bash

# --- Cài đặt các biến ---
INSTALL_DIR="$HOME/.local/miniconda"
DOWNLOAD_DIR="$HOME/src"

# Dừng script ngay nếu có lỗi
set -e

# --- Bước 1: Dọn dẹp cài đặt cũ (nếu có) ---
echo "Kiểm tra và dọn dẹp thư mục cài đặt cũ (nếu có) tại ${INSTALL_DIR}..."
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
        MINICONDA_FILE="Miniconda3-latest-Linux-x86_64.sh"
        ;;
    aarch64)
        MINICONDA_FILE="Miniconda3-latest-Linux-aarch64.sh"
        ;;
    *)
        echo "Lỗi: Kiến trúc CPU '${ARCH}' không được hỗ trợ."
        exit 1
        ;;
esac

# --- Bước 4: Tải xuống file cài đặt phù hợp ---
DOWNLOAD_URL="https://repo.anaconda.com/miniconda/${MINICONDA_FILE}"
echo "Đang tải xuống trình cài đặt từ: ${DOWNLOAD_URL}"
wget --quiet --show-progress -O "${MINICONDA_FILE}" "${DOWNLOAD_URL}"

# --- Bước 5: Cài đặt Miniconda một cách tự động ---
echo "Đang cài đặt Miniconda vào ${INSTALL_DIR}..."
bash "${MINICONDA_FILE}" -b -p "${INSTALL_DIR}"

# --- Bước 6: Dọn dẹp file cài đặt ---
echo "Đang dọn dẹp file cài đặt..."
rm "${MINICONDA_FILE}"

# --- Bước 7: Tự động phát hiện Shell và khởi tạo Conda ---
CONDA_EXEC="${INSTALL_DIR}/bin/conda"
SHELL_NAME=$(basename "$SHELL")
echo "Shell hiện tại của bạn là: ${SHELL_NAME}"

if [ -f "$CONDA_EXEC" ]; then
    echo "Đang khởi tạo Conda cho shell '${SHELL_NAME}'..."
    "$CONDA_EXEC" init "${SHELL_NAME}"
else
    echo "Lỗi: Không tìm thấy file thực thi của Conda tại ${CONDA_EXEC}."
    exit 1
fi

# --- Hoàn tất ---
echo ""
echo "✅ Cài đặt Miniconda hoàn tất!"
echo "Vui lòng KHỞI ĐỘNG LẠI TERMINAL để các thay đổi có hiệu lực."
