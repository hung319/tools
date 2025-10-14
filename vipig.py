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
            config.setdefault('vipig_token', '')
            config.setdefault('failure_threshold', 7)
            config.setdefault('stop_after_tasks', 0)
            # Thêm các key nghỉ giữa chừng nếu chưa có
            config.setdefault('tasks_before_break', 20)
            config.setdefault('break_duration', 300)
            return config
    except (FileNotFoundError, json.JSONDecodeError):
        return {
            'vipig_token': '', 'ig_cookies': [], 'tasks': '12',
            'delay_between_tasks': 15, 'tasks_before_break': 20,
            'break_duration': 300, 'use_proxy': 'off', 'proxy_file': '',
            'failure_threshold': 7, 'stop_after_tasks': 0
        }

# --- API CLIENT CHO VIPIG.NET ---
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
            if data.get("status") == "success": return True, data.get("data", {})
            else: return False, data.get("error", "Token không hợp lệ")
        except (requests.RequestException, json.JSONDecodeError):
            return False, "Lỗi kết nối hoặc phản hồi từ server không hợp lệ"
    
    def set_active_account(self, ig_user_id):
        headers = {'X-Requested-With': 'XMLHttpRequest'}
        self.session.post(f"{self.BASE_URL}/cauhinh/datnick.php", data={'iddat[]': ig_user_id}, headers=headers)

    def get_tasks(self, task_type):
        endpoint = 'subcheo/getpost.php' if task_type == 'sub' else 'getpost.php'
        headers = {'X-Requested-With': 'XMLHttpRequest'}
        try: return self.session.get(f"{self.BASE_URL}/kiemtien/{endpoint}", headers=headers).json()
        except (json.JSONDecodeError, requests.RequestException): return []

    def claim_follow_rewards(self, completed_ids):
        headers = {'X-Requested-With': 'XMLHttpRequest'}
        try: return self.session.post(f"{self.BASE_URL}/kiemtien/subcheo/nhantien2.php", data={'id': ",".join(completed_ids)}, headers=headers).json()
        except json.JSONDecodeError: return {"error": "Lỗi nhận thưởng"}

    def claim_like_reward(self, completed_id):
        headers = {'X-Requested-With': 'XMLHttpRequest'}
        try: return self.session.post(f"{self.BASE_URL}/kiemtien/nhantien.php", data={'id': completed_id}, headers=headers).json()
        except json.JSONDecodeError: return {"error": "Lỗi nhận thưởng"}

# --- HÀM XỬ LÝ INSTAGRAM ---
def do_follow(cookies, idfl):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: return 0
    headers = {'authority': 'i.instagram.com', 'cookie': cookies, 'user-agent': VipIgClient.USER_AGENT, 'x-csrftoken': token, 'x-ig-app-id': '936619743392459'}
    try:
        response = requests.post(f'https://i.instagram.com/api/v1/web/friendships/{idfl}/follow/', headers=headers, timeout=10).json()
        if response.get('status') == 'ok': print(f'{Green}SUCCESS ✔️'); return 1
        return 0
    except Exception: return 0

def do_like(cookies, media_id):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: return 0
    headers = {'authority': 'www.instagram.com', 'cookie': cookies, 'user-agent': VipIgClient.USER_AGENT, 'x-csrftoken': token}
    try:
        response = requests.post(f'https://www.instagram.com/api/v1/web/likes/{media_id}/like/', headers=headers, timeout=10)
        if response.status_code == 200 and 'ok' in response.json().get('status', ''): print(f'{Green}SUCCESS ✔️'); return 1
        return 0
    except Exception: return 0

