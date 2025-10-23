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
            print(f"LỖI: Không thể cài đặt {package}. Vui lòng cài đặt thủ công.")
            sys.exit(1)

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

Defaut, Red, Green, Yellow, Blue, Purple, Cyan = "\033[0m", "\033[0;31m", "\033[0;32m", "\033[0;33m", "\033[0;34m", "\033[0;35m", "\033[0;36m"

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

def animated_delay(duration, prefix=""):
    for i in range(duration, -1, -1):
        print(f'{Purple}{prefix} {Green}SLEEP {Red}[{i:02d}s]  ', end='\r')
        sleep(1)
    print(' ' * 50, end='\r')

# --- Cấu hình ---
def save_config(data):
    with open('config_vipig.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def load_config():
    try:
        with open('config_vipig.json', 'r', encoding='utf-8') as f:
            config = json.load(f)
            config.setdefault('vipig_token', '')
            config.setdefault('stop_after_tasks', 0)
            config.setdefault('tasks_before_break', 20)
            config.setdefault('break_duration', 300)
            return config
    except (FileNotFoundError, json.JSONDecodeError):
        return {
            'vipig_token': '', 'ig_cookies': [], 'tasks': '12',
            'delay_between_tasks': 15, 'tasks_before_break': 20,
            'break_duration': 300, 'use_proxy': 'off', 'proxy_file': '',
            'stop_after_tasks': 0
        }

# --- VIPIG Client ---
class VipIgClient:
    USER_AGENT = "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Mobile Safari/537.36"
    BASE_URL = "https://vipig.net"

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": self.USER_AGENT,
            "Accept-Language": "vi-VN,vi;q=0.9",
        })
        self.POST_BASE_HEADERS = {
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': '*/*'
        }

    def login_with_token(self, access_token):
        payload = {'access_token': access_token}
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        try:
            response = self.session.post(f"{self.BASE_URL}/logintoken.php", data=payload, headers=headers)
            response.raise_for_status()
            data = response.json()
            if data.get("status") == "success":
                return True, data.get("data", {})
            return False, data.get("error", "Token không hợp lệ")
        except (requests.RequestException, json.JSONDecodeError):
            return False, "Lỗi kết nối hoặc phản hồi không hợp lệ"

    def set_active_account(self, ig_user_id):
        headers = self.POST_BASE_HEADERS.copy()
        headers['Referer'] = f'{self.BASE_URL}/cauhinh/index.php'
        self.session.post(f"{self.BASE_URL}/cauhinh/datnick.php", data={'iddat[]': ig_user_id}, headers=headers)

    def get_tasks(self, task_type):
        endpoint = 'subcheo/getpost.php' if task_type == 'sub' else 'getpost.php'
        referer_path = 'subcheo/' if task_type == 'sub' else ''
        headers = {
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': f'{self.BASE_URL}/kiemtien/{referer_path}',
            'Accept': 'application/json, text/javascript, */*; q=0.01'
        }
        try:
            response = self.session.get(f"{self.BASE_URL}/kiemtien/{endpoint}", headers=headers)
            return response.json()
        except (json.JSONDecodeError, requests.RequestException):
            return []

    # ================================================================
    # HÀM ĐÃ SỬA (THEO FILE PHP)
    # ================================================================
    def claim_follow_rewards(self, ids):
        # 1. Dọn dẹp danh sách ID
        ids_list = list({str(i).strip() for i in ids if i})
        if not ids_list:
            return {"error": "Không có ID hợp lệ để nhận thưởng"}

        # 2. SỬA LỖI PAYLOAD: Ghép thành string '1,2,3'
        # Dựa theo hàm hoanthanhsub() trong file PHP ($data= ('id=').$id;)
        payload_string = ','.join(ids_list)
        payload_data = {'id': payload_string} # Gửi dạng {'id': '1,2,3...'}
        
        headers = self.POST_BASE_HEADERS.copy()
        headers['Referer'] = f'{self.BASE_URL}/kiemtien/subcheo/'
        
        # 3. SỬA LỖI ENDPOINT: Thêm "2" vào "nhantien"
        # Dựa theo hàm hoanthanhsub() trong file PHP
        url = f"{self.BASE_URL}/kiemtien/subcheo/nhantien2.php"

        # 4. DEBUG LOG (Vẫn giữ lại)
        print(f"\n  {Purple}DEBUG: [CLAIM REWARD]{Defaut}")
        print(f"  {Purple}DEBUG: URL: {url}{Defaut}")
        print(f"  {Purple}DEBUG: Payload Gửi đi: {payload_data}{Defaut}")
        
        try:
            response = self.session.post(
                url, 
                data=payload_data, # Dùng payload đã sửa
                headers=headers,
                timeout=15
            )
            response.raise_for_status()
            
            print(f"  {Purple}DEBUG: Response Status: {response.status_code}{Defaut}")
            print(f"  {Purple}DEBUG: Response Raw Text: {response.text[:200].strip()}...{Defaut}")
            
            return response.json()
        
        except requests.HTTPError as http_err:
            print(f"  {Red}DEBUG: HTTP Error: {http_err}{Defaut}")
            print(f"  {Red}DEBUG: Response Text (Full): {response.text}{Defaut}")
            return {"error": f"Lỗi HTTP {response.status_code}: {response.text[:100]}"}
        except (requests.RequestException, json.JSONDecodeError) as e:
            print(f"  {Red}DEBUG: Request/JSON Error: {e}{Defaut}")
            # Thêm kiểm tra response.text để tránh lỗi nếu response rỗng
            if 'response' in locals() and response.text:
                 print(f"  {Red}DEBUG: Raw Text (Non-JSON): {response.text}{Defaut}")
            return {"error": f"Lỗi kết nối hoặc JSON: {e}"}
    # ================================================================

    def claim_like_reward(self, completed_id):
        headers = self.POST_BASE_HEADERS.copy()
        headers['Referer'] = f'{self.BASE_URL}/kiemtien/'
        
        # Logic này đã đúng theo file PHP (hàm hoanthanhtym)
        url = f"{self.BASE_URL}/kiemtien/nhantien.php"
        payload = {'id': completed_id}

        print(f"\n  {Purple}DEBUG: [CLAIM LIKE REWARD]{Defaut}")
        print(f"  {Purple}DEBUG: URL: {url}{Defaut}")
        print(f"  {Purple}DEBUG: Payload: {payload}{Defaut}")
        
        try:
            response = self.session.post(
                url,
                data=payload,
                headers=headers,
                timeout=15
            )
            response.raise_for_status()

            print(f"  {Purple}DEBUG: Response Status: {response.status_code}{Defaut}")
            print(f"  {Purple}DEBUG: Response Raw Text: {response.text[:200].strip()}...{Defaut}")
            
            return response.json()
            
        except requests.HTTPError as http_err:
            print(f"  {Red}DEBUG: HTTP Error (LIKE): {http_err}{Defaut}")
            print(f"  {Red}DEBUG: Response Text (Full): {response.text}{Defaut}")
            return {"error": f"Lỗi HTTP {response.status_code}: {response.text[:100]}"}
        except (requests.RequestException, json.JSONDecodeError) as e:
            print(f"  {Red}DEBUG: Request/JSON Error (LIKE): {e}{Defaut}")
            if 'response' in locals() and response.text:
                 print(f"  {Red}DEBUG: Raw Text (Non-JSON): {response.text}{Defaut}")
            return {"error": f"Lỗi nhận thưởng: {e}"}

