#!/usr/bin/env bash
set -e

# 🏠 Thư mục cài đặt local
PREFIX="$HOME/.local"
SRC_DIR="$HOME/tmp-postgresql-src"

# 📦 Phiên bản PostgreSQL muốn cài
PG_VERSION="16.4"

echo "📥 Đang tải PostgreSQL $PG_VERSION..."
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"
curl -sL "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.gz" -o pg.tar.gz

echo "📦 Giải nén..."
tar -xzf pg.tar.gz
cd "postgresql-$PG_VERSION"

echo "🔧 Cấu hình build..."
./configure --prefix="$PREFIX" --without-readline --without-zlib

# 🧱 Build và cài libpq
echo "⚙️ Build libpq..."
cd src/interfaces/libpq
make
make install

# 🧩 Cài đầy đủ header cần thiết cho PHP build
echo "📚 Cài đặt header đầy đủ..."
cd ../../include
# Copy toàn bộ header để tránh thiếu postgres_ext.h, catalog headers,...
mkdir -p "$PREFIX/include"
cp -r ./* "$PREFIX/include/"

# ⚙️ Build psql client (tùy chọn)
cd ../bin/psql
echo "⚙️ Build psql client..."
make
make install || echo "⚠️ Bỏ qua nếu không cần psql"

echo "🧹 Dọn dẹp..."
cd ~
rm -rf "$SRC_DIR"

echo "✅ Cài đặt hoàn tất!"
echo "🪄 Hãy thêm vào ~/.bashrc hoặc ~/.zshrc:"
echo 'export PATH="$HOME/.local/bin:$PATH"'
echo 'export LD_LIBRARY_PATH="$HOME/.local/lib:$LD_LIBRARY_PATH"'
