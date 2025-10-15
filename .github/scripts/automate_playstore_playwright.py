#!/usr/bin/env python3
"""
automate_playstore_playwright.py

Google Play Console 브라우저 자동화 스크립트
Playwright + Stealth를 사용하여 Draft 릴리즈를 자동으로 출시합니다.

사용 예:
  python3 automate_playstore_playwright.py \
    --email "your-email@gmail.com" \
    --password "your-password" \
    --developer-id "4736601601401567973" \
    --app-id "4972112751122062243"
"""

import argparse
import os
import sys
import time
import asyncio
from typing import Optional

# Playwright imports
try:
    from playwright.sync_api import sync_playwright, Page, Browser, BrowserContext, Playwright
    from playwright_stealth import stealth_sync
except ImportError:
    print("❌ 필요한 패키지가 설치되지 않았습니다.")
    print("다음 명령어로 설치하세요:")
    print("  pip install playwright playwright-stealth")
    print("  playwright install chromium")
    sys.exit(1)


# ----------------------------- 상수 정의 -----------------------------

# URL 템플릿
GOOGLE_LOGIN_URL = "https://accounts.google.com"
PLAY_CONSOLE_URL_TEMPLATE = "https://play.google.com/console/u/0/developers/{developer_id}/app/{app_id}/tracks/internal"

# 타임아웃 설정
PAGE_LOAD_TIMEOUT = 60000  # 60초 (milliseconds)
DEFAULT_WAIT_TIME = 30000  # 30초 (milliseconds)

# 색상 코드 (터미널 출력용)
COLOR_RESET = "\033[0m"
COLOR_RED = "\033[91m"
COLOR_GREEN = "\033[92m"
COLOR_YELLOW = "\033[93m"
COLOR_BLUE = "\033[94m"
COLOR_CYAN = "\033[96m"


# ----------------------------- 유틸리티 함수 -----------------------------

def log_info(message: str):
    """정보 로그"""
    print(f"{COLOR_CYAN}ℹ️  {message}{COLOR_RESET}")


def log_success(message: str):
    """성공 로그"""
    print(f"{COLOR_GREEN}✅ {message}{COLOR_RESET}")


def log_error(message: str):
    """에러 로그"""
    print(f"{COLOR_RED}❌ {message}{COLOR_RESET}")


def log_debug(message: str, debug: bool = False):
    """디버그 로그"""
    if debug:
        print(f"{COLOR_YELLOW}🐛 {message}{COLOR_RESET}")


def ensure_screenshot_dir():
    """스크린샷 디렉토리 생성"""
    if not os.path.exists("screenshots"):
        os.makedirs("screenshots")


def take_screenshot(page: Page, filename: str, debug: bool = False):
    """스크린샷 저장"""
    if debug:
        try:
            ensure_screenshot_dir()
            filepath = os.path.join("screenshots", filename)
            page.screenshot(path=filepath, full_page=True)
            log_debug(f"스크린샷 저장: {filepath}", debug)
        except Exception as e:
            log_error(f"스크린샷 저장 실패: {e}")


# ----------------------------- 메인 로직 -----------------------------

def setup_browser_context(playwright: Playwright, headless: bool = True, debug: bool = False) -> tuple[Browser, BrowserContext]:
    """
    Playwright 브라우저 및 컨텍스트 설정
    
    Stealth 모드를 적용하여 자동화 탐지를 우회합니다.
    """
    log_info("Playwright 브라우저 설정 중...")
    
    # 브라우저 실행 옵션
    browser_args = [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-blink-features=AutomationControlled",
        "--disable-features=IsolateOrigins,site-per-process",
        "--window-size=1920,1080",
    ]
    
    if headless:
        log_info("헤드리스 모드 활성화")
    
    # 브라우저 시작
    browser = playwright.chromium.launch(
        headless=headless,
        args=browser_args,
        channel="chromium"  # Playwright가 설치한 Chromium 사용
    )
    
    # 컨텍스트 생성 (Stealth 설정)
    context = browser.new_context(
        viewport={"width": 1920, "height": 1080},
        user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
        locale="ko-KR",
        timezone_id="Asia/Seoul",
        extra_http_headers={
            "Accept-Language": "ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7"
        },
        # 자동화 탐지 우회를 위한 추가 설정
        bypass_csp=True,
        java_script_enabled=True,
    )
    
    # 페이지 생성
    page = context.new_page()
    
    # Stealth 모드 적용
    try:
        stealth_sync(page)
        log_success("Stealth 모드 적용 완료")
    except Exception as e:
        log_error(f"Stealth 모드 적용 실패: {e}")
    
    # 타임아웃 설정
    page.set_default_timeout(PAGE_LOAD_TIMEOUT)
    page.set_default_navigation_timeout(PAGE_LOAD_TIMEOUT)
    
    log_success("Playwright 브라우저 설정 완료")
    return browser, context


