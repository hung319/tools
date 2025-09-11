#!/usr/bin/env bash
set -e

# Thư mục cài đặt
PREFIX="$HOME/nginx"

# Tạo thư mục tạm
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Phiên bản nginx muốn cài
NGINX_VERSION=1.26.2

echo "Tải Nginx $NGINX_VERSION..."
curl -L "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz

tar xzf nginx.tar.gz
cd nginx-${NGINX_VERSION}

echo "Biên dịch Nginx..."
./configure \
  --prefix="$PREFIX" \
  --with-http_ssl_module \
  --without-http_rewrite_module \
  --without-http_gzip_module

make -j"$(nproc)"
make install

echo "Đã cài Nginx vào $PREFIX"
echo "Chạy thử: $PREFIX/sbin/nginx -v"

# Gợi ý PATH
echo 'export PATH="$HOME/nginx/sbin:$PATH"' >> "$HOME/.bashrc"
echo "Đã thêm Nginx vào PATH. Đăng nhập lại shell để dùng lệnh nginx."
