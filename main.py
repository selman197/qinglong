import os, sys, time
from typing import List
from PIL import Image
import pytesseract
import requests

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

USERNAME_SELECTOR = os.getenv("USERNAME_SELECTOR", "input#username")
PASSWORD_SELECTOR = os.getenv("PASSWORD_SELECTOR", "input#password")
SUBMIT_SELECTOR = os.getenv("SUBMIT_SELECTOR", "button#login")
CAPTCHA_SELECTOR = os.getenv("CAPTCHA_SELECTOR", "img#captcha")
CAPTCHA_INPUT_SELECTOR = os.getenv("CAPTCHA_INPUT_SELECTOR", "#captcha-input")

HEADLESS = os.getenv("HEADLESS", "1") == "1"
WECHAT_WEBHOOK = os.getenv("WECHAT_WEBHOOK", "").strip()

def send_wechat(content: str):
if not WECHAT_WEBHOOK:
print("[INFO] WECHAT_WEBHOOK not set, skip push")
return
try:
resp = requests.post(
WECHAT_WEBHOOK,
json={"msgtype":"text","text":{"content":content}},
timeout=15
)
print(f"[WECHAT] status={resp.status_code}, resp={resp.text[:200]}")
except Exception as e:
print(f"[WARN] WeChat push failed: {e}")

def solve_captcha(element, site_name: str) -> str:
path = f"/data/output/{site_name}_captcha.png"
element.screenshot(path)
print(f"[{site_name}] captcha saved: {path}")
try:
img = Image.open(path)
code = pytesseract.image_to_string(img, config='--psm 8 --oem 3').strip()
print(f"[{site_name}] OCR result: {code}")
return code
except Exception as e:
print(f"[{site_name}] OCR failed: {e}")
return ""

def build_driver() -> webdriver.Chrome:
opts = Options()
if HEADLESS:
opts.add_argument("--headless=new")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-dev-shm-usage")
opts.add_argument("--disable-gpu")
os.makedirs("/data/profile", exist_ok=True)
opts.add_argument("--user-data-dir=/data/profile")
if os.getenv("ENABLE_REMOTE_DEBUG", "0") == "1":
opts.add_argument("--remote-debugging-port=9222")
chrome_path = os.getenv("CHROME_BINARY", "/usr/bin/google-chrome")
if chrome_path:
opts.binary_location = chrome_path
driver = webdriver.Chrome(options=opts)
driver.set_page_load_timeout(int(os.getenv("PAGE_LOAD_TIMEOUT", "60")))
return driver

def split_lines_env(key: str) -> List[str]:
raw = os.getenv(key, "")
return [s for s in raw.split("\n") if s.strip()]

def process_site(driver: webdriver.Chrome, idx: int,
login_url: str, target_url: str, username: str, password: str):
site_name = f"site{idx+1}"
print(f"[{site_name}] Login URL: {login_url}")
wait = WebDriverWait(driver, int(os.getenv("WAIT_TIMEOUT", "20")))
driver.get(login_url)

wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, USERNAME_SELECTOR))).send_keys(username)
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, PASSWORD_SELECTOR))).send_keys(password)

if CAPTCHA_SELECTOR:
elems = driver.find_elements(By.CSS_SELECTOR, CAPTCHA_SELECTOR)
if elems:
print(f"[{site_name}] captcha detected, OCR...")
code = solve_captcha(elems[0], site_name)
if code and CAPTCHA_INPUT_SELECTOR:
try:
wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, CAPTCHA_INPUT_SELECTOR))).send_keys(code)
except Exception as e:
print(f"[{site_name}] captcha input not found: {e}")

wait.until(EC.element_to_be_clickable((By.CSS_SELECTOR, SUBMIT_SELECTOR))).click()
time.sleep(int(os.getenv("POST_LOGIN_SLEEP", "5")))

print(f"[{site_name}] Target URL: {target_url}")
driver.get(target_url)
time.sleep(int(os.getenv("TARGET_SLEEP", "3")))
os.makedirs("/data/output", exist_ok=True)
shot = f"/data/output/{site_name}_page.png"
driver.save_screenshot(shot)
print(f"[{site_name}] Screenshot saved: {shot}")
send_wechat(f"{site_name} OK -> {target_url}\nshot: {shot}")

def main():
login_urls = split_lines_env("LOGIN_URLS")
target_urls = split_lines_env("TARGET_URLS")
usernames = split_lines_env("USERNAMES")
passwords = split_lines_env("PASSWORDS")

n = max(len(login_urls), len(target_urls), len(usernames), len(passwords))
if not all(len(lst) == n for lst in [login_urls, target_urls, usernames, passwords]):
print("[ERROR] Env lines mismatch. Please ensure LOGIN_URLS, TARGET_URLS, USERNAMES, PASSWORDS have the same line count.")
send_wechat("Task failed: env lines mismatch.")
sys.exit(1)

driver = build_driver()
try:
for i in range(n):
try:
process_site(driver, i, login_urls[i], target_urls[i], usernames[i], passwords[i])
except Exception as e:
print(f"[ERROR] {e}")
send_wechat(f"Task failed on site{i+1}: {e}")
finally:
driver.quit()

if __name__ == "__main__":
main()