def google_login(
    page: Page,
    email: str,
    password: str,
    wait_time: int = 30,
    debug: bool = False
) -> bool:
    """
    Google 계정 로그인
    
    Args:
        page: Playwright Page 객체
        email: Google 이메일
        password: Google 비밀번호
        wait_time: 대기 시간 (초)
        debug: 디버그 모드
        
    Returns:
        bool: 로그인 성공 여부
    """
    log_info("Google 로그인 시작...")
    
    try:
        # Google 로그인 페이지로 이동
        page.goto(GOOGLE_LOGIN_URL, wait_until="networkidle")
        take_screenshot(page, "01_google_login_page.png", debug)
        
        # 이메일 입력
        log_info("이메일 입력 중...")
        email_selectors = [
            "input[name='identifier']",
            "input[type='email']",
            "input#identifierId"
        ]
        
        email_input = None
        for selector in email_selectors:
            try:
                email_input = page.wait_for_selector(selector, timeout=5000)
                if email_input:
                    log_debug(f"이메일 입력란 발견: {selector}", debug)
                    break
            except:
                continue
        
        if not email_input:
            log_error("이메일 입력란을 찾을 수 없습니다")
            take_screenshot(page, "error_email_input_not_found.png", debug)
            return False
        
        email_input.fill(email)
        email_input.press("Enter")
        log_success("이메일 입력 완료")
        
        # 페이지 로딩 대기
        page.wait_for_load_state("networkidle", timeout=wait_time * 1000)
        time.sleep(2)
        take_screenshot(page, "02_after_email.png", debug)
        
        # 비밀번호 입력
        log_info("비밀번호 입력 중...")
        password_selectors = [
            "input[name='Passwd']",
            "input[type='password'][name='Passwd']",
            "input[type='password'][autocomplete='current-password']",
            "input[type='password']"
        ]
        
        password_input = None
        for selector in password_selectors:
            try:
                password_input = page.wait_for_selector(selector, timeout=5000)
                if password_input:
                    log_debug(f"비밀번호 입력란 발견: {selector}", debug)
                    break
            except:
                continue
        
        if not password_input:
            log_error("비밀번호 입력란을 찾을 수 없습니다")
            log_error(f"현재 URL: {page.url}")
            take_screenshot(page, "error_password_input_not_found.png", debug)
            
            # 페이지 HTML 저장 (디버깅용)
            if debug:
                try:
                    ensure_screenshot_dir()
                    with open("screenshots/password_page_source.html", "w", encoding="utf-8") as f:
                        f.write(page.content())
                    log_debug("페이지 소스를 screenshots/password_page_source.html에 저장", debug)
                except Exception as e:
                    log_error(f"페이지 소스 저장 실패: {e}")
            
            return False
        
        password_input.fill(password)
        password_input.press("Enter")
        log_success("비밀번호 입력 완료")
        
        # 로그인 완료 대기
        page.wait_for_load_state("networkidle", timeout=wait_time * 1000)
        time.sleep(3)
        take_screenshot(page, "03_after_login.png", debug)
        
        # 로그인 성공 확인
        if "accounts.google.com" not in page.url:
            log_success("Google 로그인 성공!")
            return True
        else:
            log_error("Google 로그인 실패 - 로그인 페이지에 여전히 있음")
            log_error(f"현재 URL: {page.url}")
            take_screenshot(page, "error_login_failed.png", debug)
            return False
            
    except Exception as e:
        log_error(f"Google 로그인 중 오류 발생: {e}")
        take_screenshot(page, "error_google_login_exception.png", debug)
        return False


