#!/bin/bash

# Dừng script ngay lập tức nếu có bất kỳ lệnh nào thất bại
set -e

# --- CÁC BIẾN CẤU HÌNH (CÓ THỂ THAY ĐỔI) ---
NGINX_VERSION="1.26.1"
OPENSSL_VERSION="3.3.1"
BROTLI_VERSION="1.1.0"
HEADERS_MORE_VERSION="0.37"

# --- THƯ MỤC CÀI ĐẶT (KHÔNG NÊN THAY ĐỔI) ---
INSTALL_DIR="${HOME}/.local/nginx"
SOURCE_DIR="${HOME}/src"

# --- BẮT ĐẦU SCRIPT ---

echo "🚀 Bắt đầu quá trình biên dịch và cài đặt Nginx tùy chỉnh..."
echo "    - Thư mục cài đặt: ${INSTALL_DIR}"
echo "    - Thư mục mã nguồn (tạm thời): ${SOURCE_DIR}"

# 1. Chuẩn bị thư mục
echo "➡️ Bước 1/6: Chuẩn bị thư mục..."
mkdir -p ${SOURCE_DIR}
mkdir -p ${INSTALL_DIR}
cd ${SOURCE_DIR}

# 2. Tải tất cả mã nguồn cần thiết
echo "➡️ Bước 2/6: Tải các mã nguồn..."

# Tải Nginx
if [ ! -f "nginx-${NGINX_VERSION}.tar.gz" ]; then
    echo "   - Tải Nginx ${NGINX_VERSION}..."
    wget -q --show-progress http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
fi

# Tải OpenSSL (cần cho HTTP/3)
if [ ! -f "openssl-${OPENSSL_VERSION}.tar.gz" ]; then
    echo "   - Tải OpenSSL ${OPENSSL_VERSION}..."
    wget -q --show-progress https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
fi

# Tải Headers More
if [ ! -f "headers-more-${HEADERS_MORE_VERSION}.tar.gz" ]; then
    echo "   - Tải Headers More ${HEADERS_MORE_VERSION}..."
    wget -q --show-progress -O headers-more-${HEADERS_MORE_VERSION}.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v${HEADERS_MORE_VERSION}.tar.gz
fi

# Tải Brotli (sử dụng git để bao gồm submodule)
if [ ! -d "ngx_brotli" ]; then
    echo "   - Tải Brotli (sử dụng git clone)..."
    git clone --quiet https://github.com/google/ngx_brotli.git
    cd ngx_brotli
    git checkout --quiet v${BROTLI_VERSION}
    git submodule update --init --quiet
    cd ..
fi

# 3. Giải nén các file đã tải
echo "➡️ Bước 3/6: Giải nén mã nguồn..."
tar -xzf nginx-${NGINX_VERSION}.tar.gz
tar -xzf openssl-${OPENSSL_VERSION}.tar.gz
tar -xzf headers-more-${HEADERS_MORE_VERSION}.tar.gz

# 4. Biên dịch Nginx với các module tùy chọn
echo "➡️ Bước 4/6: Biên dịch Nginx (bước này có thể mất vài phút)..."
cd nginx-${NGINX_VERSION}

./configure \
    --prefix=${INSTALL_DIR} \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-openssl=../openssl-${OPENSSL_VERSION} \
    --without-http_gzip_module \
    --add-module=../ngx_brotli \
    --add-module=../headers-more-nginx-module-${HEADERS_MORE_VERSION}

make -j48
make install

# 5. Dọn dẹp thư mục mã nguồn
echo "➡️ Bước 5/6: Dọn dẹp các file tạm thời..."
cd ~
rm -rf ${SOURCE_DIR}

# 6. Tự động cấu hình biến môi trường PATH
echo "➡️ Bước 6/6: Cấu hình biến môi trường Shell..."
SHELL_CONFIG_FILE=""
if [ -n "$ZSH_VERSION" ]; then
   SHELL_CONFIG_FILE="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
   SHELL_CONFIG_FILE="$HOME/.bashrc"
else
   echo "⚠️ Không thể tự động xác định shell. Vui lòng thêm dòng sau vào file cấu hình shell của bạn:"
   echo "export PATH=${INSTALL_DIR}/sbin:\$PATH"
fi

if [ -n "$SHELL_CONFIG_FILE" ]; then
    if ! grep -q "${INSTALL_DIR}/sbin" "$SHELL_CONFIG_FILE"; then
        echo "   - Thêm đường dẫn Nginx vào ${SHELL_CONFIG_FILE}"
        echo '' >> ${SHELL_CONFIG_FILE}
        echo '# Nginx Local Installation' >> ${SHELL_CONFIG_FILE}
        echo "export PATH=${INSTALL_DIR}/sbin:\$PATH" >> ${SHELL_CONFIG_FILE}
        echo "✅ Hoàn tất! Vui lòng chạy lệnh sau hoặc mở lại terminal để sử dụng Nginx:"
        echo "source ${SHELL_CONFIG_FILE}"
    else
        echo "   - Đường dẫn Nginx đã tồn tại trong ${SHELL_CONFIG_FILE}. Không cần thêm."
    fi
fi

echo "🎉 CÀI ĐẶT THÀNH CÔNG! 🎉"
echo "Kiểm tra phiên bản và các module với lệnh: nginx -V"
