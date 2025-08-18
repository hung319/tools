#!/bin/bash

# ==============================================================================
# Script tự động xây dựng PGroonga và phụ thuộc cho Debian (non-root)
#
# Phiên bản cuối cùng:
#   - Tự động tìm kiếm file 'pg_config'.
#   - Cài đặt vào thư mục chuẩn $HOME/.local.
#   - Lưu mã nguồn vào $HOME/src.
#   - Tự động thêm biến môi trường vào ~/.bashrc nếu chưa có.
# ==============================================================================

# Dừng script ngay lập tức nếu có lỗi
set -e

# --- CẤU HÌNH ---
GROONGA_VERSION="14.0.5"
PGROONGA_VERSION="3.2.0"
INSTALL_DIR="$HOME/.local"
SRC_DIR="$HOME/src"
NUM_CORES=$(nproc 2>/dev/null || echo 1)

# --- CÁC HÀM CHỨC NĂNG ---

# Hàm tìm kiếm pg_config
find_pg_config() {
    echo "--- Bước 1: Tìm kiếm 'pg_config' ---"
    local found_path=""

    if command -v pg_config &> /dev/null; then
        found_path=$(command -v pg_config)
        echo "✅ Đã tìm thấy 'pg_config' trong PATH của bạn: $found_path"
    fi

    if [ -z "$found_path" ]; then
        echo "Không tìm thấy trong PATH. Đang quét các thư mục cục bộ..."
        found_path=$(find "$HOME" -maxdepth 4 -type f -name pg_config -executable 2>/dev/null | head -n 1)
        if [ -n "$found_path" ]; then
            echo "✅ Đã tìm thấy 'pg_config' tại: $found_path"
        fi
    fi
    
    if [ -z "$found_path" ]; then
        echo "⚠️ Không thể tự động tìm thấy 'pg_config'."
        read -p "=> Vui lòng nhập đường dẫn đầy đủ đến file 'pg_config' của bạn: " found_path
    fi

    if [ -z "$found_path" ] || [ ! -x "$found_path" ]; then
        echo "LỖI: Đường dẫn 'pg_config' không hợp lệ hoặc không tồn tại."
        exit 1
    fi

    if [[ "$found_path" == /usr/* ]]; then
        echo "------------------------------------------------------------------------------"
        echo "!!! CẢNH BÁO !!!"
        echo "Đường dẫn '$found_path' có vẻ thuộc về một bản cài đặt toàn hệ thống (bằng apt)."
        echo "Quá trình build gần như chắc chắn sẽ thất bại do thiếu quyền ghi."
        read -p "Bạn có chắc chắn muốn tiếp tục? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]; then
            echo "Đã hủy bỏ."
            exit 1
        fi
        echo "------------------------------------------------------------------------------"
    fi

    PG_CONFIG_PATH="$found_path"
    echo ""
}

# Hàm tự động cập nhật .bashrc
update_bashrc() {
    echo "--- Bước 5: Cập nhật file ~/.bashrc ---"
    # Dùng một chuỗi comment độc nhất để kiểm tra, tránh thêm nhiều lần
    local marker="# Cấu hình cho các phần mềm cài đặt cục bộ trong .local"
    
    if grep -Fxq "$marker" ~/.bashrc; then
        echo "✅ Cấu hình biến môi trường đã tồn tại trong ~/.bashrc. Bỏ qua."
    else
        echo "Thêm cấu hình biến môi trường vào cuối file ~/.bashrc..."
        # Sử dụng cat và Here Document (EOF) để thêm nhiều dòng một cách an toàn
        # Các biến $HOME, $PATH được thoát bằng dấu \ để chúng được ghi đúng vào file
        cat <<EOF >> ~/.bashrc

$marker
export PATH="\$HOME/.local/bin:\$PATH"
export LD_LIBRARY_PATH="\$HOME/.local/lib:\$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="\$HOME/.local/lib/pkgconfig:\$PKG_CONFIG_PATH"
EOF
        echo "✅ Đã thêm thành công."
    fi
    echo ""
}

# --- BẮT ĐẦU SCRIPT ---

find_pg_config

echo "--- Bước 2: Thiết lập môi trường và tạo thư mục ---"
mkdir -p "$SRC_DIR"
mkdir -p "$INSTALL_DIR"
export PATH="$INSTALL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$INSTALL_DIR/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "Thư mục cài đặt: $INSTALL_DIR"
echo "Thư mục mã nguồn: $SRC_DIR"
echo ""

echo "--- Bước 3: Tải và cài đặt Groonga v${GROONGA_VERSION} ---"
cd "$SRC_DIR"
if [ ! -f "groonga-${GROONGA_VERSION}.tar.gz" ]; then
    wget "https://packages.groonga.org/source/groonga/groonga-${GROONGA_VERSION}.tar.gz"
fi
rm -rf "groonga-${GROONGA_VERSION}"
tar -zxf "groonga-${GROONGA_VERSION}.tar.gz"
cd "groonga-${GROONGA_VERSION}"
./configure --prefix="$INSTALL_DIR"
make -j"$NUM_CORES"
make install
echo "Cài đặt Groonga thành công!"
echo ""

echo "--- Bước 4: Tải và cài đặt PGroonga v${PGROONGA_VERSION} ---"
cd "$SRC_DIR"
if [ ! -f "pgroonga-${PGROONGA_VERSION}.tar.gz" ]; then
    wget "https://packages.groonga.org/source/pgroonga/pgroonga-${PGROONGA_VERSION}.tar.gz"
fi
rm -rf "pgroonga-${PGROONGA_VERSION}"
tar -zxf "pgroonga-${PGROONGA_VERSION}.tar.gz"
cd "pgroonga-${PGROONGA_VERSION}"
export PG_CONFIG="$PG_CONFIG_PATH"
make -j"$NUM_CORES"
make install
echo "Cài đặt PGroonga thành công!"
echo ""

# Tự động cập nhật bashrc
update_bashrc

# --- HƯỚNG DẪN SAU CÀI ĐẶT ---

echo "=============================================================================="
echo "✅ XÂY DỰNG VÀ CÀI ĐẶT PGroonga HOÀN TẤT! ✅"
echo "=============================================================================="
echo ""
echo "!!! CÁC BƯỚC TIẾP THEO RẤT QUAN TRỌNG !!!"
echo ""
echo "1. Tải lại cấu hình shell."
echo "   Script đã tự động thêm các biến môi trường cần thiết vào ~/.bashrc."
echo "   Bạn chỉ cần chạy lệnh sau để áp dụng ngay lập tức:"
echo "   ---------------------------------------------------------------------------"
echo "   source ~/.bashrc"
echo "   ---------------------------------------------------------------------------"
echo "   (Hoặc bạn có thể đóng và mở lại cửa sổ terminal)."
echo ""
echo "2. Khởi động máy chủ PostgreSQL."
echo "   QUAN TRỌNG: Hãy chắc chắn bạn khởi động PostgreSQL từ một terminal đã được"
echo "   tải lại cấu hình ở trên, nếu không PostgreSQL sẽ không tìm thấy thư viện"
echo "   của Groonga (libgroonga.so) và không thể khởi động."
echo ""
echo "3. Kích hoạt extension trong cơ sở dữ liệu."
echo "   Kết nối vào database của bạn bằng psql và chạy lệnh:"
echo ""
echo "   psql ten_database_cua_ban -c 'CREATE EXTENSION pgroonga;'"
echo ""
echo "Chúc mừng bạn đã cài đặt thành công! 🎉"
