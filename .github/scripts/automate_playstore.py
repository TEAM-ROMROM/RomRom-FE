#!/usr/bin/env python3
"""
automate_playstore.py

Google Play Console 브라우저 자동화 스크립트
Selenium을 사용하여 Draft 릴리즈를 자동으로 출시합니다.

사용 예:
  python3 automate_playstore.py \
    --email "your-email@gmail.com" \
    --password "your-password" \
    --developer-id "4736601601401567973" \
    --app-id "4972112751122062243"
"""

import argparse
import os
import sys
import time
from typing import List, Optional

# Selenium imports
try:
    from selenium import webdriver
    from selenium.webdriver.common.by import By
    from selenium.webdriver.support.ui import WebDriverWait
    from selenium.webdriver.support import expected_conditions as EC
    from selenium.webdriver.chrome.options import Options
    from selenium.common.exceptions import TimeoutException, NoSuchElementException
    from selenium.webdriver.chrome.service import Service
except ImportError:
    print("❌ 필요한 패키지가 설치되지 않았습니다.")
    print("다음 명령어로 설치하세요:")
    print("  pip install selenium")
    sys.exit(1)

# Undetected ChromeDriver (optional, fallback to standard webdriver)
try:
    import undetected_chromedriver as uc
    UNDETECTED_AVAILABLE = True
except ImportError:
    UNDETECTED_AVAILABLE = False
    print("⚠️  undetected-chromedriver를 사용할 수 없습니다. 표준 webdriver를 사용합니다.")
    print("   Google 로그인 시 CAPTCHA가 나타날 수 있습니다.")
    print("   설치: pip install undetected-chromedriver")


# ----------------------------- 상수 정의 -----------------------------

# URL 템플릿
GOOGLE_LOGIN_URL = "https://accounts.google.com"
PLAY_CONSOLE_INTERNAL_TESTING_URL = "https://play.google.com/console/u/0/developers/{developer_id}/app/{app_id}/tracks/internal-testing?tab=releases"

# 기본 대기 시간 (초)
DEFAULT_WAIT_TIME = 30
PAGE_LOAD_TIMEOUT = 60

# 스크린샷 디렉토리
SCREENSHOT_DIR = "screenshots"


# ----------------------------- 헬퍼 함수 -----------------------------

def log_info(message: str) -> None:
    """정보 로그 출력"""
    print(f"ℹ️  {message}")


def log_success(message: str) -> None:
    """성공 로그 출력"""
    print(f"✅ {message}")


def log_error(message: str) -> None:
    """에러 로그 출력"""
    print(f"❌ {message}")


def log_debug(message: str, debug: bool = False) -> None:
    """디버그 로그 출력"""
    if debug:
        print(f"🔍 {message}")


def ensure_screenshot_dir() -> None:
    """스크린샷 디렉토리 생성"""
    if not os.path.exists(SCREENSHOT_DIR):
        os.makedirs(SCREENSHOT_DIR)


def take_screenshot(driver: webdriver.Chrome, filename: str, debug: bool = False) -> None:
    """스크린샷 저장"""
    if not debug:
        return
    
    try:
        ensure_screenshot_dir()
        filepath = os.path.join(SCREENSHOT_DIR, filename)
        driver.save_screenshot(filepath)
        log_debug(f"스크린샷 저장: {filepath}", debug)
    except Exception as e:
        log_error(f"스크린샷 저장 실패: {e}")


def wait_for_page_load(driver: webdriver.Chrome, wait_time: int = DEFAULT_WAIT_TIME) -> None:
    """페이지 로딩 완료 대기 (document.readyState == 'complete')"""
    try:
        WebDriverWait(driver, wait_time).until(
            lambda d: d.execute_script("return document.readyState") == "complete"
        )
        log_debug(f"페이지 로딩 완료", True)
    except TimeoutException:
        log_error("페이지 로딩 타임아웃")


