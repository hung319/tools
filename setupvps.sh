#!/bin/bash

# Đảm bảo các lệnh không yêu cầu tương tác người dùng
export DEBIAN_FRONTEND=noninteractive

# 1. Cập nhật hệ thống
apt-get update && apt-get upgrade -y

# 2. Thiết lập Locale & Timezone
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
timedatectl set-timezone Asia/Ho_Chi_Minh

# 3. Dọn dẹp Firewall nội bộ (Để dùng Firewall nhà cung cấp)
apt-get remove ufw iptables-persistent -y
iptables -F
iptables -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 4. Tối ưu mạng (Bật TCP BBR)
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 5. Tạo Swap 4GB (Chỉ tạo nếu chưa có)
if [ ! -f /swapfile ]; then
    # Thử fallocate trước, nếu lỗi thì dùng dd
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    # Tối ưu swappiness
    echo "vm.swappiness=10" > /etc/sysctl.d/99-xs-swappiness.conf
    sysctl --system
fi

# 6. Cài đặt Docker (Tự động dọn dẹp file cài sau khi xong)
curl -fsSL https://get.docker.com | sh

# 7. Hiển thị thông báo hoàn tất
echo "================================================="
echo " SETUP VPS HOÀN TẤT!"
echo " BBR: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
echo " SWAP: $(free -h | grep Swap | awk '{print $2}')"
echo " DOCKER: $(docker --version)"
echo "================================================="
