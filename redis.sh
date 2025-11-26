#!/bin/bash

# ==============================================================================
# Script cài đặt Redis "All-in-One" (Nguồn: GitHub)
# Tác giả: Gemini
# Phiên bản: 3.1 (GitHub Source)
#
# Tính năng:
# - Tải Redis 8.4.0 từ GitHub Release
# - Cài đặt binaries, config, logs, data vào ~/database/redis
# - Tự động tạo file start.sh và stop.sh
# ==============================================================================

# Dừng script ngay lập tức nếu có lỗi xảy ra
set -e

# --- CÁC BIẾN CẤU HÌNH ---
REDIS_VERSION="8.4.0"      # Phiên bản Redis từ GitHub Tag
REDIS_PORT="6379"          # Port Redis
REDIS_USER="default"       # User mặc định
REDIS_PASS="your-strong-password-here" # !!! ĐỔI MẬT KHẨU TẠI ĐÂY !!!

# Link tải từ GitHub (Dựa trên Version)
DOWNLOAD_URL="https://github.com/redis/redis/archive/refs/tags/${REDIS_VERSION}.tar.gz"

# --- CẤU HÌNH ĐƯỜNG DẪN ---
BASE_DIR="$HOME/database/redis"
BIN_DIR="$BASE_DIR/bin"
DATA_DIR="$BASE_DIR/data"
CONF_DIR="$BASE_DIR/conf"
LOG_DIR="$BASE_DIR/logs"
SRC_DIR="$HOME/src"

# --- BƯỚC 1: KIỂM TRA CÔNG CỤ ---
echo "⚙️  Kiểm tra công cụ biên dịch..."
if ! command -v gcc >/dev/null || ! command -v make >/dev/null; then
    echo "❌ LỖI: Cần cài đặt build-essential. Chạy lệnh sau:"
    echo "sudo apt update && sudo apt install build-essential -y"
    exit 1
fi

# --- BƯỚC 2: TẠO CẤU TRÚC THƯ MỤC ---
echo "📁  Đang tạo thư mục tại $BASE_DIR..."
mkdir -p "$BIN_DIR" "$DATA_DIR" "$CONF_DIR" "$LOG_DIR" "$SRC_DIR"

# --- BƯỚC 3: TẢI VÀ GIẢI NÉN (TỪ GITHUB) ---
echo "🌍  Đang tải Redis v$REDIS_VERSION từ GitHub..."
cd "$SRC_DIR"

# Tải file về và đổi tên thành redis-version.tar.gz để dễ xử lý
if [ ! -f "redis-${REDIS_VERSION}.tar.gz" ]; then
    wget -q --show-progress -O "redis-${REDIS_VERSION}.tar.gz" "$DOWNLOAD_URL"
else
    echo "ℹ️  File đã tồn tại, bỏ qua bước tải."
fi

echo "📦  Giải nén mã nguồn..."
# Xóa thư mục cũ nếu có để tránh lỗi
rm -rf "redis-${REDIS_VERSION}"
tar -xzvf "redis-${REDIS_VERSION}.tar.gz" > /dev/null

# Khi tải từ GitHub archive, thư mục giải nén thường không có chữ "v" hoặc có thể khác biệt
# Chúng ta sẽ cd vào thư mục vừa giải nén (thường là redis-8.4.0)
cd "redis-${REDIS_VERSION}"

# --- BƯỚC 4: BIÊN DỊCH VÀ CÀI ĐẶT ---
echo "🛠️  Đang biên dịch (sử dụng tất cả nhân CPU)..."
make -j$(nproc) MALLOC=libc > /dev/null

echo "🚀  Đang cài đặt Binary vào $BIN_DIR..."
make install PREFIX="$BASE_DIR" > /dev/null

# --- BƯỚC 5: TẠO CONFIG ---
echo "📝  Thiết lập file cấu hình..."
CONFIG_FILE="$CONF_DIR/redis.conf"
cp redis.conf "$CONFIG_FILE"

# Chỉnh sửa đường dẫn trong config
sed -i "s|^port 6379|port $REDIS_PORT|" "$CONFIG_FILE"
sed -i "s|^daemonize no|daemonize yes|" "$CONFIG_FILE"
sed -i "s|^pidfile .*|pidfile $BASE_DIR/redis.pid|" "$CONFIG_FILE"
sed -i "s|^logfile .*|logfile \"$LOG_DIR/redis.log\"|" "$CONFIG_FILE"
sed -i "s|^dir .*|dir $DATA_DIR|" "$CONFIG_FILE"

# Bảo mật
sed -i "/^user /d" "$CONFIG_FILE"
sed -i "/^requirepass /d" "$CONFIG_FILE"
echo "" >> "$CONFIG_FILE"
echo "# Security Settings" >> "$CONFIG_FILE"
echo "user $REDIS_USER on >$REDIS_PASS ~* +@all" >> "$CONFIG_FILE"
echo "requirepass $REDIS_PASS" >> "$CONFIG_FILE"

# --- BƯỚC 6: TẠO SCRIPT QUẢN LÝ ---
echo "🔧  Đang tạo script start.sh và stop.sh..."

# File start.sh
cat > "$BASE_DIR/start.sh" <<EOF
#!/bin/bash
echo "🚀 Starting Redis Server ($REDIS_VERSION)..."
$BIN_DIR/redis-server $CONFIG_FILE
if [ \$? -eq 0 ]; then
    echo "✅ Success! Redis is running on port $REDIS_PORT"
    echo "   PID File: $BASE_DIR/redis.pid"
else
    echo "❌ Failed to start. Check logs at $LOG_DIR/redis.log"
fi
EOF

# File stop.sh
cat > "$BASE_DIR/stop.sh" <<EOF
#!/bin/bash
echo "🛑 Stopping Redis Server..."
$BIN_DIR/redis-cli -p $REDIS_PORT -a "$REDIS_PASS" shutdown
if [ \$? -eq 0 ]; then
    echo "✅ Redis stopped successfully."
else
    echo "❌ Failed to stop Redis."
fi
EOF

chmod +x "$BASE_DIR/start.sh"
chmod +x "$BASE_DIR/stop.sh"

# --- BƯỚC 7: DỌN DẸP ---
echo "🧹  Dọn dẹp mã nguồn..."
cd ~
rm -rf "${SRC_DIR}/redis-${REDIS_VERSION}"
# Giữ lại file .tar.gz trong ~/src nếu muốn dùng lại

# --- HOÀN TẤT ---
echo ""
echo "🎉  CÀI ĐẶT REDIS $REDIS_VERSION TỪ GITHUB THÀNH CÔNG!"
echo "========================================================"
echo "📂  Vị trí: $BASE_DIR"
echo "👉  Start:  $BASE_DIR/start.sh"
echo "👉  Stop:   $BASE_DIR/stop.sh"
echo "========================================================"