def wait_for_angular_load(driver: webdriver.Chrome, wait_time: int = DEFAULT_WAIT_TIME) -> None:
    """Angular 앱 로딩 완료 대기"""
    try:
        # Angular 앱이 로드될 때까지 대기
        WebDriverWait(driver, wait_time).until(
            lambda d: d.execute_script(
                "return typeof window.getAllAngularTestabilities === 'undefined' || "
                "window.getAllAngularTestabilities().findIndex(x => !x.isStable()) === -1"
            )
        )
        log_debug("Angular 앱 로딩 완료", True)
    except:
        # Angular 확인 실패해도 계속 진행
        log_debug("Angular 확인 실패 (일반 페이지로 간주)", True)


def wait_and_click(
    driver: webdriver.Chrome,
    selectors: List[str],
    wait_time: int,
    description: str,
    debug: bool = False
) -> bool:
    """
    여러 Selector를 시도하여 요소를 찾고 클릭
    
    Args:
        driver: WebDriver 인스턴스
        selectors: 시도할 Selector 리스트 (우선순위 순)
        wait_time: 대기 시간 (초)
        description: 버튼 설명
        debug: 디버그 모드
    
    Returns:
        성공 여부
    """
    log_info(f"🔍 {description} 버튼 찾는 중...")
    
    for idx, selector in enumerate(selectors):
        try:
            log_debug(f"Selector {idx+1}/{len(selectors)} 시도: {selector}", debug)
            
            # CSS Selector
            if selector.startswith("//"):
                # XPath
                element = WebDriverWait(driver, wait_time).until(
                    EC.element_to_be_clickable((By.XPATH, selector))
                )
            else:
                # CSS Selector
                element = WebDriverWait(driver, wait_time).until(
                    EC.element_to_be_clickable((By.CSS_SELECTOR, selector))
                )
            
            log_debug(f"요소 발견: {selector}", debug)
            take_screenshot(driver, f"before_click_{description.replace(' ', '_')}.png", debug)
            
            # 클릭 시도
            try:
                element.click()
            except:
                # JavaScript 클릭 시도
                driver.execute_script("arguments[0].click();", element)
            
            log_success(f"{description} 버튼 클릭 완료")
            take_screenshot(driver, f"after_click_{description.replace(' ', '_')}.png", debug)
            
            # 클릭 후 페이지 로딩 대기
            time.sleep(2)
            wait_for_page_load(driver, wait_time)
            wait_for_angular_load(driver, wait_time)
            
            return True
            
        except TimeoutException:
            log_debug(f"Selector {idx+1} 타임아웃", debug)
            continue
        except Exception as e:
            log_debug(f"Selector {idx+1} 오류: {e}", debug)
            continue
    
    # 모든 Selector 실패
    log_error(f"{description} 버튼을 찾을 수 없습니다")
    take_screenshot(driver, f"error_{description.replace(' ', '_')}.png", debug)
    return False


# ----------------------------- 메인 로직 -----------------------------