# --- MENU CẤU HÌNH ---
def get_configuration():
    config = load_config()
    while True:
        clear_terminal()
        token = config.get('vipig_token', '')
        stop_after = config.get('stop_after_tasks', 0)
        
        print(f'{Cyan}--- TOOL VIPIG.NET (Đăng nhập bằng Token) ---{Defaut}')
        print(f" [Access Token VIPIG]: {Yellow}{token[:15]}...{Defaut}" if token else f"{Red}Chưa có{Defaut}")
        print(f" [Cookies IG]        : {Yellow}{len(config.get('ig_cookies', []))} tài khoản{Defaut}")
        print(f" [Cài đặt]           : Nhiệm vụ {Yellow}{config.get('tasks')}{Defaut}, Delay {Yellow}{config.get('delay_between_tasks')}s{Defaut}")
        print(f" [Nghỉ ngơi]         : {Yellow}Nghỉ {config.get('break_duration')}s sau mỗi {config.get('tasks_before_break')} nhiệm vụ{Defaut}")
        print(f" [Ngưỡng Lỗi]       : {Yellow}{config.get('failure_threshold')} lần thất bại liên tiếp{Defaut}")
        print(f" [Dừng tool]        : {Yellow}{'Chạy vô hạn' if stop_after == 0 else f'Dừng sau {stop_after} nhiệm vụ'}{Defaut}")
        print(f'{Cyan}--------------------------------------------------{Defaut}\n')
        
        print(f'{Green}[s] Bắt đầu chạy{Defaut}')
        print(f'{Yellow}[1] Cấu hình Access Token VIPIG{Defaut}')
        print(f'{Yellow}[2] Cấu hình Cookies Instagram{Defaut}')
        print(f'{Yellow}[3] Tùy chỉnh Nhiệm vụ, Delay, Nghỉ & Dừng tool{Defaut}')
        print(f'{Red}[q] Thoát{Defaut}\n')
        
        choice = input(f'{Cyan}Nhập lựa chọn: {Red}').lower()
        if choice == '1':
            config['vipig_token'] = input(f'{Cyan}Nhập Access Token VIPIG mới: {Red}').strip()
        elif choice == '2':
            cookies = []
            if input(f'{Cyan}1. Nhập tay cookie IG\n2. Tải từ file\nLựa chọn: {Red}') == '1':
                print(f'{Yellow}Nhập lần lượt từng cookie, nhấn Enter (bỏ trống) để kết thúc.{Defaut}')
                while True:
                    cookie = input(f'{Cyan}Nhập cookie thứ {len(cookies) + 1}: {Red}')
                    if not cookie: break
                    cookies.append(cookie.strip())
            else:
                try:
                    with open(input(f'{Cyan}Nhập tên file: {Red}'), 'r') as f: cookies = [l.strip() for l in f if l.strip()]
                except FileNotFoundError: print(f"{Red}Lỗi: không tìm thấy file.")
            config['ig_cookies'] = cookies
        elif choice == '3':
            config['tasks'] = input(f'{Cyan}Chọn nhiệm vụ (1:Follow, 2:Like, 12:Cả hai): {Red}').strip()
            config['delay_between_tasks'] = int(input(f'{Cyan}Delay giữa các nhiệm vụ (giây): {Red}'))
            # === [MỚI] Thêm câu hỏi cho tính năng nghỉ ngơi ===
            config['tasks_before_break'] = int(input(f'{Cyan}Sau bao nhiêu nhiệm vụ thì nghỉ?: {Red}'))
            config['break_duration'] = int(input(f'{Cyan}Thời gian nghỉ (giây): {Red}'))
            config['failure_threshold'] = int(input(f'{Cyan}Ngưỡng lỗi (thất bại liên tiếp): {Red}'))
            config['stop_after_tasks'] = int(input(f'{Cyan}Dừng hẳn sau bao nhiêu nhiệm vụ (nhập 0 để chạy vô hạn): {Red}'))
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
    stop_after_tasks = config.get('stop_after_tasks', 0)
    tasks_before_break = config.get('tasks_before_break', 20)
    break_duration = config.get('break_duration', 300)
    failure_counts = {i: 0 for i in range(len(list_acc))}
    
    print(f"{Yellow}Đang xác thực Access Token...{Defaut}")
    success, data = client.login_with_token(config['vipig_token'])
    if not success: print(f"{Red}Lỗi đăng nhập: {data}"); sys.exit(1)

    clear_terminal()
    print(f'{Defaut}#===========================================================#')
    print(f'》   {Purple}Tài khoản: {Red}{data.get("user")} | {Purple}Xu: {Red}{data.get("sodu")}')
    print(f'》   {Purple}Số tài khoản IG: {Red}{len(list_acc)}')
    if stop_after_tasks > 0: print(f'》   {Purple}Mục tiêu: {Red}{stop_after_tasks} nhiệm vụ')
    print(f'》   {Purple}Nghỉ {break_duration}s sau mỗi {tasks_before_break} nhiệm vụ')
    print(f'{Defaut}#===========================================================#\n'); sleep(2)

    total_task_count = 0
    account_index = 0
    while list_acc:
        if stop_after_tasks > 0 and total_task_count >= stop_after_tasks:
            print(f'{Green}Đã hoàn thành mục tiêu {total_task_count}/{stop_after_tasks} nhiệm vụ. Dừng tool!{Defaut}'); break
            
        if account_index >= len(list_acc): account_index = 0
        current_cookie = list_acc[account_index]
        
        try: ds_user_id = current_cookie.split('ds_user_id=')[1].split(';')[0]
        except IndexError:
            list_acc.pop(account_index); config['ig_cookies'] = list_acc; save_config(config); continue

        print(f'\n{Purple}➤ ACC {account_index + 1}/{len(list_acc)} <> ID: {Green}{ds_user_id} | Đang đặt cấu hình...{Defaut}')
        client.set_active_account(ds_user_id)
        
        account_is_dead = False
        tasks_this_session = 0 # Bộ đếm nhiệm vụ cho phiên nghỉ ngơi
        
        # LOGIC CHẠY NHIỆM VỤ
        job_types_to_run = []
        if '1' in config['tasks']: job_types_to_run.append({'name': 'FOLLOW', 'type': 'sub', 'color': Yellow})
        if '2' in config['tasks']: job_types_to_run.append({'name': 'LIKE', 'type': 'tym', 'color': Cyan})
        
        for job_info in job_types_to_run:
            if account_is_dead: break
            while True:
                if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                tasks = client.get_tasks(job_info['type'])
                if not tasks: print(f'   {Green}Hết nhiệm vụ {job_info["name"]}.{Defaut}'); break
                
                completed_follow_ids = []
                for task in tasks:
                    if job_info['type'] == 'sub' and len(completed_follow_ids) >= 6: break
                    if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                    
                    total_task_count += 1
                    tasks_this_session += 1
                    
                    task_id = task.get("soID") or task.get("idpost")
                    print(f'   [{total_task_count}] [{job_info["color"]}{job_info["name"]}{Defaut}] [{task_id}] ', end='')
                    
                    result = 0
                    if job_info['type'] == 'sub':
                        result = do_follow(current_cookie, task["soID"])
                        if result == 1: completed_follow_ids.append(task["soID"])
                    elif job_info['type'] == 'tym':
                        result = do_like(current_cookie, task["mediaid"])
                        if result == 1:
                            reward_info = client.claim_like_reward(task["idpost"])
                            if 'mess' in reward_info: print(f"   {Green}↳ {reward_info['mess']}{Defaut}")

                    if result == 1: failure_counts[account_index] = 0
                    else: failure_counts[account_index] = failure_counts.get(account_index, 0) + 1
                    
                    if failure_counts.get(account_index, 0) >= failure_threshold:
                         account_is_dead=True; break
                    
                    animated_delay(config['delay_between_tasks'])
                    
                    # === [MỚI] Logic nghỉ giữa chừng ===
                    if tasks_this_session > 0 and tasks_this_session % tasks_before_break == 0:
                        animated_delay(break_duration, f"Tạm nghỉ")

                if job_info['type'] == 'sub' and completed_follow_ids:
                    reward_info = client.claim_follow_rewards(completed_follow_ids)
                    if 'mess' in reward_info: print(f"   {Green}↳ {reward_info['mess']}{Defaut}")
                
                if account_is_dead or not tasks: break

        if not account_is_dead: account_index += 1
        else:
            print(f"{Red}CẢNH BÁO: Cookie tài khoản {ds_user_id} đã bị xóa do thất bại liên tiếp.{Defaut}")
            list_acc.pop(account_index); config['ig_cookies'] = list_acc; save_config(config)

        if not list_acc: print(f"{Yellow}Đã hết cookie để chạy."); break
        if not (stop_after_tasks > 0 and total_task_count >= stop_after_tasks):
            print(f"\n{Cyan}Chuyển tài khoản tiếp theo...{Defaut}"); sleep(3)

if __name__ == "__main__":
    final_config = get_configuration()
    if final_config:
        job(final_config)
