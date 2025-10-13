# ======================================================================================
# PHẦN TỰ ĐỘNG KIỂM TRA VÀ CÀI ĐẶT THƯ VIỆN
# ======================================================================================
import subprocess
import sys
import importlib.util
import json

def install_if_missing(package):
    if importlib.util.find_spec(package) is None:
        print(f"Thư viện {package} chưa được cài đặt. Đang tiến hành cài đặt...")
        try:
            subprocess.check_call([sys.executable, "-m", "pip", "install", package, "--quiet"])
            print(f"Cài đặt {package} thành công.")
        except subprocess.CalledProcessError:
            print(f"LỖI: Không thể cài đặt {package}. Vui lòng cài đặt thủ công."); sys.exit(1)

required_packages = ['requests', 'pystyle']
for pkg in required_packages:
    install_if_missing(pkg)

# ======================================================================================
# PHẦN CODE CHÍNH
# =====================================================================================
import requests
from time import sleep
from pystyle import *
import os
from datetime import datetime
import random

# Định nghĩa màu sắc
Defaut, Red, Green, Yellow, Blue, Purple, Cyan = "\033[0m", "\033[0;31m", "\033[0;32m", "\033[0;33m", "\033[0;34m", "\033[0;35m", "\033[0;36m"

def clear_terminal(): os.system('cls' if os.name == 'nt' else 'clear')
def animated_delay(duration, prefix=""):
    for i in range(duration, -1, -1):
        print(f'{Purple}{prefix} {Green}SLEEP {Red}[{i:02d}s]  ', end='\r'); sleep(1)
    print('                                        ', end='\r')

