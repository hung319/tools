#!/usr/bin/env bash
set -e

# 🏠 Cài vào ~/.local
PREFIX="$HOME/.local"
SRC_DIR="$HOME/tmp-postgresql-src"

# 📦 Phiên bản PostgreSQL muốn cài
PG_VERSION="16.4"

echo "📥 Tải PostgreSQL $PG_VERSION..."
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
curl -sL "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz" -o pg.tar.gz

echo "📦 Giải nén..."
tar -xzf pg.tar.gz
cd "postgresql-$PG_VERSION"

echo "🔧 Cấu hình build..."
./configure --prefix="$PREFIX" --without-readline --without-zlib

echo "⚙️ Build chỉ phần libpq..."
cd src/interfaces/libpq
make
make install

echo "⚙️ Build psql client (tùy chọn)..."
cd ../../bin/psql
make
make install || echo "⚠️ Bỏ qua nếu không cần psql"

echo "🧹 Dọn dẹp..."
cd ~
rm -rf "$SRC_DIR"

echo "✅ Hoàn tất!"
echo "🪄 Hãy thêm vào ~/.bashrc hoặc ~/.zshrc:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
