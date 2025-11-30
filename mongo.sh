#!/bin/bash
set -e # Thoát ngay khi có lỗi

# --- Cấu hình các biến ---
MONGO_SERVER_VERSION="8.2.2"
# Chọn phiên bản mongosh mới nhất, tương thích ngược
MONGO_SHELL_VERSION="2.5.10"
MONGO_USER="myuser"
MONGO_PASS="mypassword"
MONGO_PORT="27017"

# --- THAY ĐỔI YÊU CẦU ---
# Cài đặt vào thư mục ~/database/mongodb
INSTALL_DIR="$HOME/database/mongodb" 
# --- KẾT THÚC THAY ĐỔI ---

DATA_DIR="$INSTALL_DIR/data"
LOG_DIR="$INSTALL_DIR/log"
LOG_FILE="$LOG_DIR/mongod.log"
CONFIG_FILE="$INSTALL_DIR/mongod.conf"

# --- Các hàm chức năng ---
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        "x86_64") MONGO_ARCH="x86_64"; SHELL_ARCH="x64" ;;
        "aarch64") MONGO_ARCH="arm64"; SHELL_ARCH="arm64" ;;
        *) echo "❌ Lỗi: Kiến trúc '$ARCH' không được hỗ trợ."; exit 1 ;;
    esac
}

add_to_path() {
    local shell_config_file
    if [ -f "$HOME/.zshrc" ]; then shell_config_file="$HOME/.zshrc";
    elif [ -f "$HOME/.bashrc" ]; then shell_config_file="$HOME/.bashrc";
    else shell_config_file="$HOME/.profile"; fi
    
    local path_to_add="$INSTALL_DIR/bin"
    if ! grep -q "export PATH=\$PATH:$path_to_add" "$shell_config_file"; then
        echo "✍️  Thêm MongoDB vào PATH trong file $shell_config_file..."
        echo -e "\n# Add MongoDB to PATH\nexport PATH=\$PATH:$path_to_add" >> "$shell_config_file"
    fi
}

# --- Bắt đầu quá trình chính ---
detect_arch

# 1. CÀI ĐẶT MONGODB SERVER
echo "🚀 Bắt đầu cài đặt MongoDB Server v${MONGO_SERVER_VERSION}..."
echo "📂 Thư mục cài đặt: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR" "$DATA_DIR" "$LOG_DIR"

MONGO_PLATFORM="debian12"
SERVER_URL="https://fastdl.mongodb.org/linux/mongodb-linux-${MONGO_ARCH}-${MONGO_PLATFORM}-${MONGO_SERVER_VERSION}.tgz"

echo "📥 Đang tải Server từ: $SERVER_URL"
if ! curl -# -f -L "$SERVER_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1; then
    echo "❌ Lỗi: Tải hoặc giải nén MongoDB Server thất bại."
    exit 1
fi
echo "✅ Cài đặt Server thành công."

# 2. <<< BƯỚC MỚI: TẢI MONGOSH (SHELL) RIÊNG BIỆT >>>
echo ""
echo "🚀 Bắt đầu cài đặt MongoDB Shell v${MONGO_SHELL_VERSION}..."
SHELL_URL="https://downloads.mongodb.com/compass/mongosh-${MONGO_SHELL_VERSION}-linux-${SHELL_ARCH}.tgz"

echo "📥 Đang tải Shell từ: $SHELL_URL"
# Giải nén trực tiếp vào thư mục cài đặt đã có
if ! curl -# -f -L "$SHELL_URL" | tar -xz -C "$INSTALL_DIR" --strip-components=1; then
    echo "❌ Lỗi: Tải hoặc giải nén MongoDB Shell thất bại."
    exit 1
fi
echo "✅ Cài đặt Shell thành công. File 'mongosh' đã được thêm vào thư mục bin."

# 3. CẤU HÌNH VÀ TẠO NGƯỜI DÙNG
MONGOD_BIN="$INSTALL_DIR/bin/mongod"
MONGOSH_BIN="$INSTALL_DIR/bin/mongosh" # Bây giờ file này chắc chắn tồn tại