def setup_chrome_driver(headless: bool = True, debug: bool = False) -> webdriver.Chrome:
    """Chrome WebDriver 설정 및 초기화"""
    log_info("Chrome WebDriver 설정 중...")
    
    # ChromeDriver 경로 확인 (환경 변수 또는 시스템 PATH)
    chromedriver_path = os.environ.get('CHROMEDRIVER_PATH', None)
    
    # Undetected ChromeDriver 사용 시도
    if UNDETECTED_AVAILABLE:
        log_info("🔓 Undetected ChromeDriver 사용 (CAPTCHA 우회)")
        
        options = uc.ChromeOptions()
        
        # 헤드리스 모드
        if headless:
            options.add_argument("--headless=new")
            log_info("헤드리스 모드 활성화")
        
        # 기본 옵션
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1920,1080")
        
        # User-Agent (실제 Chrome과 동일하게)
        options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36")
        
        try:
            # undetected_chromedriver로 드라이버 생성
            driver = uc.Chrome(
                options=options,
                driver_executable_path=chromedriver_path,
                version_main=None,  # 자동 버전 감지
                use_subprocess=False
            )
            log_debug(f"ChromeDriver 경로: {chromedriver_path or '자동 감지'}", debug)
            
        except Exception as e:
            log_error(f"Undetected ChromeDriver 초기화 실패: {e}")
            log_error("ChromeDriver가 설치되어 있고 PATH에 있는지 확인하세요.")
            sys.exit(1)
    
    else:
        # 표준 Selenium WebDriver 사용 (Fallback)
        log_info("⚠️  표준 Selenium WebDriver 사용 (CAPTCHA 발생 가능)")
        
        options = Options()
        
        # 헤드리스 모드
        if headless:
            options.add_argument("--headless=new")
            log_info("헤드리스 모드 활성화")
        
        # 기본 옵션
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1920,1080")
        options.add_argument("--disable-blink-features=AutomationControlled")
        options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36")
        
        # 자동화 감지 방지
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option("useAutomationExtension", False)
        
        try:
            if chromedriver_path:
                service = Service(executable_path=chromedriver_path)
                driver = webdriver.Chrome(service=service, options=options)
            else:
                driver = webdriver.Chrome(options=options)
            
            log_debug(f"ChromeDriver 경로: {chromedriver_path or '시스템 PATH'}", debug)
            
            # 자동화 감지 방지 스크립트 (표준 WebDriver용)
            driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
            
        except Exception as e:
            log_error(f"ChromeDriver 초기화 실패: {e}")
            log_error("ChromeDriver가 설치되어 있고 PATH에 있는지 확인하세요.")
            sys.exit(1)
    
    # 타임아웃 설정
    driver.set_page_load_timeout(PAGE_LOAD_TIMEOUT)
    
    log_success("Chrome WebDriver 설정 완료")
    return driver


def google_login(
    driver: webdriver.Chrome,
    email: str,
    password: str,
    wait_time: int = DEFAULT_WAIT_TIME,
    debug: bool = False
) -> bool:
    """
    Google 계정 로그인
    
    Args:
        driver: WebDriver 인스턴스
        email: Google 계정 이메일
        password: Google 계정 비밀번호
        wait_time: 대기 시간
        debug: 디버그 모드
    
    Returns:
        로그인 성공 여부
    """
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info("🔐 Google 로그인 시작")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    try:
        # Google 로그인 페이지 접속
        log_info("Google 로그인 페이지 접속 중...")
        driver.get(GOOGLE_LOGIN_URL)
        wait_for_page_load(driver, wait_time)
        take_screenshot(driver, "01_google_login_page.png", debug)
        
        # 이메일 입력
        log_info("이메일 입력 중...")
        email_selectors = [
            "input[type='email']",
            "input#identifierId",
            "input[name='identifier']"
        ]
        
        for selector in email_selectors:
            try:
                email_input = WebDriverWait(driver, wait_time).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                )
                email_input.clear()
                email_input.send_keys(email)
                log_success("이메일 입력 완료")
                break
            except:
                continue
        else:
            log_error("이메일 입력란을 찾을 수 없습니다")
            return False
        
        take_screenshot(driver, "02_email_entered.png", debug)
        
        # "다음" 버튼 클릭 (이메일)
        next_button_selectors = [
            "button#identifierNext",
            "button[jsname='LgbsSe'][type='button']",
            "//button[.//span[contains(text(), '다음')]]",
            "//button[.//span[text()='Next']]",
            "button[type='button']"
        ]
        
        if not wait_and_click(driver, next_button_selectors, wait_time, "이메일 다음", debug):
            return False
        
        time.sleep(3)  # 페이지 전환 대기 시간 증가
        take_screenshot(driver, "03_after_email_next.png", debug)
        
        # 비밀번호 페이지 완전 로딩 대기
        log_debug("비밀번호 페이지 로딩 대기 중...", debug)
        time.sleep(2)
        wait_for_page_load(driver, wait_time)
        
        # 비밀번호 입력
        log_info("비밀번호 입력 중...")
        password_selectors = [
            "input[name='Passwd']",  # Google의 실제 name 속성
            "input[type='password'][name='Passwd']",
            "input[type='password'][autocomplete='current-password']",
            "input[jsname='YPqjbf'][type='password']",
            "input.whsOnd.zHQkBf[type='password']",
            "input[type='password']",
            "input[name='password']",
            "input#password"
        ]
        
        for selector in password_selectors:
            try:
                password_input = WebDriverWait(driver, wait_time).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                )
                password_input.clear()
                password_input.send_keys(password)
                log_success("비밀번호 입력 완료")
                break
            except:
                continue
        else:
            log_error("비밀번호 입력란을 찾을 수 없습니다")
            log_error(f"현재 URL: {driver.current_url}")
            log_error("가능한 원인:")
            log_error("  1. 2FA가 활성화되어 있음")
            log_error("  2. Google이 로그인 페이지 구조를 변경함")
            log_error("  3. 네트워크 지연으로 페이지 로딩 미완료")
            if debug:
                try:
                    ensure_screenshot_dir()
                    with open("screenshots/password_page_source.html", "w", encoding="utf-8") as f:
                        f.write(driver.page_source)
                    log_debug("페이지 소스를 screenshots/password_page_source.html에 저장", debug)
                except Exception as e:
                    log_error(f"페이지 소스 저장 실패: {e}")
            return False
        
        take_screenshot(driver, "04_password_entered.png", debug)
        
        # "다음" 버튼 클릭 (비밀번호)
        next_password_selectors = [
            "button#passwordNext",
            "button[jsname='LgbsSe'][type='button']",
            "//button[.//span[contains(text(), '다음')]]",
            "//button[.//span[text()='Next']]",
            "button[type='button']"
        ]
        
        if not wait_and_click(driver, next_password_selectors, wait_time, "비밀번호 다음", debug):
            return False
        
        # 로그인 완료 대기
        time.sleep(5)
        wait_for_page_load(driver, wait_time)
        take_screenshot(driver, "05_login_complete.png", debug)
        
        # 2FA 확인
        if "signin/v2/challenge" in driver.current_url or "signin/challenge" in driver.current_url:
            log_error("2FA가 활성화되어 있습니다. 2FA를 비활성화하거나 앱 비밀번호를 사용하세요.")
            return False
        
        log_success("Google 로그인 완료")
        return True
        
    except Exception as e:
        log_error(f"Google 로그인 실패: {e}")
        take_screenshot(driver, "error_google_login.png", debug)
        return False


