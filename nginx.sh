#!/usr/bin/env bash
set -e

PREFIX="$HOME/nginx"
NGINX_VERSION=1.26.2
PCRE_VERSION=8.45

TMPDIR=$(mktemp -d)
cd "$TMPDIR"

echo "Tải PCRE ${PCRE_VERSION}..."
curl -L "https://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz" -o pcre.tar.gz
tar xzf pcre.tar.gz

echo "Tải Nginx ${NGINX_VERSION}..."
curl -L "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz
tar xzf nginx.tar.gz

cd nginx-${NGINX_VERSION}

echo "Biên dịch Nginx với PCRE + gzip..."
./configure \
  --prefix="$PREFIX" \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-pcre=../pcre-${PCRE_VERSION}

make -j"$(nproc)"
make install

echo "Đã cài Nginx vào $PREFIX"
echo "Chạy thử: $PREFIX/sbin/nginx -v"

if ! grep -q 'nginx/sbin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/nginx/sbin:$PATH"' >> "$HOME/.bashrc"
fi
echo "Đã thêm Nginx vào PATH. Đăng nhập lại shell để dùng lệnh nginx."
