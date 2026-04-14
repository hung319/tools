#!/bin/bash

# 1. Cập nhật hệ thống
apt update && apt upgrade -y

# 2. Thiết lập Locale & Timezone Việt Nam
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
timedatectl set-timezone Asia/Ho_Chi_Minh

# 3. Xử lý Tường lửa (Dọn dẹp để Docker quản lý tốt hơn)
# Vì bạn dùng Firewall nhà cung cấp, ta nên gỡ các tool gây xung đột
apt remove ufw iptables-persistent -y
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 4. Tối ưu mạng (Bật TCP BBR)
# Kiểm tra nếu chưa có thì mới thêm vào để tránh trùng lặp
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
fi

# 5. Tạo Swap 4GB (Chỉ tạo nếu chưa có file swap)
if [ ! -f /swapfile ]; then
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    # Tối ưu độ ưu tiên của Swap
    echo "vm.swappiness=10" > /etc/sysctl.d/99-xs-swappiness.conf
    sysctl --system
fi

# 6. Cài đặt Docker & Docker Compose bản mới nhất
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 7. Kiểm tra kết quả
echo "------------------------------------------------"
echo "Cấu hình hoàn tất!"
echo "Múi giờ: $(date)"
echo "TCP BBR: $(sysctl net.ipv4.tcp_congestion_control)"
echo "Swap: $(free -h | grep Swap)"
echo "Docker: $(docker --version)"
echo "------------------------------------------------"