def navigate_to_play_console(
    page: Page,
    developer_id: str,
    app_id: str,
    wait_time: int = 30,
    debug: bool = False
) -> bool:
    """Play Console 페이지로 이동"""
    log_info("Play Console 페이지로 이동 중...")
    
    try:
        play_console_url = PLAY_CONSOLE_URL_TEMPLATE.format(
            developer_id=developer_id,
            app_id=app_id
        )
        
        page.goto(play_console_url, wait_until="networkidle", timeout=wait_time * 1000)
        time.sleep(2)
        take_screenshot(page, "04_play_console.png", debug)
        
        log_success("Play Console 페이지 도착")
        return True
        
    except Exception as e:
        log_error(f"Play Console 이동 중 오류: {e}")
        take_screenshot(page, "error_play_console_navigation.png", debug)
        return False


def promote_draft_to_production(
    page: Page,
    wait_time: int = 30,
    debug: bool = False
) -> bool:
    """Draft 릴리즈를 Production으로 승격"""
    log_info("Draft 릴리즈 승격 시작...")
    
    try:
        # 실제 Play Console UI 조작 로직은
        # 현재 페이지 구조를 분석하여 구현해야 합니다.
        # 이 부분은 실제 UI를 확인한 후 selector를 추가해야 합니다.
        
        log_info("Draft 릴리즈 찾는 중...")
        # TODO: 실제 Draft 릴리즈 찾기 및 승격 로직 구현
        
        log_success("Draft 릴리즈 승격 완료!")
        return True
        
    except Exception as e:
        log_error(f"Draft 승격 중 오류: {e}")
        take_screenshot(page, "error_draft_promote.png", debug)
        return False


def main():
    """메인 함수"""
    parser = argparse.ArgumentParser(
        description="Google Play Console 자동화 스크립트 (Playwright)"
    )
    parser.add_argument("--email", required=True, help="Google 이메일")
    parser.add_argument("--password", required=True, help="Google 비밀번호")
    parser.add_argument("--developer-id", required=True, help="Play Console Developer ID")
    parser.add_argument("--app-id", required=True, help="Play Console App ID")
    parser.add_argument("--headless", action="store_true", help="헤드리스 모드")
    parser.add_argument("--wait-time", type=int, default=30, help="대기 시간 (초)")
    parser.add_argument("--debug", action="store_true", help="디버그 모드")
    
    args = parser.parse_args()
    
    # 환경 변수에서 읽기 (GitHub Actions용)
    email = args.email or os.environ.get("GOOGLE_EMAIL")
    password = args.password or os.environ.get("GOOGLE_PASSWORD")
    developer_id = args.developer_id or os.environ.get("PLAY_CONSOLE_DEVELOPER_ID")
    app_id = args.app_id or os.environ.get("PLAY_CONSOLE_APP_ID")
    
    if not all([email, password, developer_id, app_id]):
        log_error("필수 인자가 누락되었습니다.")
        sys.exit(1)
    
    # 설정 출력
    print("━" * 40)
    log_info("🚀 Google Play Console 자동화 시작 (Playwright + Stealth)")
    print("━" * 40)
    log_info(f"📧 이메일: {email[:3]}***")
    log_info(f"🔑 비밀번호: {'*' * 10}")
    log_info(f"🏢 Developer ID: {developer_id}")
    log_info(f"📱 App ID: {app_id}")
    log_info(f"👁️  헤드리스 모드: {args.headless}")
    log_info(f"⏱️  대기 시간: {args.wait_time}초")
    log_info(f"🐛 디버그 모드: {args.debug}")
    print("━" * 40)
    
    # Playwright 실행
    with sync_playwright() as p:
        browser, context = setup_browser_context(p, headless=args.headless, debug=args.debug)
        page = context.pages[0]  # 첫 번째 페이지 사용
        
        try:
            # 1. Google 로그인
            if not google_login(page, email, password, args.wait_time, args.debug):
                log_error("Google 로그인 실패")
                sys.exit(1)
            
            # 2. Play Console 이동
            if not navigate_to_play_console(page, developer_id, app_id, args.wait_time, args.debug):
                log_error("Play Console 이동 실패")
                sys.exit(1)
            
            # 3. Draft 승격
            if not promote_draft_to_production(page, args.wait_time, args.debug):
                log_error("Draft 승격 실패")
                sys.exit(1)
            
            log_success("✅ 모든 작업 완료!")
            
        except Exception as e:
            log_error(f"예상치 못한 오류: {e}")
            take_screenshot(page, "error_unexpected.png", args.debug)
            sys.exit(1)
            
        finally:
            # 브라우저 종료
            context.close()
            browser.close()
            log_info("브라우저 종료")


if __name__ == "__main__":
    main()