echo ""
echo "⚙️  Tạo file cấu hình và khởi tạo người dùng..."
cat > "$CONFIG_FILE" << EOL
storage:
  dbPath: "$DATA_DIR"
net:
  port: $MONGO_PORT
  bindIp: 0.0.0.0
systemLog:
  destination: file
  path: "$LOG_FILE"
  logAppend: true
processManagement:
  fork: true
security:
  authorization: "enabled"
EOL

add_to_path

INIT_JS_FILE="$INSTALL_DIR/init-user.js"
cat > "$INIT_JS_FILE" << EOL
db = db.getSiblingDB('admin');
db.createUser({
  user: "$MONGO_USER",
  pwd: "$MONGO_PASS",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
});
EOL

$MONGOD_BIN --config $CONFIG_FILE

echo "    Chờ server khởi động trong 5 giây..."
sleep 5
$MONGOSH_BIN --port $MONGO_PORT < "$INIT_JS_FILE"

if [ $? -eq 0 ]; then
    echo "    ✅ Tạo người dùng '$MONGO_USER' thành công!"
else
    echo "    ❌ Lỗi: Không thể tạo người dùng. Vui lòng kiểm tra log tại $LOG_FILE"
fi

echo "    Dừng server để hoàn tất quá trình cài đặt..."
$MONGOD_BIN --config $CONFIG_FILE --shutdown
sleep 2
rm "$INIT_JS_FILE" # Xóa file js khởi tạo cho sạch

# --- THAY ĐỔI YÊU CẦU: TẠO SCRIPT START/STOP ---
echo ""
echo "🤖 Đang tạo script 'start.sh' và 'stop.sh'..."

START_SCRIPT="$INSTALL_DIR/start.sh"
STOP_SCRIPT="$INSTALL_DIR/stop.sh"

# --- Tạo start.sh ---
# Các biến $MONGOD_BIN, $CONFIG_FILE, $LOG_FILE sẽ được thay thế bằng giá trị thực
# tại thời điểm chạy script cài đặt này.
cat > "$START_SCRIPT" << EOL
#!/bin/bash
echo "🚀 Đang khởi động MongoDB..."
"$MONGOD_BIN" --config "$CONFIG_FILE"
if [ \$? -eq 0 ]; then
    echo "✅ MongoDB đã khởi động. Kiểm tra log tại: $LOG_FILE"
else
    echo "❌ Lỗi: Không thể khởi động. Kiểm tra log tại: $LOG_FILE"
fi
EOL

# --- Tạo stop.sh ---
cat > "$STOP_SCRIPT" << EOL
#!/bin/bash
echo "🛑 Đang dừng MongoDB..."
"$MONGOD_BIN" --config "$CONFIG_FILE" --shutdown
if [ \$? -eq 0 ]; then
    echo "✅ Đã gửi lệnh dừng."
else
    echo "❌ Lỗi: Không thể dừng. Server có đang chạy không?"
fi
EOL

# Cấp quyền thực thi
chmod +x "$START_SCRIPT" "$STOP_SCRIPT"
echo "✅ Đã tạo $START_SCRIPT và $STOP_SCRIPT"
# --- KẾT THÚC THAY ĐỔI ---


# --- Hoàn tất ---
echo ""
echo "--- CÀI ĐẶT HOÀN TẤT ---"
echo "🎉 Mọi thứ đã sẵn sàng!"
echo "❗️ QUAN TRỌNG: Vui lòng chạy 'source ~/.bashrc' (hoặc .zshrc/.profile) hoặc MỞ LẠI TERMINAL để cập nhật PATH."
echo ""
echo "--- HƯỚNG DẪN SỬ DỤNG ---"
echo "Các script quản lý đã được tạo trong: $INSTALL_DIR"
echo ""
echo "1. Khởi động MongoDB:"
echo "   $START_SCRIPT"
echo ""
echo "2. Kết nối với MongoDB shell:"
echo "   mongosh --port $MONGO_PORT -u '$MONGO_USER' -p '$MONGO_PASS' --authenticationDatabase admin"
echo ""
echo "3. Dừng MongoDB:"
echo "   $STOP_SCRIPT"