# --- INSTAGRAM ---
def do_follow(cookies, idfl):
    try:
        token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError:
        return 0
    headers = {
        'authority': 'i.instagram.com',
        'cookie': cookies,
        'user-agent': VipIgClient.USER_AGENT,
        'x-csrftoken': token,
        'x-ig-app-id': '936619743392459'
    }
    try:
        response = requests.post(f'https://i.instagram.com/api/v1/web/friendships/{idfl}/follow/', headers=headers, timeout=10).json()
        if response.get('status') == 'ok':
            print(f'{Green}SUCCESS ✔️')
            return 1
        return 0
    except Exception:
        return 0

def do_like(cookies, media_id):
    try:
        token = cookies.split('csrftoken=')[1].split(';')[0]
    except IndexError:
        return 0
    headers = {
        'authority': 'www.instagram.com',
        'cookie': cookies,
        'user-agent': VipIgClient.USER_AGENT,
        'x-csrftoken': token
    }
    try:
        response = requests.post(f'https://www.instagram.com/api/v1/web/likes/{media_id}/like/', headers=headers, timeout=10)
        if response.status_code == 200 and 'ok' in response.json().get('status', ''):
            print(f'{Green}SUCCESS ✔️')
            return 1
        return 0
    except Exception:
        return 0

