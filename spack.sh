#!/bin/sh

# Script tự động clone Spack, kích hoạt cho phiên hiện tại,
# và tự động thêm lệnh kích hoạt vào file cấu hình shell.

# Dừng script ngay khi có lỗi
set -e

# --- CÁC BIẾN CẤU HÌNH ---
SPACK_DIR="$HOME/.local/spack"
SPACK_REPO="https://github.com/spack/spack.git"

# --- HÀM HỖ TRỢ ---

# Hàm in thông báo với màu sắc để dễ đọc hơn
print_info() {
    # Màu xanh lá cây
    printf "\033[1;32m%s\033[0m\n" "$1"
}

print_warning() {
    # Màu vàng
    printf "\033[1;33m%s\033[0m\n" "$1"
}

print_success() {
    # Màu xanh dương
    printf "\033[1;34m%s\033[0m\n" "$1"
}


# --- BƯỚC 1: CLONE REPOSITORY SPACK ---
if [ -d "$SPACK_DIR" ]; then
    print_info "✅ Thư mục Spack đã tồn tại tại: $SPACK_DIR. Bỏ qua bước clone."
else
    print_info "⏳ Đang clone Spack từ $SPACK_REPO..."
    # --depth=1 để clone nhanh hơn, chỉ lấy commit mới nhất
    git clone --depth=1 "$SPACK_REPO" "$SPACK_DIR"
    print_info "✅ Clone Spack thành công."
fi


# --- BƯỚC 2: XÁC ĐỊNH SHELL VÀ FILE CẤU HÌNH ---
CURRENT_SHELL=$(basename "$SHELL")
CONFIG_FILE=""
SOURCE_CMD=""

case "$CURRENT_SHELL" in
    bash)
        CONFIG_FILE="$HOME/.bashrc"
        SOURCE_CMD=". \"$SPACK_DIR/share/spack/setup-env.sh\""
        ;;
    zsh)
        CONFIG_FILE="$HOME/.zshrc"
        SOURCE_CMD=". \"$SPACK_DIR/share/spack/setup-env.sh\""
        ;;
    sh)
        # sh thường không có file rc tương tác, .profile là lựa chọn tốt nhất
        CONFIG_FILE="$HOME/.profile"
        SOURCE_CMD=". \"$SPACK_DIR/share/spack/setup-env.sh\""
        ;;
    fish)
        # Fish shell có cấu trúc khác
        CONFIG_FILE="$HOME/.config/fish/config.fish"
        SOURCE_CMD=". \"$SPACK_DIR/share/spack/setup-env.fish\""
        ;;
    csh|tcsh)
        CONFIG_FILE="$HOME/.cshrc" # Hoặc .tcshrc
        SOURCE_CMD="source \"$SPACK_DIR/share/spack/setup-env.csh\""
        ;;
    *)
        print_warning "⚠️ Không thể tự động xác định cấu hình cho shell '$CURRENT_SHELL'."
        print_warning "Vui lòng tự thêm lệnh source phù hợp vào file cấu hình của bạn."
        exit 1
        ;;
esac


# --- BƯỚC 3: THÊM LỆNH VÀO FILE CẤU HÌNH ---
# Kiểm tra xem lệnh đã tồn tại trong file cấu hình chưa
if grep -q "setup-env.sh" "$CONFIG_FILE" 2>/dev/null; then
    print_info "✅ Lệnh kích hoạt Spack đã có trong $CONFIG_FILE."
else
    print_info "⏳ Đang thêm lệnh kích hoạt Spack vào $CONFIG_FILE..."
    # Thêm một dòng trống và một dòng comment để dễ nhận biết
    echo "" >> "$CONFIG_FILE"
    echo "# [Spack] Kích hoạt môi trường Spack tự động" >> "$CONFIG_FILE"
    echo "$SOURCE_CMD" >> "$CONFIG_FILE"
    print_info "✅ Đã thêm thành công."
fi


# --- BƯỚC 4: KÍCH HOẠT CHO PHIÊN LÀM VIỆC HIỆN TẠI ---
print_info "⏳ Kích hoạt Spack cho phiên làm việc hiện tại..."
eval "$SOURCE_CMD"


# --- HOÀN TẤT ---
echo ""
print_success "🚀 Cài đặt và cấu hình Spack hoàn tất!"
print_success "Spack hiện đã được kích hoạt. Bạn có thể kiểm tra bằng lệnh 'spack --version'."
print_success "Từ lần sau, Spack sẽ tự động được kích hoạt mỗi khi bạn mở terminal mới."
