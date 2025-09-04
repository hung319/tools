#!/bin/bash
set -e

# Định nghĩa thư mục cài đặt
PREFIX="$HOME/.local"
SRC_DIR="$HOME/src"
VER="2.7.0"
URL="https://github.com/djc/rnc2rng/archive/refs/tags/$VER.tar.gz"

# Tạo thư mục nguồn nếu chưa tồn tại
mkdir -p "$SRC_DIR"
cd "$SRC_DIR"

# Tải mã nguồn nếu chưa có
if [ ! -f "$VER.tar.gz" ]; then
    curl -LO "$URL"
fi

# Giải nén và vào thư mục
rm -rf "rnc2rng-$VER"
tar -xf "$VER.tar.gz"
cd "rnc2rng-$VER"

# Cài đặt vào thư mục .local
python3 setup.py install --prefix="$PREFIX"

# Đảm bảo thư mục bin đã có trong PATH
mkdir -p "$PREFIX/bin"

# Tạo script rnc2rng để chạy dễ dàng
cat > "$PREFIX/bin/rnc2rng" <<'EOF'
#!/bin/bash
exec python3 -m rnc2rng "$@"
EOF

chmod +x "$PREFIX/bin/rnc2rng"

echo "✅ Đã cài đặt rnc2rng $VER vào $PREFIX/bin"