# --- MENU ---
def get_configuration():
    config = load_config()
    while True:
        clear_terminal()
        token = config.get('vipig_token', '')
        stop_after = config.get('stop_after_tasks', 0)
        print(f'{Cyan}--- TOOL VIPIG.NET (Đăng nhập bằng Token) ---{Defaut}')
        token_display = f"{Yellow}{token[:15]}...{Defaut}" if token else f"{Red}Chưa có{Defaut}"
        print(f" [Access Token VIPIG]: {token_display}")
        print(f" [Cookies IG]        : {Yellow}{len(config.get('ig_cookies', []))} tài khoản{Defaut}")
        print(f" [Cài đặt]           : Nhiệm vụ {Yellow}{config.get('tasks')}{Defaut}, Delay {Yellow}{config.get('delay_between_tasks')}s{Defaut}")
        print(f" [Nghỉ ngơi]         : {Yellow}Nghỉ {config.get('break_duration')}s sau mỗi {config.get('tasks_before_break')} nhiệm vụ{Defaut}")
        print(f" [Dừng tool]          : {Yellow}{'Chạy vô hạn' if stop_after == 0 else f'Dừng sau {stop_after} nhiệm vụ'}{Defaut}")
        print(f'{Cyan}--------------------------------------------------{Defaut}\n')
        
        print(f'{Green}[s] Bắt đầu chạy{Defaut}')
        print(f'{Yellow}[1] Cấu hình Access Token VIPIG{Defaut}')
        print(f'{Yellow}[2] Cấu hình Cookies Instagram{Defaut}')
        print(f'{Yellow}[3] Tùy chỉnh nhiệm vụ, delay, nghỉ & dừng tool{Defaut}')
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
                    with open(input(f'{Cyan}Nhập tên file: {Red}'), 'r') as f:
                        cookies = [l.strip() for l in f if l.strip()]
                except FileNotFoundError:
                    print(f"{Red}Lỗi: không tìm thấy file.")
            config['ig_cookies'] = cookies
        elif choice == '3':
            config['tasks'] = input(f'{Cyan}Chọn nhiệm vụ (1:Follow, 2:Like, 12:Cả hai): {Red}').strip()
            config['delay_between_tasks'] = int(input(f'{Cyan}Delay giữa các nhiệm vụ (giây): {Red}'))
            config['tasks_before_break'] = int(input(f'{Cyan}Sau bao nhiêu nhiệm vụ thì nghỉ?: {Red}'))
            config['break_duration'] = int(input(f'{Cyan}Thời gian nghỉ (giây): {Red}'))
            config['stop_after_tasks'] = int(input(f'{Cyan}Dừng hẳn sau bao nhiêu nhiệm vụ (nhập 0 để chạy vô hạn): {Red}'))
        elif choice == 's':
            if not config.get('vipig_token') or not config.get('ig_cookies'):
                print(f"{Red}Lỗi: Access Token và Cookies IG không được để trống!"); sleep(2); continue
            save_config(config)
            return config
        elif choice == 'q': sys.exit()
        save_config(config)

