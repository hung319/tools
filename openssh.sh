#!/bin/bash

# Script cài đặt OpenSSH Server vào thư mục local (~/.local)
# Phiên bản này tự động biên dịch dependencies và yêu cầu nhập key nếu chưa có.

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
SSH_PORT=2222
# Bạn có thể điền sẵn key vào đây, hoặc để mặc định để script hỏi khi chạy
PUBLIC_KEY_TO_ADD="ssh-rsa AAAA... user@client-machine"

ZLIB_VERSION="1.3.1"
OPENSSL_VERSION="3.3.1"
OPENSSH_VERSION="9.7p1"

INSTALL_DIR="${HOME}/.local"
SSH_USER=$(whoami)
# --- KẾT THÚC CẤU HÌNH ---


# --- SCRIPT THỰC THI ---

# <<< THAY ĐỔI Ở ĐÂY: Yêu cầu người dùng nhập key nếu chưa được cấu hình >>>
if [[ "${PUBLIC_KEY_TO_ADD}" == "ssh-rsa AAAA... user@client-machine" ]]; then
    echo "⚠️ Public key chưa được cấu hình sẵn trong script."
    # Lặp lại cho đến khi người dùng nhập một giá trị hợp lệ
    while true; do
        read -p "➡️ Vui lòng dán public key của bạn vào đây và nhấn Enter: " -r PUBLIC_KEY_TO_ADD
        if [[ -n "$PUBLIC_KEY_TO_ADD" ]]; then
            # Kiểm tra xem key có vẻ hợp lệ không (bắt đầu bằng 'ssh-' hoặc 'ecdsa-')
            if [[ "$PUBLIC_KEY_TO_ADD" == ssh-* || "$PUBLIC_KEY_TO_ADD" == ecdsa-* ]]; then
                break
            else
                echo "❌ Key không hợp lệ. Key phải bắt đầu bằng 'ssh-...' hoặc 'ecdsa-...'. Vui lòng thử lại."
                PUBLIC_KEY_TO_ADD="" # Reset biến để vòng lặp tiếp tục
            fi
        else
            echo "❌ Public key không được để trống. Vui lòng thử lại."
        fi
    done
fi

echo " Bắt đầu quá trình cài đặt OpenSSH và các thư viện phụ thuộc..."
echo " Thư mục cài đặt: ${INSTALL_DIR}"

# 1. Kiểm tra các công cụ build cơ bản
echo " Kiểm tra các công cụ build (build-essential, perl)..."
PACKAGES_NEEDED=()
command -v gcc >/dev/null 2>&1 || PACKAGES_NEEDED+=("build-essential")
command -v make >/dev/null 2>&1 || PACKAGES_NEEDED+=("build-essential")
command -v perl >/dev/null 2>&1 || PACKAGES_NEEDED+=("perl")

