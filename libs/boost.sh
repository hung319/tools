#!/usr/bin/env bash
set -e

# --- Cấu hình ---
BOOST_VERSION="1.89.0"
BOOST_URL="https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION//./_}.tar.gz"
ARCHIVE_NAME=$(basename "$BOOST_URL")
EXTRACTED_DIR="boost_${BOOST_VERSION//./_}"

# --- Đường dẫn ---
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"

# --- Chuẩn bị ---
echo "▶️  Chuẩn bị môi trường..."
mkdir -p "$PREFIX" "$SRC_DIR"
cd "$SRC_DIR"

# --- Tải mã nguồn ---
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "📥 Đang tải Boost ${BOOST_VERSION}..."
    wget -O "$ARCHIVE_NAME" "$BOOST_URL"
else
    echo "☑️  Đã có file nén Boost."
fi

# --- Giải nén ---
if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "📦 Đang giải nén..."
    tar -xzf "$ARCHIVE_NAME"
else
    echo "☑️  Đã có thư mục mã nguồn Boost."
fi

cd "$EXTRACTED_DIR"

# --- Build và cài đặt ---
echo "⚙️  Đang cấu hình hệ thống build Boost (bootstrap)..."
./bootstrap.sh --prefix="$PREFIX"

echo "🚀 Đang build và cài đặt Boost (sẽ bỏ qua các module không cần thiết)..."

# =========================================================================
# SỬA LỖI Ở ĐÂY:
# Thêm --without-<tên module> để bỏ qua các thư viện dễ gây lỗi và không
# cần thiết cho việc build Nix.
# =========================================================================
./b2 -j"$(nproc)" --without-mpi --without-python --without-graph_parallel install

echo ""
echo "✅ Boost ${BOOST_VERSION} đã được cài đặt vào $PREFIX"