# --- Chức năng lưu và tải cấu hình ---
def save_config(data):
    with open('config_vipig.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def load_config():
    try:
        with open('config_vipig.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
            if 'vipig_user' in config: del config['vipig_user']
            if 'vipig_pass' in config: del config['vipig_pass']
            config.setdefault('vipig_token', '')
            config.setdefault('failure_threshold', 7)
            return config
    except (FileNotFoundError, json.JSONDecodeError):
        return {
            'vipig_token': '', 'ig_cookies': [], 'tasks': '12',
            'delay_between_tasks': 15, 'tasks_before_break': 20,
            'break_duration': 300, 'use_proxy': 'off', 'proxy_file': '',
            'failure_threshold': 7
        }

# --- API CLIENT CHO VIPIG.NET VỚI TOKEN ---
class VipIgClient:
    BASE_URL = "https://vipig.net"
    USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.63 Safari/537.36"

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({"User-Agent": self.USER_AGENT})

    def login_with_token(self, access_token):
        payload = {'access_token': access_token}
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        try:
            response = self.session.post(f"{self.BASE_URL}/logintoken.php", data=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
            if data.get("status") == "success":
                return True, data.get("data", {})
            else:
                return False, data.get("error", "Token không hợp lệ hoặc đã hết hạn")
        except (requests.RequestException, json.JSONDecodeError):
            return False, "Lỗi kết nối hoặc phản hồi từ server không hợp lệ"

    def set_active_account(self, ig_user_id):
        headers = {'X-Requested-With': 'XMLHttpRequest', 'Referer': f'{self.BASE_URL}/cauhinh/index.php'}
        self.session.post(f"{self.BASE_URL}/cauhinh/datnick.php", data={'iddat[]': ig_user_id}, headers=headers)

    def get_tasks(self, task_type):
        endpoint = 'subcheo/getpost.php' if task_type == 'sub' else 'getpost.php'
        referer = 'subcheo/' if task_type == 'sub' else ''
        headers = {'X-Requested-With': 'XMLHttpRequest', 'Referer': f'{self.BASE_URL}/kiemtien/{referer}'}
        try:
            return self.session.get(f"{self.BASE_URL}/kiemtien/{endpoint}", headers=headers).json()
        except (json.JSONDecodeError, requests.RequestException): return []

    def claim_follow_rewards(self, completed_ids):
        headers = {'X-Requested-With': 'XMLHttpRequest', 'Referer': f'{self.BASE_URL}/kiemtien/subcheo/'}
        try:
            return self.session.post(f"{self.BASE_URL}/kiemtien/subcheo/nhantien2.php", data={'id': ",".join(completed_ids)}, headers=headers).json()
        except json.JSONDecodeError: return {"error": "Lỗi nhận thưởng"}

    def claim_like_reward(self, completed_id):
        headers = {'X-Requested-With': 'XMLHttpRequest', 'Referer': f'{self.BASE_URL}/kiemtien/'}
        try:
            return self.session.post(f"{self.BASE_URL}/kiemtien/nhantien.php", data={'id': completed_id}, headers=headers).json()
        except json.JSONDecodeError: return {"error": "Lỗi nhận thưởng"}

# --- HÀM XỬ LÝ INSTAGRAM ---
def do_follow(cookies, idfl):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: print(f'{Red}Cookie lỗi{Defaut}'); return 0
    headers = {'authority': 'i.instagram.com', 'accept': '*/*', 'cookie': cookies, 'origin': 'https://www.instagram.com', 'user-agent': VipIgClient.USER_AGENT, 'x-csrftoken': token, 'x-ig-app-id': '936619743392459'}
    try:
        response = requests.post(f'https://i.instagram.com/api/v1/web/friendships/{idfl}/follow/', headers=headers, timeout=10).json()
        if response.get('status') == 'ok': print(f'{Green}SUCCESS ✔️'); return 1
        else: print(f'{Red}FAIL ❌'); return 0
    except Exception: return 0

def do_like(cookies, media_id):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: print(f'{Red}Cookie lỗi{Defaut}'); return 0
    headers = {'authority': 'www.instagram.com', 'accept': '*/*', 'cookie': cookies, 'origin': 'https://www.instagram.com', 'user-agent': VipIgClient.USER_AGENT, 'x-csrftoken': token}
    try:
        response = requests.post(f'https://www.instagram.com/api/v1/web/likes/{media_id}/like/', headers=headers, timeout=10)
        if response.status_code == 200 and 'ok' in response.json().get('status', ''): print(f'{Green}SUCCESS ✔️'); return 1
        else: print(f'{Red}FAIL ❌'); return 0
    except Exception: return 0

# --- MENU CẤU HÌNH ---
def get_configuration():
    config = load_config()
    while True:
        clear_terminal()
        token = config.get('vipig_token', '')
        
        # === [FIX] Căn chỉnh lại hiển thị menu ===
        print(f'{Cyan}--- TOOL VIPIG.NET (Đăng nhập bằng Token) ---{Defaut}')
        
        token_display = f"{Yellow}{token[:15]}...{Defaut}" if token else f"{Red}Chưa có{Defaut}"
        print(f" [Access Token VIPIG]: {token_display}")
        
        print(f" [Cookies IG]        : {Yellow}{len(config.get('ig_cookies', []))} tài khoản{Defaut}")
        print(f" [Cài đặt]           : Nhiệm vụ {Yellow}{config.get('tasks')}{Defaut}, Delay {Yellow}{config.get('delay_between_tasks')}s{Defaut}")
        print(f" [Ngưỡng Lỗi]       : {Yellow}{config.get('failure_threshold')} lần thất bại liên tiếp{Defaut}")
        print(f'{Cyan}--------------------------------------------------{Defaut}\n')
        
        print(f'{Green}[s] Bắt đầu chạy{Defaut}')
        print(f'{Yellow}[1] Cấu hình Access Token & Cookies IG{Defaut}')
        print(f'{Yellow}[2] Tùy chỉnh Nhiệm vụ, Delay & Ngưỡng Lỗi{Defaut}')
        print(f'{Red}[q] Thoát{Defaut}\n')
        
        choice = input(f'{Cyan}Nhập lựa chọn: {Red}').lower()
        if choice == '1':
            config['vipig_token'] = input(f'{Cyan}Nhập Access Token VIPIG: {Red}').strip()
            cookies = []
            if input(f'{Cyan}1. Nhập tay cookie IG\n2. Tải từ file\nLựa chọn: {Red}') == '1':
                while True:
                    cookie = input(f'{Cyan}Nhập cookie thứ {len(cookies) + 1} (Enter để kết thúc): {Red}')
                    if not cookie: break; cookies.append(cookie.strip())
            else:
                try:
                    with open(input(f'{Cyan}Nhập tên file: {Red}'), 'r') as f: cookies = [l.strip() for l in f if l.strip()]
                except FileNotFoundError: print(f"{Red}Lỗi: không tìm thấy file.")
            config['ig_cookies'] = cookies
        elif choice == '2':
            config['tasks'] = input(f'{Cyan}Chọn nhiệm vụ (1:Follow, 2:Like, 12:Cả hai): {Red}').strip()
            config['delay_between_tasks'] = int(input(f'{Cyan}Delay giữa các nhiệm vụ (giây): {Red}'))
            config['failure_threshold'] = int(input(f'{Cyan}Ngưỡng lỗi (thất bại liên tiếp): {Red}'))
        elif choice == 's':
            if not config.get('vipig_token') or not config.get('ig_cookies'):
                print(f"{Red}Lỗi: Access Token và Cookies IG không được để trống!"); sleep(2); continue
            save_config(config); return config
        elif choice == 'q': sys.exit()
        save_config(config)

# --- HÀM CHẠY CHÍNH ---
def job(config):
    client = VipIgClient()
    list_acc = config['ig_cookies']
    failure_threshold = config['failure_threshold']
    failure_counts = {i: 0 for i in range(len(list_acc))}
    
    print(f"{Yellow}Đang xác thực Access Token với VIPIG.net...{Defaut}")
    success, data = client.login_with_token(config['vipig_token'])
    if not success:
        print(f"{Red}Lỗi đăng nhập VIPIG: {data}"); sys.exit(1)

    clear_terminal()
    print(f'{Defaut}#===========================================================#')
    print(f'》   {Purple}Tài khoản VIPIG: {Red}{data.get("user")} | {Purple}Xu: {Red}{data.get("sodu")}')
    print(f'》   {Purple}Số tài khoản IG: {Red}{len(list_acc)}')
    print(f'》   {Purple}Ngưỡng lỗi: {Red}{failure_threshold} lần')
    print(f'{Defaut}#===========================================================#\n'); sleep(2)

    total_task_count = 0
    account_index = 0
    while list_acc:
        if account_index >= len(list_acc): account_index = 0
        current_cookie = list_acc[account_index]
        
        try:
            ds_user_id = current_cookie.split('ds_user_id=')[1].split(';')[0]
        except IndexError:
            list_acc.pop(account_index); config['ig_cookies'] = list_acc; save_config(config)
            failure_counts = {i: 0 for i in range(len(list_acc))}; continue

        print(f'\n{Purple}➤ ACC {account_index + 1}/{len(list_acc)} <> ID: {Green}{ds_user_id} | Đang đặt cấu hình...{Defaut}')
        client.set_active_account(ds_user_id)
        
        account_is_dead = False
        # FOLLOW
        if '1' in config['tasks']:
            while True:
                tasks = client.get_tasks('sub')
                if not tasks: print(f'{Green}Hết nhiệm vụ follow.{Defaut}'); break
                
                completed_follow_ids = []
                for task in tasks:
                    if len(completed_follow_ids) >= 6: break
                    total_task_count += 1
                    print(f'   [{total_task_count}] [{Yellow}FOLLOW{Defaut}] [{task["soID"]}] ', end='')
                    result = do_follow(current_cookie, task["soID"])
                    if result == 1:
                        failure_counts[account_index] = 0; completed_follow_ids.append(task["soID"])
                    else:
                        failure_counts[account_index] += 1
                    
                    if failure_counts.get(account_index, 0) >= failure_threshold:
                         account_is_dead=True; break
                    animated_delay(config['delay_between_tasks'])
                
                if completed_follow_ids:
                    reward_info = client.claim_follow_rewards(completed_follow_ids)
                    if 'mess' in reward_info: print(f"   {Green}↳ {reward_info['mess']}{Defaut}")
                
                if account_is_dead or not tasks: break

        # LIKE
        if '2' in config['tasks'] and not account_is_dead:
             while True:
                tasks = client.get_tasks('tym')
                if not tasks: print(f'{Green}Hết nhiệm vụ like.{Defaut}'); break
                for task in tasks:
                    total_task_count += 1
                    print(f'   [{total_task_count}] [{Cyan}LIKE{Defaut}] [{task["idpost"]}] ', end='')
                    result = do_like(current_cookie, task["mediaid"])
                    if result == 1:
                        failure_counts[account_index] = 0
                        reward_info = client.claim_like_reward(task["idpost"])
                        if 'mess' in reward_info: print(f"   {Green}↳ {reward_info['mess']}{Defaut}")
                    else:
                        failure_counts[account_index] += 1
                    
                    if failure_counts.get(account_index, 0) >= failure_threshold:
                         account_is_dead=True; break
                    animated_delay(config['delay_between_tasks'])
                if account_is_dead or not tasks: break

        if not account_is_dead: 
            account_index += 1
        else:
            print(f"{Red}CẢNH BÁO: Cookie tài khoản {ds_user_id} đã bị xóa do thất bại liên tiếp.{Defaut}")
            list_acc.pop(account_index); config['ig_cookies'] = list_acc; save_config(config)
            failure_counts = {i: 0 for i in range(len(list_acc))}

        if not list_acc: print(f"{Yellow}Đã hết cookie để chạy."); break
        print(f"\n{Cyan}Chuyển tài khoản tiếp theo...{Defaut}"); sleep(3)

if __name__ == "__main__":
    final_config = get_configuration()
    if final_config:
        job(final_config)