def automate_playstore_release(
    driver: webdriver.Chrome,
    developer_id: str,
    app_id: str,
    wait_time: int = DEFAULT_WAIT_TIME,
    debug: bool = False
) -> bool:
    """
    Google Play Console에서 Draft 릴리즈를 자동으로 출시
    
    5단계 프로세스:
    1. 내부 테스트 페이지 접속
    2. "버전 수정" 버튼 클릭
    3. "다음" 버튼 클릭
    4. "저장 및 출시" 버튼 클릭
    5. 팝업의 "저장 및 출시" 버튼 클릭
    
    Args:
        driver: WebDriver 인스턴스
        developer_id: Play Console Developer ID
        app_id: Play Console App ID
        wait_time: 대기 시간
        debug: 디버그 모드
    
    Returns:
        성공 여부
    """
    log_info("")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info("📱 Google Play Console 자동화 시작")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info(f"Developer ID: {developer_id}")
    log_info(f"App ID: {app_id}")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    try:
        # Step 1: 내부 테스트 페이지 접속
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("📋 Step 1: 내부 테스트 페이지 접속")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        url = PLAY_CONSOLE_INTERNAL_TESTING_URL.format(
            developer_id=developer_id,
            app_id=app_id
        )
        log_info(f"URL: {url}")
        
        driver.get(url)
        wait_for_page_load(driver, wait_time)
        wait_for_angular_load(driver, wait_time)
        time.sleep(3)  # Angular 앱 추가 대기
        take_screenshot(driver, "10_internal_testing_page.png", debug)
        
        log_success("내부 테스트 페이지 로딩 완료")
        
        # Step 2: "버전 수정" 버튼 클릭
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("🔨 Step 2: 버전 수정 버튼 클릭")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        edit_draft_selectors = [
            "button[debug-id='edit-draft-release-button']",
            "//button[contains(text(), '버전 수정')]",
            "//button[contains(text(), 'Edit draft')]",
            "button.mdc-button.mdc-button--text"
        ]
        
        if not wait_and_click(driver, edit_draft_selectors, wait_time, "버전 수정", debug):
            log_error("버전 수정 버튼을 찾을 수 없습니다. Draft 릴리즈가 없을 수 있습니다.")
            return False
        
        time.sleep(3)
        take_screenshot(driver, "11_prepare_page.png", debug)
        
        # Step 3: "다음" 버튼 클릭
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("➡️  Step 3: 다음 버튼 클릭")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        next_button_selectors = [
            "button[type='submit']",
            "//button[contains(., '다음')]",
            "//button[contains(., 'Next')]",
            "//div[contains(@class, 'button-content') and contains(text(), '다음')]/..",
            "button.mdc-button[type='submit']"
        ]
        
        if not wait_and_click(driver, next_button_selectors, wait_time, "다음", debug):
            return False
        
        time.sleep(3)
        take_screenshot(driver, "12_review_page.png", debug)
        
        # Step 4: "저장 및 출시" 버튼 클릭 (메인)
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("💾 Step 4: 저장 및 출시 버튼 클릭 (메인)")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        save_and_release_main_selectors = [
            "button[debug-id='main-button']",
            "//button[contains(., '저장 및 출시')]",
            "//button[contains(., 'Save and release')]",
            "//span[@class='mdc-button__label' and contains(text(), '저장 및 출시')]/..",
            "button.mdc-button.mdc-button--unelevated.overflowable-button"
        ]
        
        if not wait_and_click(driver, save_and_release_main_selectors, wait_time, "저장 및 출시", debug):
            return False
        
        time.sleep(3)
        take_screenshot(driver, "13_popup_appeared.png", debug)
        
        # Step 5: 팝업의 "저장 및 출시" 버튼 클릭 (확인)
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("✅ Step 5: 팝업 저장 및 출시 버튼 클릭 (확인)")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # 팝업 헤더 확인
        try:
            WebDriverWait(driver, wait_time).until(
                EC.presence_of_element_located((
                    By.XPATH,
                    "//h1[contains(text(), 'Google Play에 변경사항을') or contains(text(), 'Publish changes')]"
                ))
            )
            log_success("확인 팝업 감지됨")
        except:
            log_error("확인 팝업을 찾을 수 없습니다")
        
        save_and_release_popup_selectors = [
            "button[debug-id='yes-button']",
            "button.yes-button",
            "//button[contains(@class, 'yes-button')]",
            "//span[contains(@class, 'yes-button-label') and contains(text(), '저장 및 출시')]/..",
            "//button[contains(., '저장 및 출시') and contains(@class, 'yes-button')]"
        ]
        
        if not wait_and_click(driver, save_and_release_popup_selectors, wait_time, "팝업 저장 및 출시", debug):
            return False
        
        # 완료 대기
        time.sleep(5)
        wait_for_page_load(driver, wait_time)
        wait_for_angular_load(driver, wait_time)
        take_screenshot(driver, "14_release_complete.png", debug)
        
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_success("🎉 Play Store 자동 배포 완료!")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("✅ Draft 릴리즈가 성공적으로 출시되었습니다.")
        log_info("📱 테스터는 Play Store에서 즉시 업데이트 가능합니다.")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        return True
        
    except Exception as e:
        log_error(f"Play Store 자동화 실패: {e}")
        take_screenshot(driver, "error_playstore_automation.png", debug)
        return False


