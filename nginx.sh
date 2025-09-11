#!/usr/bin/env bash
set -e

# Thư mục cài đặt
PREFIX="$HOME/nginx"

# Phiên bản Nginx
NGINX_VERSION=1.26.2

# Thư mục tạm
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "Tải Nginx $NGINX_VERSION..."
curl -L "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz
tar xzf nginx.tar.gz
cd nginx-${NGINX_VERSION}

echo "Biên dịch Nginx với gzip..."
./configure \
  --prefix="$PREFIX" \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-http_v2_module

make -j"$(nproc)"
make install

echo "Đã cài Nginx vào $PREFIX"
echo "Chạy thử: $PREFIX/sbin/nginx -v"

# Thêm vào PATH
if ! grep -q 'nginx/sbin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/nginx/sbin:$PATH"' >> "$HOME/.bashrc"
fi
echo "Đã thêm Nginx vào PATH. Đăng nhập lại shell để dùng lệnh nginx."
