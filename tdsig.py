# ======================================================================================
# PHẦN TỰ ĐỘNG KIỂM TRA VÀ CÀI ĐẶT THƯ VIỆN (KHÔNG THAY ĐỔI)
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
    try:
        with open('config.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"{Red}Lỗi khi lưu cấu hình: {e}")

def load_config():
    try:
        with open('config.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
            # Đảm bảo các key mới tồn tại
            config.setdefault('failure_threshold', 7)
            return config
    except (FileNotFoundError, json.JSONDecodeError):
        return {
            'tds_token': '', 'ig_cookies': [], 'tasks': '12',
            'delay_between_tasks': 10, 'tasks_before_break': 20,
            'break_duration': 300, 'use_proxy': 'off', 'proxy_file': '',
            'failure_threshold': 7  # Ngưỡng lỗi mặc định
        }

def safe_get_json(url):
    try:
        res = requests.get(url, timeout=15)
        res.raise_for_status()
        return res.json() if res.text.strip() else {}
    except requests.exceptions.RequestException:
        return {}

# --- HÀM XỬ LÝ NHIỆM VỤ ---
def do_follow(cookies, idfl, uafake, proxie=None):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: print(f'{Red}Cookie lỗi{Defaut}'); return 0
    headers = {'authority': 'i.instagram.com', 'accept': '*/*', 'cookie': cookies, 'origin': 'https://www.instagram.com', 'user-agent': uafake, 'x-csrftoken': token, 'x-ig-app-id': '936619743392459'}
    proxies_config = {'http': f'http://{proxie}', 'https': f'http://{proxie}'} if proxie else None
    try:
        response = requests.post(f'https://i.instagram.com/api/v1/web/friendships/{idfl}/follow/', headers=headers, proxies=proxies_config, timeout=10).json()
        if response.get('status') == 'ok': print(f'{Green}SUCCESS ✔️'); return 1
        else: print(f'{Red}FAIL ❌'); return 0
    except Exception: return 0

def do_like(cookies, idlike, uafake, link, proxie=None):
    try: token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError: print(f'{Red}Cookie lỗi{Defaut}'); return 0
    headers = {'authority': 'www.instagram.com', 'accept': '*/*', 'cookie': cookies, 'origin': 'https://www.instagram.com', 'referer': link, 'user-agent': uafake, 'x-csrftoken': token}
    proxies_config = {'http': f'http://{proxie}', 'https': f'http://{proxie}'} if proxie else None
    try:
        response = requests.post(f'https://www.instagram.com/web/likes/{idlike}/like/', headers=headers, proxies=proxies_config, timeout=10)
        if response.status_code == 200 and 'ok' in response.json().get('status', ''): print(f'{Green}SUCCESS ✔️'); return 1
        else: print(f'{Red}FAIL ❌'); return 0
    except Exception: return 0

def claim_rewards(tokenn, task_type):
    job_id_for_claim = f"{task_type}_API"
    url = f'https://traodoisub.com/api/coin/?type={task_type}&id={job_id_for_claim}&access_token={tokenn}'
    response = safe_get_json(url)
    if response and 'data' in response and 'msg' in response['data']:
        print(f'{Blue}[NHẬN THƯỞỞNG] {Yellow}[{task_type}] {Green}➤ {response["data"]["msg"]}{Defaut}')

# --- MENU CẤU HÌNH ---
def get_configuration():
    config = load_config()
    while True:
        clear_terminal()
        print(f'{Cyan}--- CẤU HÌNH HIỆN TẠI ---{Defaut}')
        print(f" [Token TDS] : {Yellow}{config['tds_token'][:20]}...{Defaut}" if config['tds_token'] else f" [Token TDS] : {Red}Chưa có{Defaut}")
        print(f" [Cookies IG]: {Yellow}{len(config['ig_cookies'])} tài khoản{Defaut}")
        print(f" [Cài đặt]   : Nhiệm vụ {Yellow}{config['tasks']}{Defaut}, Delay {Yellow}{config['delay_between_tasks']}s{Defaut}, Nghỉ {Yellow}{config['break_duration']}s{Defaut} sau {Yellow}{config['tasks_before_break']}{Defaut} jobs")
        print(f" [Ngưỡng Lỗi]: {Yellow}{config['failure_threshold']} lần thất bại liên tiếp thì xóa cookie{Defaut}") # <--- HIỂN THỊ MỚI
        print(f" [Proxy]     : {Yellow if config['use_proxy'] == 'on' else Red}{config['use_proxy']}{Defaut} (File: {config['proxy_file']})")
        print(f'{Cyan}---------------------------{Defaut}\n')

        print(f'{Green}[s] Bắt đầu chạy với cấu hình trên{Defaut}')
        print(f'{Yellow}[1] Thay đổi Token TraoDoiSub{Defaut}')
        print(f'{Yellow}[2] Cập nhật danh sách Cookies Instagram{Defaut}')
        print(f'{Yellow}[3] Tùy chỉnh Nhiệm vụ, Delay & Ngưỡng Lỗi{Defaut}') # <--- THAY ĐỔI TÊN
        print(f'{Yellow}[4] Cấu hình Proxy{Defaut}')
        print(f'{Red}[q] Thoát chương trình{Defaut}\n')

        choice = input(f'{Cyan}Nhập lựa chọn của bạn: {Red}').lower()

        if choice == '1':
            config['tds_token'] = input(f'{Cyan}Nhập Token TDS mới: {Red}').strip()
        elif choice == '2':
            # ... (logic không đổi)
            cookies = []
            if input(f'{Cyan}1. Nhập tay\n2. Tải từ file\nLựa chọn: {Red}') == '1':
                while True:
                    cookie = input(f'{Cyan}Nhập cookie thứ {len(cookies) + 1} (Enter để kết thúc): {Red}')
                    if not cookie: break
                    cookies.append(cookie.strip())
            else:
                try:
                    with open(input(f'{Cyan}Nhập tên file: {Red}'), 'r') as f: cookies = [l.strip() for l in f if l.strip()]
                except FileNotFoundError: print(f"{Red}Lỗi: không tìm thấy file.")
            config['ig_cookies'] = cookies
        elif choice == '3': # <--- LOGIC ĐÃ GỘP
            print(f'{Purple}--- TÙY CHỈNH NHIỆM VỤ, DELAY & NGƯỠNG LỖI ---{Defaut}')
            config['tasks'] = input(f'{Cyan}Chọn nhiệm vụ (1:Follow, 2:Like, 12:Cả hai): {Red}').strip()
            config['delay_between_tasks'] = int(input(f'{Cyan}Delay giữa các nhiệm vụ (giây): {Red}'))
            config['tasks_before_break'] = int(input(f'{Cyan}Sau bao nhiêu nhiệm vụ thì nghỉ?: {Red}'))
            config['break_duration'] = int(input(f'{Cyan}Thời gian nghỉ (giây): {Red}'))
            config['failure_threshold'] = int(input(f'{Cyan}Ngưỡng lỗi (số lần thất bại liên tiếp để xóa cookie): {Red}')) # <--- CÀI ĐẶT MỚI
        elif choice == '4':
            config['use_proxy'] = input(f'{Cyan}Sử dụng proxy? (on/off): {Red}').lower()
            if config['use_proxy'] == 'on': config['proxy_file'] = input(f'{Cyan}Nhập tên file proxy: {Red}')
        elif choice == 's':
            if not config['tds_token'] or not config['ig_cookies']:
                print(f"{Red}Lỗi: Token TDS và Cookies Instagram không được để trống!"); sleep(2); continue
            save_config(config); return config
        elif choice == 'q': sys.exit()
        save_config(config)

def job(config):
    # Giải nén config và khởi tạo biến
    tokenn, list_acc, task_choice = config['tds_token'], config['ig_cookies'], config['tasks']
    delay, tasks_before_break, break_duration = config['delay_between_tasks'], config['tasks_before_break'], config['break_duration']
    failure_threshold = config['failure_threshold']
    
    # Khởi tạo bộ đếm lỗi
    failure_counts = {i: 0 for i in range(len(list_acc))}

    # ... (các phần kiểm tra login, tải proxy, ua không đổi)
    login = safe_get_json(f'https://traodoisub.com/api/?fields=profile&access_token={tokenn}')
    if 'data' not in login: print(f'{Red}➤ Sai TOKEN!'); sys.exit(1)
    clear_terminal()
    print(f'{Defaut}#===========================================================#')
    print(f'》   {Purple}Username TDS: {Red}{login["data"]["user"]} | {Purple}Xu: {Red}{login["data"]["xu"]}')
    print(f'》   {Purple}Số tài khoản IG: {Red}{len(list_acc)}')
    print(f'》   {Purple}Ngưỡng lỗi: {Red}{failure_threshold} lần')
    print(f'{Defaut}#===========================================================#\n')
    sleep(2)
    
    list_proxie, read_ua = [], []
    if config['use_proxy'].lower() == 'on':
        try:
            with open(config['proxy_file'], 'r') as f: list_proxie = [l.strip() for l in f if l.strip()]
        except FileNotFoundError: pass
    try:
        with open('ua.txt', 'r') as f: read_ua = [l.strip() for l in f if l.strip()]
    except FileNotFoundError: pass

    # Vòng lặp chính
    total_task_count = 0
    account_index = 0
    while list_acc: # Chạy khi nào vẫn còn cookie trong danh sách
        # Điều chỉnh account_index nếu nó vượt quá giới hạn sau khi xóa cookie
        if account_index >= len(list_acc):
            account_index = 0

        current_cookie = list_acc[account_index]
        tasks_this_session, account_is_dead = 0, False
        proxie = random.choice(list_proxie) if list_proxie else None
        uafake = random.choice(read_ua) if read_ua else 'Mozilla/5.0'

        try:
            ds_user_id = current_cookie.split('ds_user_id=')[1].split(';')[0]
        except IndexError:
            print(f"{Red}Lỗi: Cookie #{account_index + 1} không hợp lệ. Đang tự động xóa...");
            list_acc.pop(account_index)
            config['ig_cookies'] = list_acc
            save_config(config)
            failure_counts = {i: 0 for i in range(len(list_acc))} # Reset bộ đếm
            continue

        cauhinh = safe_get_json(f'https://traodoisub.com/api/?fields=instagram_run&id={ds_user_id}&access_token={tokenn}')
        if 'data' not in cauhinh:
            print(f"{Red}Cấu hình ID {ds_user_id} thất bại. Có thể do cookie. Chuyển acc.")
            account_index = (account_index + 1) % len(list_acc) if len(list_acc) > 0 else 0
            sleep(2)
            continue
        
        print(f'\n{Purple}➤ ACC {account_index + 1}/{len(list_acc)} <> Cấu hình ID: {Green}{ds_user_id}')

        # --- NHIỆM VỤ FOLLOW ---
        if '1' in task_choice and not account_is_dead:
            while True:
                job_list = safe_get_json(f'https://traodoisub.com/api/?fields=instagram_follow&access_token={tokenn}')
                if not job_list.get('data'):
                    print(f'{Green}Hết nhiệm vụ follow.{Defaut}'); claim_rewards(tokenn, 'INS_FOLLOW'); break
                for job_item in job_list['data']:
                    total_task_count += 1; tasks_this_session += 1
                    print(f'{Red}[{total_task_count}] [{datetime.now().strftime("%H:%M:%S")}] [{Yellow}FOLLOW{Red}] [{job_item["id"]}] ', end='')
                    result = do_follow(current_cookie, job_item['id'].split('_')[0], uafake, proxie)
                    
                    if result == 1:
                        failure_counts[account_index] = 0 # Reset bộ đếm khi thành công
                        safe_get_json(f'https://traodoisub.com/api/coin/?type=INS_FOLLOW_CACHE&id={job_item["id"]}&access_token={tokenn}')
                    else:
                        failure_counts[account_index] += 1 # Tăng bộ đếm khi thất bại
                        print(f"{Yellow}Thất bại liên tiếp: {failure_counts[account_index]}/{failure_threshold}")
                    
                    # Kiểm tra nếu tài khoản "chết"
                    if failure_counts.get(account_index, 0) >= failure_threshold:
                        print(f"{Red}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                        print(f"{Red}CẢNH BÁO: Cookie tài khoản {ds_user_id} đã bị xóa do thất bại {failure_threshold} lần liên tiếp.")
                        print(f"{Red}Lý do có thể: Bị chặn tương tác, checkpoint hoặc cookie hết hạn.")
                        print(f"{Red}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
                        list_acc.pop(account_index)
                        config['ig_cookies'] = list_acc
                        save_config(config)
                        failure_counts = {i: 0 for i in range(len(list_acc))} # Reset lại toàn bộ bộ đếm
                        account_is_dead = True
                        break

                    animated_delay(delay)
                    if tasks_this_session % tasks_before_break == 0:
                        animated_delay(break_duration, f"Tạm nghỉ"); claim_rewards(tokenn, 'INS_FOLLOW')
                
                if account_is_dead: break # Thoát vòng lặp while
                else: continue
            
        # --- (ÁP DỤNG TƯƠNG TỰ CHO NHIỆM VỤ LIKE) ---
        
        # Chuyển tài khoản
        if not account_is_dead: # Chỉ tăng index nếu không xóa tài khoản
             account_index += 1
        
        if not list_acc:
             print(f"{Yellow}Đã hết cookie để chạy. Dừng chương trình.")
             break

        print(f"\n{Cyan}Chuyển tài khoản tiếp theo...{Defaut}")
        sleep(3)

if __name__ == "__main__":
    final_config = get_configuration()
    if final_config:
        job(final_config)
