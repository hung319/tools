#!/bin/sh

# Script để tự động clone Spack và hướng dẫn thiết lập môi trường.

# Dừng script ngay khi có lỗi
set -e

# Xác định thư mục cài đặt Spack
SPACK_DIR="$HOME/.local/spack"

# 1. Clone Spack nếu chưa tồn tại
if [ -d "$SPACK_DIR" ]; then
    echo "✅ Thư mục Spack đã tồn tại tại: $SPACK_DIR. Bỏ qua bước clone."
else
    echo "⏳ Đang clone Spack vào $SPACK_DIR..."
    # --depth=1 để clone nhanh hơn, chỉ lấy commit mới nhất
    git clone --depth=1 https://github.com/spack/spack.git "$SPACK_DIR"
    echo "✅ Clone Spack thành công."
fi

# 2. Phát hiện shell và đưa ra hướng dẫn
# Lấy tên của shell hiện tại (ví dụ: bash, zsh, fish)
CURRENT_SHELL=$(basename "$SHELL")

echo ""
echo "------------------------------------------------------------------"
echo "🚀 Spack đã sẵn sàng!"
echo "Để kích hoạt trong phiên làm việc hiện tại, hãy chạy lệnh sau:"
echo "------------------------------------------------------------------"
echo ""

# Dùng case-statement để in ra lệnh phù hợp với shell
case "$CURRENT_SHELL" in
    bash|zsh|sh)
        # In chữ màu xanh lá cho dễ nhìn
        echo "👉 \033[1;32msource $SPACK_DIR/share/spack/setup-env.sh\033[0m"
        ;;
    csh|tcsh)
        echo "👉 \033[1;32msource $SPACK_DIR/share/spack/setup-env.csh\033[0m"
        ;;
    fish)
        echo "👉 \033[1;32m. $SPACK_DIR/share/spack/setup-env.fish\033[0m"
        ;;
    *)
        echo "⚠️ Không thể tự động xác định shell của bạn ($CURRENT_SHELL)."
        echo "Vui lòng tìm file setup phù hợp trong '$SPACK_DIR/share/spack/' và chạy nó."
        ;;
esac

echo ""
echo "💡 Mẹo: Để Spack luôn có sẵn mỗi khi mở terminal,"
echo "   hãy thêm lệnh trên vào file khởi động của shell"
echo "   (ví dụ: ~/.bashrc, ~/.zshrc, hoặc ~/.config/fish/config.fish)."
echo "------------------------------------------------------------------"
