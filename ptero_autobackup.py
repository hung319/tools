#!/usr-bin/env python3
import requests
import os
import sys
from datetime import datetime

# ================== CONFIG ==================
PANEL_URL = ""  # URL Panel Pterodactyl (không có / ở cuối)
API_KEY = ""          # API key của user (không phải Admin API)
TELEGRAM_TOKEN = ""
TELEGRAM_CHAT_ID = ""
MAX_BACKUPS = 10   # số backup tối đa cho mỗi server
# ============================================

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
    "Accept": "application/json"
}

def send_telegram(message: str):
    """Gửi tin nhắn tới Telegram và kiểm tra kết quả."""
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    payload = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": message,
        "parse_mode": "Markdown"
    }
    try:
        response = requests.post(url, data=payload, timeout=15)
        response.raise_for_status()
        response_data = response.json()
        if not response_data.get("ok"):
            error_code = response_data.get('error_code')
            description = response_data.get('description')
            # In lỗi này ra vì nó quan trọng cho việc debug
            print(f"❌ Lỗi từ API Telegram: [{error_code}] {description}")
    except requests.exceptions.RequestException as e:
        print(f"❌ Lỗi mạng khi gửi Telegram: {e}")
    except Exception as e:
        print(f"❌ Lỗi không xác định khi gửi Telegram: {e}")

def get_servers():
    url = f"{PANEL_URL}/api/client"
    r = requests.get(url, headers=headers)
    r.raise_for_status()
    return r.json()["data"]

def get_backups(server_id):
    url = f"{PANEL_URL}/api/client/servers/{server_id}/backups"
    r = requests.get(url, headers=headers)
    r.raise_for_status()
    return r.json()["data"]

def delete_backup(server_id, backup_id):
    url = f"{PANEL_URL}/api/client/servers/{server_id}/backups/{backup_id}"
    r = requests.delete(url, headers=headers)
    r.raise_for_status()

def create_backup(server_id):
    timestamp = datetime.now().strftime("%H-%M_%d-%m-%Y")
    backup_name = f"Auto Backup {timestamp}"
    url = f"{PANEL_URL}/api/client/servers/{server_id}/backups"
    r = requests.post(url, headers=headers, json={"name": backup_name})
    r.raise_for_status()
    return r.json()["attributes"]

def main():
    try:
        servers = get_servers()
    except Exception as e:
        error_message = f"❌ Lỗi nghiêm trọng: Không thể lấy danh sách server.\nLý do: {e}"
        print(error_message) # Giữ lại lỗi nghiêm trọng
        send_telegram(error_message)
        sys.exit(1)

    for server in servers:
        server_id = server["attributes"]["identifier"]
        server_name = server["attributes"]["name"]
        try:
            backups = get_backups(server_id)
            if len(backups) >= MAX_BACKUPS:
                oldest = sorted(backups, key=lambda x: x["attributes"]["created_at"])[0]
                oldest_name = oldest['attributes']['name']
                oldest_uuid = oldest['attributes']['uuid']
                delete_backup(server_id, oldest_uuid)
                send_telegram(f"🗑️ Đã xóa backup cũ nhất của server *{server_name}*\n`{oldest_name}`")

            backup_info = create_backup(server_id)
            # **Đã xóa dòng kích thước khỏi thông báo này**
            send_telegram(
                f"✅ Backup thành công server *{server_name}*\n\n"
                f"📦 *Tên*: `{backup_info['name']}`"
            )

        except Exception as e:
            error_message = f"❌ Backup thất bại cho server *{server_name}*.\nLý do: {e}"
            print(error_message) # Giữ lại log lỗi cho từng server
            send_telegram(error_message)

if __name__ == "__main__":
    main()
