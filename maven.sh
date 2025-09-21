#!/bin/bash

# Script để cài đặt Apache Maven vào thư mục local mà không cần quyền root.
# Yêu cầu: Java Development Kit (JDK) phải được cài đặt sẵn.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
# Bạn có thể thay đổi phiên bản Maven nếu muốn.
MAVEN_VERSION="3.9.8"
# Nơi cài đặt các ứng dụng tùy chọn.
INSTALL_OPTS_DIR="${HOME}/.local/opt"
# --- KẾT THÚC CẤU HÌNH ---


# --- SCRIPT THỰC THI ---
echo " Bắt đầu quá trình cài đặt Apache Maven..."

# 1. Kiểm tra Java Development Kit (JDK)
echo " Kiểm tra sự tồn tại của JDK (lệnh javac)..."
if ! command -v javac &> /dev/null; then
    echo " LỖI: Không tìm thấy Java Development Kit (JDK)."
    echo " Maven yêu cầu JDK để hoạt động."
    echo " Vui lòng chạy lệnh sau với quyền sudo để cài đặt JDK:"
    echo " sudo apt update && sudo apt install default-jdk"
    exit 1
fi
JAVA_VERSION=$(javac -version 2>&1)
echo "✅ Đã tìm thấy JDK: $JAVA_VERSION"


# 2. Tải xuống và giải nén Maven
MAVEN_TARBALL="apache-maven-${MAVEN_VERSION}-bin.tar.gz"
MAVEN_URL="https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/${MAVEN_TARBALL}"
INSTALL_DIR="${INSTALL_OPTS_DIR}/apache-maven-${MAVEN_VERSION}"
SYMLINK_PATH="${INSTALL_OPTS_DIR}/apache-maven"

# Kiểm tra nếu đã cài đặt rồi thì bỏ qua
if [ -d "$INSTALL_DIR" ]; then
    echo " Maven phiên bản ${MAVEN_VERSION} đã được cài đặt tại ${INSTALL_DIR}. Bỏ qua..."
else
    TEMP_DIR=$(mktemp -d)
    echo " Tải xuống Maven phiên bản ${MAVEN_VERSION}..."
    wget -q --show-progress -O "${TEMP_DIR}/${MAVEN_TARBALL}" "${MAVEN_URL}"

    echo " Giải nén vào ${INSTALL_OPTS_DIR}..."
    mkdir -p "${INSTALL_OPTS_DIR}"
    tar -xzf "${TEMP_DIR}/${MAVEN_TARBALL}" -C "${INSTALL_OPTS_DIR}"
    echo " Dọn dẹp file tạm..."
    rm -rf "${TEMP_DIR}"
fi

# 3. Tạo symbolic link để dễ quản lý phiên bản
echo " Tạo symbolic link: ${SYMLINK_PATH} -> ${INSTALL_DIR}"
# ln -sfn: force, no-dereference, symbolic link
ln -sfn "${INSTALL_DIR}" "${SYMLINK_PATH}"


# 4. Kiểm tra shell và cập nhật PATH, M2_HOME
SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" = "bash" ]; then
    SHELL_CONFIG_FILE="${HOME}/.bashrc"
elif [ "$CURRENT_SHELL" = "zsh" ]; then
    SHELL_CONFIG_FILE="${HOME}/.zshrc"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    # Chỉ thêm vào nếu M2_HOME chưa được định nghĩa
    if ! grep -q "export M2_HOME" "$SHELL_CONFIG_FILE"; then
        echo " Thêm biến môi trường M2_HOME và PATH vào ${SHELL_CONFIG_FILE}..."
        # Ghi một khối vào file config
        cat >> "$SHELL_CONFIG_FILE" <<'EOL'

# --- Apache Maven Environment Variables ---
export M2_HOME="${HOME}/.local/opt/apache-maven"
export PATH="${M2_HOME}/bin:${PATH}"
EOL
        echo "✅ Đã thêm biến môi trường."
    else
        echo " Biến môi trường Maven đã được cấu hình."
    fi
fi


# --- HOÀN TẤT ---
echo ""
echo "✅ HOÀN TẤT! Apache Maven đã được cài đặt thành công."
echo " ========================================================================="
echo ""
echo " CÁC BƯỚC TIẾP THEO:"
echo ""
echo " 1. Tải lại cấu hình shell của bạn (rất quan trọng!):"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo ""
echo " 2. Kiểm tra phiên bản maven vừa cài đặt:"
echo "    mvn -version"
echo ""
echo "    Bạn sẽ thấy thông tin về phiên bản Apache Maven, Java và hệ điều hành."
echo ""
echo " ========================================================================="
