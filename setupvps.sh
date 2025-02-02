#!/bin/bash

# đổi pass
passwd

# tạo user mới
sudo adduser hung319
sudo usermod -aG sudo hung319

# cập nhập OS
sudo apt update && sudo apt upgrade -y

# set locale
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Tắt Firewall
sudo apt remove iptables-persistent -y
sudo ufw disable
sudo iptables -F

# Chỉnh về múi giờ Việt Nam
timedatectl set-timezone Asia/Ho_Chi_Minh

# Tạo swap 4GB RAM
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
cat <<EOF > /etc/sysctl.d/99-xs-swappiness.conf
vm.swappiness=10
EOF

# Enable TCP BBR congestion control
cat <<EOF > /etc/sysctl.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

# Cài đặt docker và docker-compose
curl -fsSL https://get.docker.com -o get-docker.sh 
sh get-docker.sh
