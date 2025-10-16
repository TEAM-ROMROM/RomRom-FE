#!/usr/bin/env python3
"""
automate_playstore_playwright.py

Google Play Console 브라우저 자동화 스크립트 (Playwright 버전)
Playwright를 사용하여 Draft 릴리즈를 자동으로 출시합니다.

사용 예:
  python3 automate_playstore_playwright.py \
    --email "your-email@gmail.com" \
    --password "your-password" \
    --developer-id "4736601601401567973" \
    --app-id "4972112751122062243"
"""

import argparse
import asyncio
import os
import sys
import time
from typing import List, Optional

try:
    from playwright.async_api import async_playwright, Page, Browser, TimeoutError as PlaywrightTimeoutError
    from playwright_stealth import stealth_async
except ImportError:
    print("❌ 필요한 패키지가 설치되지 않았습니다.")
    print("다음 명령어로 설치하세요:")
    print("  pip install playwright playwright-stealth")
    sys.exit(1)


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


async def take_screenshot(page: Page, filename: str, debug: bool = False) -> None:
    """스크린샷 저장"""
    if not debug:
        return
    
    try:
        ensure_screenshot_dir()
        filepath = os.path.join(SCREENSHOT_DIR, filename)
        await page.screenshot(path=filepath, full_page=True)
        log_debug(f"스크린샷 저장: {filepath}", debug)
    except Exception as e:
        log_error(f"스크린샷 저장 실패: {e}")


async def wait_and_click(
    page: Page,
    selectors: List[str],
    wait_time: int,
    description: str,
    debug: bool = False
) -> bool:
    """
    여러 Selector를 시도하여 요소를 찾고 클릭
    
    Args:
        page: Playwright Page 인스턴스
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
            
            # 요소 대기 및 클릭
            await page.wait_for_selector(selector, timeout=wait_time * 1000, state='visible')
            await take_screenshot(page, f"before_click_{description.replace(' ', '_')}.png", debug)
            
            # 클릭 가능할 때까지 대기
            element = page.locator(selector).first
            await element.click(timeout=5000)
            
            log_success(f"{description} 버튼 클릭 완료")
            await take_screenshot(page, f"after_click_{description.replace(' ', '_')}.png", debug)
            
            # 클릭 후 페이지 로딩 대기
            await asyncio.sleep(2)
            await page.wait_for_load_state('networkidle', timeout=wait_time * 1000)
            
            return True
            
        except PlaywrightTimeoutError:
            log_debug(f"Selector {idx+1} 타임아웃", debug)
            continue
        except Exception as e:
            log_debug(f"Selector {idx+1} 오류: {e}", debug)
            continue
    
    # 모든 Selector 실패
    log_error(f"{description} 버튼을 찾을 수 없습니다")
    await take_screenshot(page, f"error_{description.replace(' ', '_')}.png", debug)
    return False


# ----------------------------- 메인 로직 -----------------------------

async def google_login(
    page: Page,
    email: str,
    password: str,
    wait_time: int = DEFAULT_WAIT_TIME,
    debug: bool = False
) -> bool:
    """
    Google 계정 로그인
    
    Args:
        page: Playwright Page 인스턴스
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
        await page.goto(GOOGLE_LOGIN_URL, wait_until='networkidle', timeout=PAGE_LOAD_TIMEOUT * 1000)
        await take_screenshot(page, "01_google_login_page.png", debug)
        
        # 이메일 입력
        log_info("이메일 입력 중...")
        email_selectors = [
            "input[type='email']",
            "input#identifierId",
            "input[name='identifier']"
        ]
        
        for selector in email_selectors:
            try:
                await page.wait_for_selector(selector, timeout=wait_time * 1000)
                await page.fill(selector, email)
                log_success("이메일 입력 완료")
                break
            except:
                continue
        else:
            log_error("이메일 입력란을 찾을 수 없습니다")
            return False
        
        await take_screenshot(page, "02_email_entered.png", debug)
        
        # "다음" 버튼 클릭 (이메일)
        next_button_selectors = [
            "button#identifierNext",
            "button:has-text('다음')",
            "button:has-text('Next')"
        ]
        
        if not await wait_and_click(page, next_button_selectors, wait_time, "이메일 다음", debug):
            return False
        
        await asyncio.sleep(2)
        await take_screenshot(page, "03_after_email_next.png", debug)
        
        # 비밀번호 입력
        log_info("비밀번호 입력 중...")
        password_selectors = [
            "input[type='password']",
            "input[name='password']",
            "input#password"
        ]
        
        for selector in password_selectors:
            try:
                await page.wait_for_selector(selector, timeout=wait_time * 1000)
                await page.fill(selector, password)
                log_success("비밀번호 입력 완료")
                break
            except:
                continue
        else:
            log_error("비밀번호 입력란을 찾을 수 없습니다")
            return False
        
        await take_screenshot(page, "04_password_entered.png", debug)
        
        # "다음" 버튼 클릭 (비밀번호)
        next_password_selectors = [
            "button#passwordNext",
            "button:has-text('다음')",
            "button:has-text('Next')"
        ]
        
        if not await wait_and_click(page, next_password_selectors, wait_time, "비밀번호 다음", debug):
            return False
        
        # 로그인 완료 대기
        await asyncio.sleep(5)
        await page.wait_for_load_state('networkidle', timeout=PAGE_LOAD_TIMEOUT * 1000)
        await take_screenshot(page, "05_login_complete.png", debug)
        
        # 2FA 확인
        current_url = page.url
        if "signin/v2/challenge" in current_url or "signin/challenge" in current_url:
            log_error("2FA가 활성화되어 있습니다. 2FA를 비활성화하거나 앱 비밀번호를 사용하세요.")
            return False
        
        log_success("Google 로그인 완료")
        return True
        
    except Exception as e:
        log_error(f"Google 로그인 실패: {e}")
        await take_screenshot(page, "error_google_login.png", debug)
        return False


