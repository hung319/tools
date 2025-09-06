#!/usr/bin/env bash
set -e

# --- Cấu hình ---
NCURSES_VERSION="6.5"
NCURSES_URL="https://ftp.gnu.org/pub/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz"
ARCHIVE_NAME=$(basename "$NCURSES_URL")
EXTRACTED_DIR="ncurses-${NCURSES_VERSION}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải ncurses ${NCURSES_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$NCURSES_URL"
else
    echo "☑️  Đã có file nén ncurses."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn ncurses."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình ncurses..."
# Các cờ này đảm bảo build shared, có file .pc và sinh libtinfo
./configure --prefix="$PREFIX" \
            --with-shared \
            --without-debug \
            --enable-pc-files \
            --with-pkg-config-libdir="$PREFIX/lib/pkgconfig" \
            --with-termlib

echo "🚀 Đang build và cài đặt ncurses..."
make -j"$(nproc)"
make install

echo ""
echo "✅ ncurses ${NCURSES_VERSION} đã được cài đặt vào $PREFIX"
echo "👉 Kiểm tra libtinfo: ls $PREFIX/lib | grep tinfo"