# --- HÀM CHẠY CHÍNH (Logic xử lý response đã có, không cần sửa) ---
def job(config):
    client = VipIgClient()
    list_acc = config['ig_cookies']
    stop_after_tasks = config.get('stop_after_tasks', 0)
    tasks_before_break = config.get('tasks_before_break', 20)
    break_duration = config.get('break_duration', 300)
    
    print(f"{Yellow}Đang xác thực Access Token...{Defaut}")
    success, data = client.login_with_token(config['vipig_token'])
    if not success:
        print(f"{Red}Lỗi đăng nhập: {data}")
        sys.exit(1)

    clear_terminal()
    print(f'{Defaut}#===========================================================#')
    print(f'》  {Purple}Tài khoản: {Red}{data.get("user")} | {Purple}Xu: {Red}{data.get("sodu")}')
    print(f'》  {Purple}Số tài khoản IG: {Red}{len(list_acc)}')
    if stop_after_tasks > 0: print(f'》  {Purple}Mục tiêu: {Red}{stop_after_tasks} nhiệm vụ')
    print(f'》  {Purple}Nghỉ {break_duration}s sau mỗi {tasks_before_break} nhiệm vụ')
    print(f'{Defaut}#===========================================================#\n'); sleep(2)

    total_task_count = 0
    account_index = 0
    job_since_break = 0
    
    while list_acc:
        if stop_after_tasks > 0 and total_task_count >= stop_after_tasks:
            print(f'{Green}Đã hoàn thành mục tiêu {total_task_count}/{stop_after_tasks} nhiệm vụ. Dừng tool!{Defaut}'); break
            
        if account_index >= len(list_acc): account_index = 0
        current_cookie = list_acc[account_index]
        
        try:
            ds_user_id = current_cookie.split('ds_user_id=')[1].split(';')[0]
        except IndexError:
            print(f"{Red}CẢNH BÁO: Cookie tại vị trí {account_index + 1} bị lỗi cấu trúc. Đã xóa.{Defaut}")
            list_acc.pop(account_index)
            config['ig_cookies'] = list_acc
            save_config(config)
            continue

        print(f'\n{Purple}➤ ACC {account_index + 1}/{len(list_acc)} <> ID: {Green}{ds_user_id} | Đang đặt cấu hình...{Defaut}')
        client.set_active_account(ds_user_id)
        
        accumulated_follow_ids = []

        job_types_to_run = []
        if '1' in config['tasks']: job_types_to_run.append({'name': 'FOLLOW', 'type': 'sub', 'color': Yellow})
        if '2' in config['tasks']: job_types_to_run.append({'name': 'LIKE', 'type': 'tym', 'color': Cyan})
        
        for job_info in job_types_to_run:
            while True:
                if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                
                tasks = client.get_tasks(job_info['type'])
                if not tasks: 
                    print(f'  {Green}Hết nhiệm vụ {job_info["name"]}.{Defaut}')
                    break
                
                for task in tasks:
                    if stop_after_tasks > 0 and total_task_count >= stop_after_tasks: break
                    
                    total_task_count += 1
                    job_since_break += 1
                    
                    task_id = task.get("soID") or task.get("idpost")
                    print(f'  [{total_task_count}] [{job_info["color"]}{job_info["name"]}{Defaut}] [{task_id}] ', end='')
                    
                    result = 0
                    if job_info['type'] == 'sub':
                        result = do_follow(current_cookie, task["soID"])
                        if result == 1:
                            accumulated_follow_ids.append(task["soID"])
                            # Logic nhận thưởng khi đủ 10
                            if len(accumulated_follow_ids) >= 10:
                                print(f"\n  {Cyan}Đạt 10 nhiệm vụ FOLLOW. Đang nhận thưởng...{Defaut}")
                                reward_info = client.claim_follow_rewards(accumulated_follow_ids)
                                current_time = datetime.now().strftime('%H:%M:%S')
                                
                                if 'mess' in reward_info: 
                                    print(f"  {Green}↳ {reward_info['mess']} | {Purple}{current_time}{Defaut}")
                                    if 'sodu' in reward_info:
                                        print(f"  {Cyan}  ↳ Số dư mới: {reward_info['sodu']} xu{Defaut}")
                                elif 'error' in reward_info:
                                    print(f"  {Red}↳ Lỗi: {reward_info['error']} | {Purple}{current_time}{Defaut}")
                                else:
                                    print(f"  {Yellow}↳ Phản hồi lạ: {reward_info} | {Purple}{current_time}{Defaut}")

                                accumulated_follow_ids = [] # Reset
                    
                    elif job_info['type'] == 'tym':
                        result = do_like(current_cookie, task["mediaid"])
                        if result == 1:
                            # Logic nhận thưởng LIKE (nhận ngay)
                            reward_info = client.claim_like_reward(task["idpost"])
                            current_time = datetime.now().strftime('%H:%M:%S')
                            if 'mess' in reward_info: 
                                print(f"  {Green}↳ {reward_info['mess']} | {Purple}{current_time}{Defaut}")
                                if 'sodu' in reward_info:
                                     print(f"  {Cyan}  ↳ Số dư mới: {reward_info['sodu']} xu{Defaut}")
                            elif 'error' in reward_info:
                                print(f"  {Red}↳ Lỗi: {reward_info['error']} | {Purple}{current_time}{Defaut}")

                    
                    # Logic nghỉ ngơi
                    if job_since_break >= tasks_before_break:
                        # Ưu tiên nhận nốt xu FOLLOW trước khi nghỉ
                        if accumulated_follow_ids:
                            print(f"\n  {Cyan}Đang nhận thưởng FOLLOW còn lại trước khi nghỉ ({len(accumulated_follow_ids)} job)...{Defaut}")
                            try:
                                reward_info = client.claim_follow_rewards(accumulated_follow_ids)
                                current_time = datetime.now().strftime('%H:%M:%S')
                                
                                if 'mess' in reward_info:
                                    print(f"  {Green}↳ {reward_info['mess']} | {Purple}{current_time}{Defaut}")
                                    if 'sodu' in reward_info:
                                        print(f"  {Cyan}  ↳ Số dư mới: {reward_info['sodu']} xu{Defaut}")
                                elif 'error' in reward_info:
                                    print(f"  {Red}↳ Lỗi: {reward_info['error']} | {Purple}{current_time}{Defaut}")

                            except Exception as e:
                                print(f"  {Red}Lỗi khi nhận thưởng FOLLOW: {e}{Defaut}")
                            accumulated_follow_ids = []

                        # Bắt đầu nghỉ
                        print(f"\n{Yellow}Đã hoàn thành {job_since_break} nhiệm vụ, nghỉ {break_duration}s để tránh checkpoint...{Defaut}")
                        animated_delay(break_duration, f"Tạm nghỉ")
                        job_since_break = 0 # Reset bộ đếm
                    else:
                        # Delay bình thường
                        animated_delay(config['delay_between_tasks'])
                
                if not tasks: break # Hết nhiệm vụ trong vòng lặp while
            
            # Hết nhiệm vụ (LIKE hoặc FOLLOW), nhận nốt xu FOLLOW nếu còn
            if job_info['type'] == 'sub' and accumulated_follow_ids:
                print(f"  {Cyan}Hết nhiệm vụ, nhận thưởng cho {len(accumulated_follow_ids)} job FOLLOW còn lại...{Defaut}")
                try:
                    reward_info = client.claim_follow_rewards(accumulated_follow_ids)
                    current_time = datetime.now().strftime('%H:%M:%S')
                    
                    if 'mess' in reward_info:
                        print(f"  {Green}↳ {reward_info['mess']} | {Purple}{current_time}{Defaut}")
                        if 'sodu' in reward_info:
                            print(f"  {Cyan}  ↳ Số dư mới: {reward_info['sodu']} xu{Defaut}")
                    elif 'error' in reward_info:
                        print(f"  {Red}↳ Lỗi: {reward_info['error']} | {Purple}{current_time}{Defaut}")

                except Exception as e:
                    print(f"  {Red}Lỗi khi nhận thưởng FOLLOW: {e}{Defaut}")
                accumulated_follow_ids = []

        account_index += 1
        
        if not list_acc: print(f"{Yellow}Đã hết cookie để chạy."); break
        if not (stop_after_tasks > 0 and total_task_count >= stop_after_tasks):
            print(f"\n{Cyan}Chuyển tài khoản tiếp theo...{Defaut}"); sleep(3)

if __name__ == "__main__":
    final_config = get_configuration()
    if final_config:
        job(final_config)
