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
    with open('config_tds.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def load_config():
    try:
        with open('config_tds.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
            config.setdefault('tds_token', '')
            config.setdefault('tasks', '12')
            config.setdefault('delay_between_tasks', 15)
            config.setdefault('tasks_before_break', 20)
            config.setdefault('break_duration', 300)
            config.setdefault('stop_after_tasks', 0)
            # Xóa key cũ nếu tồn tại
            if 'failure_threshold' in config:
                del config['failure_threshold']
            return config
    except (FileNotFoundError, json.JSONDecodeError):
        return {
            'tds_token': '', 'ig_cookies': [], 'tasks': '12',
            'delay_between_tasks': 15, 'tasks_before_break': 20,
            'break_duration': 300, 'stop_after_tasks': 0
        }

def safe_get_json(url):
    try:
        res = requests.get(url, timeout=15)
        res.raise_for_status()
        return res.json() if res.text.strip() else {}
    except (requests.RequestException, json.JSONDecodeError):
        return {}

# --- HÀM XỬ LÝ INSTAGRAM ---
def do_follow(cookies, idfl):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: return 0
    headers = {'authority': 'i.instagram.com', 'cookie': cookies, 'user-agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36', 'x-csrftoken': token, 'x-ig-app-id': '936619743392459'}
    try:
        response = requests.post(f'https://i.instagram.com/api/v1/web/friendships/{idfl}/follow/', headers=headers, timeout=10).json()
        if response.get('status') == 'ok': print(f'{Green}SUCCESS ✔️'); return 1
        return 0
    except Exception: return 0

def do_like(cookies, media_id):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: return 0
    headers = {'authority': 'www.instagram.com', 'cookie': cookies, 'user-agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36', 'x-csrftoken': token}
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
        token = config.get('tds_token', '')
        stop_after = config.get('stop_after_tasks', 0)
        
        print(f'{Cyan}--- TOOL TRAODOISUB.COM ---{Defaut}')
        print(f" [Token TDS]         : {Yellow}{token[:15]}...{Defaut}" if token else f"{Red}Chưa có{Defaut}")
        print(f" [Cookies IG]        : {Yellow}{len(config.get('ig_cookies', []))} tài khoản{Defaut}")
        print(f" [Cài đặt]           : Nhiệm vụ {Yellow}{config.get('tasks')}{Defaut}, Delay {Yellow}{config.get('delay_between_tasks')}s{Defaut}")
        print(f" [Nghỉ ngơi]         : {Yellow}Nghỉ {config.get('break_duration')}s sau mỗi {config.get('tasks_before_break')} nhiệm vụ{Defaut}")
        print(f" [Dừng tool]        : {Yellow}{'Chạy vô hạn' if stop_after == 0 else f'Dừng sau {stop_after} nhiệm vụ'}{Defaut}")
        print(f'{Cyan}--------------------------------------------------{Defaut}\n')
        
        print(f'{Green}[s] Bắt đầu chạy{Defaut}')
        print(f'{Yellow}[1] Cấu hình Token TDS{Defaut}')
        print(f'{Yellow}[2] Cấu hình Cookies Instagram{Defaut}')
        print(f'{Yellow}[3] Tùy chỉnh Nhiệm vụ, Delay & Dừng tool{Defaut}')
        print(f'{Red}[q] Thoát{Defaut}\n')
        
        choice = input(f'{Cyan}Nhập lựa chọn: {Red}').lower()
        if choice == '1':
            config['tds_token'] = input(f'{Cyan}Nhập Token TDS mới: {Red}').strip()
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
            config['tasks_before_break'] = int(input(f'{Cyan}Sau bao nhiêu nhiệm vụ thì nghỉ?: {Red}'))
            config['break_duration'] = int(input(f'{Cyan}Thời gian nghỉ (giây): {Red}'))
            config['stop_after_tasks'] = int(input(f'{Cyan}Dừng hẳn sau bao nhiêu nhiệm vụ (nhập 0 để chạy vô hạn): {Red}'))
        elif choice == 's':
            if not config.get('tds_token') or not config.get('ig_cookies'):
                print(f"{Red}Lỗi: Token TDS và Cookies IG không được để trống!"); sleep(2); continue
            save_config(config); return config
        elif choice == 'q': sys.exit()
        save_config(config)

# --- HÀM CHẠY CHÍNH ---
def job(config):
    token = config['tds_token']
    list_acc = config['ig_cookies']
    stop_after_tasks = config.get('stop_after_tasks', 0)
    tasks_before_break = config.get('tasks_before_break', 20)
    break_duration = config.get('break_duration', 300)
    
    login = safe_get_json(f'https://traodoisub.com/api/?fields=profile&access_token={token}')
    if 'data' not in login or 'user' not in login['data']:
        print(f"{Red}Lỗi Token TDS không hợp lệ!"); sys.exit(1)

    clear_terminal()
    print(f'{Defaut}#===========================================================#')
    print(f'》   {Purple}Tài khoản: {Red}{login["data"]["user"]} | {Purple}Xu: {Red}{login["data"]["xu"]}')
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
            print(f"{Red}Cookie #{account_index+1} không hợp lệ, bỏ qua...{Defaut}")
            account_index += 1; continue

        cauhinh = safe_get_json(f'https://traodoisub.com/api/?fields=instagram_run&id={ds_user_id}&access_token={token}')
        if 'data' not in cauhinh or 'msg' not in cauhinh['data']:
            print(f"{Red}Lỗi cấu hình ID {ds_user_id}. Chuyển acc...{Defaut}")
            account_index += 1; sleep(2); continue
            
        print(f'\n{Purple}➤ ACC {account_index + 1}/{len(list_acc)} <> ID: {Green}{ds_user_id} | {cauhinh["data"]["msg"]}{Defaut}')
        
        tasks_this_session = 0
        
        job_types_to_run = []
        if '1' in config['tasks']: job_types_to_run.append({'name': 'FOLLOW', 'type': 'instagram_follow', 'color': Yellow})
        if '2' in config['tasks']: job_types_to_run.append({'name': 'LIKE', 'type': 'instagram_like', 'color': Cyan})
        
        for job_info in job_types_to_run:
            while True:
                if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                tasks = safe_get_json(f'https://traodoisub.com/api/?fields={job_info["type"]}&access_token={token}').get('data', [])
                if not tasks: print(f'   {Green}Hết nhiệm vụ {job_info["name"]}.{Defaut}'); break
                
                for task in tasks:
                    if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                    
                    total_task_count += 1
                    tasks_this_session += 1
                    
                    task_id = task["id"]
                    print(f'   [{total_task_count}] [{job_info["color"]}{job_info["name"]}{Defaut}] [{task_id}] ', end='')
                    
                    result = 0
                    if job_info['name'] == 'FOLLOW':
                        result = do_follow(current_cookie, task_id.split('_')[0])
                    elif job_info['name'] == 'LIKE':
                        # Cần API để lấy media_id từ link, hiện tại chưa có
                        # Giả định tạm thời media_id là id
                        result = do_like(current_cookie, task_id.split('_')[0])

                    if result == 1:
                        # Gửi yêu cầu duyệt
                        type_cache = 'INS_FOLLOW_CACHE' if job_info['name'] == 'FOLLOW' else 'INS_LIKE_CACHE'
                        duyet = safe_get_json(f'https://traodoisub.com/api/coin/?type={type_cache}&id={task_id}&access_token={token}')
                        if 'data' in duyet: print(f"   {Green}↳ {duyet['data']['msg']}{Defaut}")
                        
                    animated_delay(config['delay_between_tasks'])
                    
                    if tasks_this_session > 0 and tasks_this_session % tasks_before_break == 0:
                        animated_delay(break_duration, f"Tạm nghỉ")
                
                if not tasks: break
        
        account_index += 1
        if not list_acc: print(f"{Yellow}Đã hết cookie để chạy."); break
        if not (stop_after_tasks > 0 and total_task_count >= stop_after_tasks):
            print(f"\n{Cyan}Chuyển tài khoản tiếp theo...{Defaut}"); sleep(3)

if __name__ == "__main__":
    # Chọn tool để chạy
    tool_choice = input(f"Chọn tool để chạy:\n1. VIPIG.net\n2. TraoDoiSub.com\nLựa chọn: ")
    if tool_choice == '1':
        final_config = get_configuration() # Gọi menu của VIPIG
        if final_config:
            job(final_config) # Chạy job của VIPIG
    elif tool_choice == '2':
        # Bạn cần tạo hàm get_configuration_tds() và job_tds() riêng
        # Hoặc sửa lại file này để chỉ chạy 1 trong 2
        print("Vui lòng chạy file riêng cho TraoDoiSub.")
        # Ví dụ:
        # final_config_tds = get_configuration_tds()
        # if final_config_tds:
        #     job_tds(final_config_tds)
    else:
        print("Lựa chọn không hợp lệ.")