# ----------------------------- CLI 인터페이스 -----------------------------

def main(argv: Optional[List[str]] = None) -> int:
    """메인 함수"""
    parser = argparse.ArgumentParser(
        prog='automate_playstore',
        description='Google Play Console 브라우저 자동화 스크립트',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
사용 예:
  python3 automate_playstore.py \\
    --email "your-email@gmail.com" \\
    --password "your-password" \\
    --developer-id "4736601601401567973" \\
    --app-id "4972112751122062243"

환경 변수:
  GOOGLE_EMAIL, GOOGLE_PASSWORD, PLAY_CONSOLE_DEVELOPER_ID, PLAY_CONSOLE_APP_ID
        """
    )
    
    parser.add_argument(
        '--email',
        required=False,
        default=os.environ.get('GOOGLE_EMAIL'),
        help='Google 계정 이메일 (환경변수: GOOGLE_EMAIL)'
    )
    parser.add_argument(
        '--password',
        required=False,
        default=os.environ.get('GOOGLE_PASSWORD'),
        help='Google 계정 비밀번호 (환경변수: GOOGLE_PASSWORD)'
    )
    parser.add_argument(
        '--developer-id',
        required=False,
        default=os.environ.get('PLAY_CONSOLE_DEVELOPER_ID', '4736601601401567973'),
        help='Play Console Developer ID (기본값: 4736601601401567973)'
    )
    parser.add_argument(
        '--app-id',
        required=False,
        default=os.environ.get('PLAY_CONSOLE_APP_ID', '4972112751122062243'),
        help='Play Console App ID (기본값: 4972112751122062243)'
    )
    parser.add_argument(
        '--headless',
        action='store_true',
        default=os.environ.get('HEADLESS', 'true').lower() == 'true',
        help='헤드리스 모드로 실행 (기본값: true)'
    )
    parser.add_argument(
        '--wait-time',
        type=int,
        default=int(os.environ.get('WAIT_TIME', DEFAULT_WAIT_TIME)),
        help=f'요소 대기 시간 (초, 기본값: {DEFAULT_WAIT_TIME})'
    )
    parser.add_argument(
        '--debug',
        action='store_true',
        default=os.environ.get('DEBUG', 'false').lower() == 'true',
        help='디버그 모드 (스크린샷 저장)'
    )
    
    args = parser.parse_args(argv)
    
    # 필수 파라미터 검증
    if not args.email or not args.password:
        log_error("Google 계정 이메일과 비밀번호가 필요합니다.")
        log_error("--email 및 --password 파라미터를 제공하거나")
        log_error("GOOGLE_EMAIL 및 GOOGLE_PASSWORD 환경변수를 설정하세요.")
        return 1
    
    # 설정 출력
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info("🚀 Google Play Console 자동화 시작")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info(f"📧 이메일: {args.email}")
    log_info(f"🔑 비밀번호: {'*' * len(args.password)}")
    log_info(f"🏢 Developer ID: {args.developer_id}")
    log_info(f"📱 App ID: {args.app_id}")
    log_info(f"👁️  헤드리스 모드: {args.headless}")
    log_info(f"⏱️  대기 시간: {args.wait_time}초")
    log_info(f"🐛 디버그 모드: {args.debug}")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    driver = None
    
    try:
        # Chrome WebDriver 설정
        driver = setup_chrome_driver(headless=args.headless, debug=args.debug)
        
        # Google 로그인
        if not google_login(driver, args.email, args.password, args.wait_time, args.debug):
            log_error("Google 로그인 실패")
            return 1
        
        # Play Store 자동화
        if not automate_playstore_release(
            driver,
            args.developer_id,
            args.app_id,
            args.wait_time,
            args.debug
        ):
            log_error("Play Store 자동화 실패")
            return 1
        
        log_info("")
        log_success("✅ 모든 작업이 성공적으로 완료되었습니다!")
        return 0
        
    except KeyboardInterrupt:
        log_info("")
        log_error("사용자에 의해 중단되었습니다")
        return 130
        
    except Exception as e:
        log_error(f"예상치 못한 오류 발생: {e}")
        if driver and args.debug:
            take_screenshot(driver, "error_unexpected.png", args.debug)
        return 1
        
    finally:
        if driver:
            log_info("브라우저 종료 중...")
            driver.quit()
            log_success("브라우저 종료 완료")


if __name__ == '__main__':
    sys.exit(main())

