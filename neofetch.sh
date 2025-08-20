#!/bin/bash

# Tạo các thư mục cần thiết nếu chúng chưa tồn tại
mkdir -p "$HOME/src"
mkdir -p "$HOME/.local/bin"

# Di chuyển vào thư mục src
cd "$HOME/src" || exit

# Xóa thư mục neofetch cũ nếu có để tránh lỗi
rm -rf neofetch

# Tải mã nguồn Neofetch từ GitHub
git clone https://github.com/dylanaraps/neofetch.git

# Di chuyển vào thư mục neofetch vừa tải về
cd neofetch || exit

# Build và cài đặt Neofetch vào $HOME/.local
# PREFIX xác định thư mục cài đặt
make PREFIX="$HOME/.local" install

# (Tùy chọn) Thêm $HOME/.local/bin vào PATH nếu chưa có
# Bạn có thể thêm dòng này vào file .bashrc, .zshrc, hoặc .profile của bạn
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo "Đã thêm $HOME/.local/bin vào PATH trong ~/.bashrc. Vui lòng khởi động lại terminal hoặc chạy 'source ~/.bashrc'."
fi

echo "Cài đặt Neofetch hoàn tất!"
neofetch
