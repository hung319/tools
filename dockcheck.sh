curl -L https://raw.githubusercontent.com/mag37/dockcheck/main/dockcheck.sh -o /usr/local/bin/dockcheck.sh && chmod +x /usr/local/bin/dockcheck.sh && /usr/local/bin/dockcheck.sh -v && (crontab -l 2>/dev/null | grep -v "/usr/local/bin/dockcheck.sh"; echo "0 4 * * * /usr/local/bin/dockcheck.sh -ai -p > /dev/null 2>&1") | crontab - && echo "Xong! Dockcheck đã cài và đặt lịch 4h sáng hàng ngày."


sudo rm /usr/local/bin/dockcheck.sh && \
sudo rm /usr/local/bin/regctl && \
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/dockcheck.sh") | crontab - && \
echo "Đã gỡ bỏ Dockcheck và lịch chạy tự động."
