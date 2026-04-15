#!/bin/bash

# Đảm bảo các lệnh không yêu cầu tương tác người dùng
export DEBIAN_FRONTEND=noninteractive

# 1. Cập nhật hệ thống
apt-get update && apt-get upgrade -y && apt install sudo wget curl -y

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
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    echo "vm.swappiness=10" > /etc/sysctl.d/99-xs-swappiness.conf
    sysctl --system
fi

# 6. Cài đặt Docker
curl -fsSL https://get.docker.com | sh

# 7. Cấu hình Fail2ban (Tự động nhận diện SSH Port)
echo "Đang cấu hình Fail2ban..."
# Tìm port SSH đang chạy thực tế
SSH_PORT=$(ss -tlnp | grep sshd | awk '{print $4}' | awk -F':' '{print $NF}' | head -n 1)
# Nếu không thấy, tìm trong file config
[ -z "$SSH_PORT" ] && SSH_PORT=$(grep -iE "^#?Port [0-9]+" /etc/ssh/sshd_config | grep -oE "[0-9]+" | head -n 1)
# Cuối cùng mặc định là 22
[ -z "$SSH_PORT" ] && SSH_PORT=22

apt-get install fail2ban -y
cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = $SSH_PORT
maxretry = 5
bantime = 1h
backend = systemd
EOF
systemctl restart fail2ban

# 8. Hiển thị thông báo hoàn tất
echo "================================================="
echo " SETUP VPS HOÀN TẤT!"
echo " BBR: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
echo " SWAP: $(free -h | grep Swap | awk '{print $2}')"
echo " DOCKER: $(docker --version)"
echo " SSH PORT: $SSH_PORT"
echo " FAIL2BAN: $(systemctl is-active fail2ban)"
echo "================================================="
