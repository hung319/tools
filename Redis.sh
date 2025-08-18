#!/bin/bash

# ==============================================================================
# Script cài đặt Redis non-root (Không Tcl, Full CPU)
# Tác giả: Gemini
# Phiên bản: 2.2
#
# Thay đổi:
# - Sử dụng 'make -j$(nproc)' để biên dịch với tất cả các lõi CPU.
# ==============================================================================

# Dừng script ngay lập tức nếu có lỗi xảy ra
set -e

# --- CÁC BIẾN CẤU HÌNH (Bạn có thể thay đổi các giá trị này) ---
REDIS_VERSION="7.2.5"      # Phiên bản Redis ổn định mới nhất
REDIS_PORT="6379"          # Port mặc định của Redis
REDIS_USER="default"       # Tên người dùng Redis (yêu cầu Redis 6.0+)
REDIS_PASS="your-strong-password-here" # !!! THAY ĐỔI MẬT KHẨU NÀY !!!

# --- CÁC ĐƯỜNG DẪN CỐ ĐỊNH ---
INSTALL_PATH="$HOME/redis"
DOWNLOAD_DIR="$HOME/src"

# --- BƯỚC 1: KIỂM TRA CÁC CÔNG CỤ CẦN THIẾT ---
echo "⚙️  Kiểm tra các công cụ biên dịch (build-essential)..."
if ! command -v gcc >/dev/null || ! command -v make >/dev/null; then
    echo "❌ LỖI: Yêu cầu quản trị viên (root) cài đặt các gói sau:"
    echo "sudo apt update && sudo apt install build-essential -y"
    exit 1
fi
echo "✅  Các công cụ cần thiết đã có sẵn."
echo ""

# --- BƯỚC 2: TẠO CẤU TRÚC THƯ MỤC ---
echo "📁  Tạo cấu trúc thư mục..."
mkdir -p "$INSTALL_PATH"/{bin,etc,data,log}
mkdir -p "$DOWNLOAD_DIR"
echo "✅  Đã tạo thư mục tại $INSTALL_PATH và $DOWNLOAD_DIR."
echo ""

# --- BƯỚC 3: TẢI VÀ GIẢI NÉN MÃ NGUỒN ---
echo "🌍  Đang tải Redis v$REDIS_VERSION vào $DOWNLOAD_DIR..."
cd "$DOWNLOAD_DIR"

if [ ! -f "redis-${REDIS_VERSION}.tar.gz" ]; then
    wget -q --show-progress "http://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
else
    echo "ℹ️  File nén đã tồn tại, bỏ qua bước tải."
fi

echo "📦  Đang giải nén mã nguồn..."
rm -rf "redis-${REDIS_VERSION}"
tar -xzvf "redis-${REDIS_VERSION}.tar.gz" > /dev/null
cd "redis-${REDIS_VERSION}"
echo "✅  Giải nén thành công."
echo ""

# --- BƯỚC 4: BIÊN DỊCH VÀ CÀI ĐẶT ---
CPU_CORES=$(nproc)
echo "🛠️  Đang biên dịch Redis với $CPU_CORES lõi CPU... (quá trình này sẽ nhanh hơn)"
# Sử dụng -j$(nproc) để biên dịch với tất cả các lõi CPU, giúp tăng tốc đáng kể
make -j$(nproc) MALLOC=libc > /dev/null
echo "✅  Biên dịch hoàn tất."

echo "🚀  Đang cài đặt Redis vào $INSTALL_PATH..."
make install PREFIX="$INSTALL_PATH" > /dev/null
echo "✅  Cài đặt thành công, các file thực thi nằm trong $INSTALL_PATH/bin."
echo ""

# --- BƯỚC 5: TẠO FILE CẤU HÌNH TÙY CHỈNH ---
echo "📝  Tạo file cấu hình tùy chỉnh..."
CONFIG_FILE="$INSTALL_PATH/etc/redis.conf"
cp redis.conf "$CONFIG_FILE"

# Chỉnh sửa file cấu hình
sed -i "s|^port 6379|port $REDIS_PORT|" "$CONFIG_FILE"
sed -i "s|^daemonize no|daemonize yes|" "$CONFIG_FILE"
sed -i "s|^pidfile /var/run/redis_6379.pid|pidfile $INSTALL_PATH/redis.pid|" "$CONFIG_FILE"
sed -i "s|^logfile \"\"|logfile \"$INSTALL_PATH/log/redis.log\"|" "$CONFIG_FILE"
sed -i "s|^dir ./|dir $INSTALL_PATH/data|" "$CONFIG_FILE"

# Cấu hình bảo mật: user và password
sed -i "/^user /d" "$CONFIG_FILE"
sed -i "/^requirepass /d" "$CONFIG_FILE"
echo "" >> "$CONFIG_FILE"
echo "# === Cấu hình bảo mật tùy chỉnh ===" >> "$CONFIG_FILE"
echo "user $REDIS_USER on >$REDIS_PASS ~* +@all" >> "$CONFIG_FILE"
echo "requirepass $REDIS_PASS" >> "$CONFIG_FILE"

echo "✅  File cấu hình đã được tạo tại $CONFIG_FILE"
echo ""

# --- BƯỚC 6: CẬP NHẬT BIẾN MÔI TRƯỜNG ---
echo "🔧  Cập nhật biến môi trường trong ~/.bashrc..."
REDIS_PATH_EXPORT="export PATH=\$HOME/redis/bin:\$PATH"

if ! grep -qF "$REDIS_PATH_EXPORT" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Thêm đường dẫn Redis vào PATH" >> ~/.bashrc
    echo "$REDIS_PATH_EXPORT" >> ~/.bashrc
    echo "✅  Đã thêm đường dẫn Redis vào ~/.bashrc. Vui lòng tải lại shell."
else
    echo "ℹ️  Đường dẫn Redis đã tồn tại trong ~/.bashrc."
fi
echo ""

# --- BƯỚC 7: DỌN DẸP ---
echo "🧹  Dọn dẹp các file mã nguồn đã giải nén..."
cd ~
rm -rf "${DOWNLOAD_DIR}/redis-${REDIS_VERSION}"
echo "✅  Dọn dẹp hoàn tất. File nén .tar.gz được giữ lại trong $DOWNLOAD_DIR."
echo ""

# --- HOÀN TẤT ---
echo "🎉  CÀI ĐẶT REDIS THÀNH CÔNG! 🎉"
echo ""
echo "--- HƯỚNG DẪN SỬ DỤNG ---"
echo "1. Tải lại cấu hình shell để nhận biến PATH mới:"
echo "   source ~/.bashrc"
echo ""
echo "2. Khởi động Redis Server:"
echo "   redis-server $INSTALL_PATH/etc/redis.conf"
echo ""
echo "3. Kiểm tra trạng thái (kết nối và xác thực):"
echo "   redis-cli -p $REDIS_PORT -a $REDIS_PASS ping"
echo "   (Nếu nhận được phản hồi 'PONG' là thành công)"
echo ""
echo "4. Tắt Redis Server (yêu cầu xác thực):"
echo "   redis-cli -p $REDIS_PORT -a $REDIS_PASS shutdown"
echo ""