if [ ${#PACKAGES_NEEDED[@]} -ne 0 ]; then
    echo " LỖI: Thiếu các công cụ build cơ bản."
    echo " Vui lòng chạy lệnh sau với quyền sudo: sudo apt update && sudo apt install -y ${PACKAGES_NEEDED[@]} wget"
    exit 1
fi
echo "✅ Các công cụ build cơ bản đã có."

mkdir -p "${INSTALL_DIR}"
TEMP_DIR=$(mktemp -d)

# --- BUILD ZLIB ---
if [ -f "${INSTALL_DIR}/lib/libz.a" ]; then
    echo " Zlib đã được cài đặt. Bỏ qua..."
else
    echo "--- Bắt đầu build Zlib v${ZLIB_VERSION} ---"
    cd "${TEMP_DIR}"
    wget -q https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz
    tar -xzf zlib-${ZLIB_VERSION}.tar.gz
    cd zlib-${ZLIB_VERSION}
    ./configure --prefix="${INSTALL_DIR}"
    make -j$(nproc)
    make install
fi

# --- BUILD OPENSSL ---
if [ -f "${INSTALL_DIR}/bin/openssl" ]; then
    echo " OpenSSL đã được cài đặt. Bỏ qua..."
else
    echo "--- Bắt đầu build OpenSSL v${OPENSSL_VERSION} ---"
    cd "${TEMP_DIR}"
    wget -q https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}
    ./config --prefix="${INSTALL_DIR}" --openssldir="${INSTALL_DIR}"
    make -j$(nproc)
    make install_sw
fi

# --- BUILD OPENSSH ---
echo "--- Bắt đầu build OpenSSH v${OPENSSH_VERSION} ---"
cd "${TEMP_DIR}"
wget -q https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz
tar -xzf openssh-${OPENSSH_VERSION}.tar.gz
cd openssh-${OPENSSH_VERSION}

echo " Cấu hình OpenSSH để sử dụng thư viện local..."
./configure \
    --prefix="${INSTALL_DIR}" \
    --with-zlib="${INSTALL_DIR}" \
    --with-ssl-dir="${INSTALL_DIR}" \
    --with-privsep-path="${INSTALL_DIR}/var/empty" \
    --without-pam \
    --without-selinux

echo " Biên dịch và cài đặt OpenSSH..."
make -j$(nproc)
make install

echo " Dọn dẹp thư mục tạm..."
rm -rf "${TEMP_DIR}"

# --- CẤU HÌNH SAU KHI BUILD ---
SSHD_CONFIG_FILE="${INSTALL_DIR}/etc/sshd_config"
echo " Tạo file cấu hình sshd..."
cat > "${SSHD_CONFIG_FILE}" <<EOL
Port ${SSH_PORT}
PermitRootLogin no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
AllowUsers ${SSH_USER}
Subsystem sftp ${INSTALL_DIR}/libexec/sftp-server
HostKey ${INSTALL_DIR}/etc/ssh_host_rsa_key
HostKey ${INSTALL_DIR}/etc/ssh_host_ecdsa_key
HostKey ${INSTALL_DIR}/etc/ssh_host_ed25519_key
EOL

AUTHORIZED_KEYS_FILE="${HOME}/.ssh/authorized_keys"
echo " Cấu hình public key..."
mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "${AUTHORIZED_KEYS_FILE}"
chmod 600 "${AUTHORIZED_KEYS_FILE}"
if ! grep -qF -- "${PUBLIC_KEY_TO_ADD}" "${AUTHORIZED_KEYS_FILE}"; then
    echo "${PUBLIC_KEY_TO_ADD}" >> "${AUTHORIZED_KEYS_FILE}"
fi

SHELL_CONFIG_FILE=""
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" = "bash" ]; then SHELL_CONFIG_FILE="${HOME}/.bashrc"; fi
if [ "$CURRENT_SHELL" = "zsh" ]; then SHELL_CONFIG_FILE="${HOME}/.zshrc"; fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    EXPORT_PATH="export PATH=\"${INSTALL_DIR}/bin:${INSTALL_DIR}/sbin:\$PATH\""
    if ! grep -qF -- "$EXPORT_PATH" "$SHELL_CONFIG_FILE"; then
        echo " Thêm PATH vào ${SHELL_CONFIG_FILE}..."
        echo -e "\n# Add local OpenSSH to PATH\n${EXPORT_PATH}" >> "$SHELL_CONFIG_FILE"
    fi
fi

# --- HOÀN TẤT ---
echo -e "\n✅ HOÀN TẤT! OpenSSH và các thư viện phụ thuộc đã được cài đặt thành công."
echo " ========================================================================="
echo -e "\n CÁC BƯỚC TIẾP THEO:"
echo -e "\n 1. Tải lại cấu hình shell của bạn (quan trọng!):"
echo "    source ${SHELL_CONFIG_FILE:-~/.bashrc}"
echo -e "\n 2. Khởi động SSH server:"
echo "    ${INSTALL_DIR}/sbin/sshd"
echo -e "\n 3. Để kết nối đến server từ máy khách (client):"
echo "    ssh -i /path/to/private_key ${SSH_USER}@<server-ip-address> -p ${SSH_PORT}"
echo -e "\n 4. Để dừng server, tìm và kill tiến trình:"
echo "    ps aux | grep '${INSTALL_DIR}/sbin/sshd' | grep -v grep | awk '{print \$2}' | xargs kill 2>/dev/null || echo 'Server không đang chạy.'"
echo " ========================================================================="