async def automate_playstore_release(
    page: Page,
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
        page: Playwright Page 인스턴스
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
        
        await page.goto(url, wait_until='networkidle', timeout=PAGE_LOAD_TIMEOUT * 1000)
        await asyncio.sleep(3)  # Angular 앱 추가 대기
        await take_screenshot(page, "10_internal_testing_page.png", debug)
        
        log_success("내부 테스트 페이지 로딩 완료")
        
        # Step 2: "버전 수정" 버튼 클릭
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("🔨 Step 2: 버전 수정 버튼 클릭")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        edit_draft_selectors = [
            "button[debug-id='edit-draft-release-button']",
            "button:has-text('버전 수정')",
            "button:has-text('Edit draft')",
            "button.mdc-button.mdc-button--text"
        ]
        
        if not await wait_and_click(page, edit_draft_selectors, wait_time, "버전 수정", debug):
            log_error("버전 수정 버튼을 찾을 수 없습니다. Draft 릴리즈가 없을 수 있습니다.")
            return False
        
        await asyncio.sleep(3)
        await take_screenshot(page, "11_prepare_page.png", debug)
        
        # Step 3: "다음" 버튼 클릭
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("➡️  Step 3: 다음 버튼 클릭")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        next_button_selectors = [
            "button[type='submit']",
            "button:has-text('다음')",
            "button:has-text('Next')",
            "button.mdc-button[type='submit']"
        ]
        
        if not await wait_and_click(page, next_button_selectors, wait_time, "다음", debug):
            return False
        
        await asyncio.sleep(3)
        await take_screenshot(page, "12_review_page.png", debug)
        
        # Step 4: "저장 및 출시" 버튼 클릭 (메인)
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("💾 Step 4: 저장 및 출시 버튼 클릭 (메인)")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        save_and_release_main_selectors = [
            "button[debug-id='main-button']",
            "button:has-text('저장 및 출시')",
            "button:has-text('Save and release')",
            "button.mdc-button.mdc-button--unelevated.overflowable-button"
        ]
        
        if not await wait_and_click(page, save_and_release_main_selectors, wait_time, "저장 및 출시", debug):
            return False
        
        await asyncio.sleep(3)
        await take_screenshot(page, "13_popup_appeared.png", debug)
        
        # Step 5: 팝업의 "저장 및 출시" 버튼 클릭 (확인)
        log_info("")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log_info("✅ Step 5: 팝업 저장 및 출시 버튼 클릭 (확인)")
        log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # 팝업 헤더 확인
        try:
            await page.wait_for_selector(
                "h1:has-text('Google Play에 변경사항을'), h1:has-text('Publish changes')",
                timeout=wait_time * 1000
            )
            log_success("확인 팝업 감지됨")
        except:
            log_error("확인 팝업을 찾을 수 없습니다")
        
        save_and_release_popup_selectors = [
            "button[debug-id='yes-button']",
            "button.yes-button",
            "button:has-text('저장 및 출시')",
            "button:has-text('Save and release')"
        ]
        
        if not await wait_and_click(page, save_and_release_popup_selectors, wait_time, "팝업 저장 및 출시", debug):
            return False
        
        # 완료 대기
        await asyncio.sleep(5)
        await page.wait_for_load_state('networkidle', timeout=PAGE_LOAD_TIMEOUT * 1000)
        await take_screenshot(page, "14_release_complete.png", debug)
        
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
        await take_screenshot(page, "error_playstore_automation.png", debug)
        return False


# ----------------------------- CLI 인터페이스 -----------------------------

async def main_async(args) -> int:
    """메인 비동기 함수"""
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info("🚀 Google Play Console 자동화 시작 (Playwright)")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    log_info(f"📧 이메일: {args.email}")
    log_info(f"🔑 비밀번호: {'*' * len(args.password)}")
    log_info(f"🏢 Developer ID: {args.developer_id}")
    log_info(f"📱 App ID: {args.app_id}")
    log_info(f"👁️  헤드리스 모드: {args.headless}")
    log_info(f"⏱️  대기 시간: {args.wait_time}초")
    log_info(f"🐛 디버그 모드: {args.debug}")
    log_info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    async with async_playwright() as p:
        # 브라우저 실행
        browser = await p.chromium.launch(
            headless=args.headless,
            args=[
                '--no-sandbox',
                '--disable-dev-shm-usage',
                '--disable-blink-features=AutomationControlled',
                '--disable-gpu'
            ]
        )
        
        # 컨텍스트 생성
        context = await browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )
        
        # 페이지 생성
        page = await context.new_page()
        
        # Stealth 모드 적용 (CAPTCHA 회피)
        await stealth_async(page)
        
        try:
            # Google 로그인
            if not await google_login(page, args.email, args.password, args.wait_time, args.debug):
                log_error("Google 로그인 실패")
                return 1
            
            # Play Store 자동화
            if not await automate_playstore_release(
                page,
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
            if args.debug:
                await take_screenshot(page, "error_unexpected.png", args.debug)
            return 1
            
        finally:
            await browser.close()


def main(argv: Optional[List[str]] = None) -> int:
    """메인 함수"""
    parser = argparse.ArgumentParser(
        prog='automate_playstore_playwright',
        description='Google Play Console 브라우저 자동화 스크립트 (Playwright)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
사용 예:
  python3 automate_playstore_playwright.py \\
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
    
    # 비동기 실행
    return asyncio.run(main_async(args))


if __name__ == '__main__':
    sys.exit(main())

