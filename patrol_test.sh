#!/usr/bin/env bash
# ============================================================
# Patrol Test Wizard
# 사용법: bash patrol_test.sh
#
# 대화형 마법사로 Patrol E2E 테스트를 실행합니다.
# 히스토리 기능으로 이전 설정을 빠르게 재실행할 수 있습니다.
# ============================================================

set -euo pipefail

# ──────────────────────────────────────────────
# 색상 정의
# RESET 후 터미널 기본색이 회색으로 떨어지는 문제 방지:
# RESET = sgr0 + 흰색(setaf 15)으로 강제 복원
# ──────────────────────────────────────────────
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  _SGR0=$(tput sgr0)
  WHITE=$(tput setaf 15)
  RESET="${_SGR0}${WHITE}"
  BOLD=$(tput bold)
  CYAN=$(tput setaf 6)
  GREEN=$(tput setaf 2)
  YELLOW=$(tput setaf 3)
  RED=$(tput setaf 1)
  MAGENTA=$(tput setaf 5)
else
  BOLD="" RESET="" CYAN="" GREEN="" YELLOW="" RED="" MAGENTA="" WHITE=""
fi

# ──────────────────────────────────────────────
# 상수
# ──────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HISTORY_FILE="$SCRIPT_DIR/.patrol_history.json"
MAX_HISTORY=10

# ──────────────────────────────────────────────
# 유틸 함수
# ──────────────────────────────────────────────
print_header() {
  echo ""
  echo "${CYAN}${BOLD}========================================${RESET}"
  echo "${CYAN}${BOLD}  Patrol Test Wizard${RESET}"
  echo "${CYAN}${BOLD}========================================${RESET}"
  echo ""
}

print_step() {
  echo ""
  echo "${MAGENTA}${BOLD}[$1] $2${RESET}"
  echo "────────────────────────────────────────"
}

print_selected() {
  echo "  ${GREEN}>> $1${RESET}"
}

print_info() {
  echo "  $1"
}

print_warn() {
  echo "  ${YELLOW}! $1${RESET}"
}

print_error() {
  echo "  ${RED}x $1${RESET}"
  exit 1
}

# 상대 시간 표시 (python3 사용)
relative_time() {
  local ts="$1"
  python3 -c "
import datetime, sys
try:
    ts = datetime.datetime.strptime('$ts', '%Y-%m-%d %H:%M:%S')
    diff = datetime.datetime.now() - ts
    secs = int(diff.total_seconds())
    if secs < 60: print(f'{secs}초 전')
    elif secs < 3600: print(f'{secs // 60}분 전')
    elif secs < 86400: print(f'{secs // 3600}시간 전')
    elif secs < 604800: print(f'{secs // 86400}일 전')
    else: print('$ts')
except: print('$ts')
" 2>/dev/null || echo "$ts"
}

# ──────────────────────────────────────────────
# 히스토리 JSON 관리 (python3 사용)
# ──────────────────────────────────────────────
load_history_count() {
  if [[ ! -f "$HISTORY_FILE" ]]; then
    echo "0"
    return
  fi
  python3 -c "
import json, sys
try:
    with open('$HISTORY_FILE', 'r') as f:
        data = json.load(f)
    print(len(data))
except:
    print(0)
" 2>/dev/null || echo "0"
}

# 히스토리 항목 하나 읽기 (인덱스 기반)
load_history_item() {
  local idx="$1"
  local field="$2"
  python3 -c "
import json
try:
    with open('$HISTORY_FILE', 'r') as f:
        data = json.load(f)
    print(data[$idx].get('$field', ''))
except:
    print('')
" 2>/dev/null || echo ""
}

# 히스토리 목록 출력
print_history_list() {
  python3 -c "
import json, datetime

try:
    with open('$HISTORY_FILE', 'r') as f:
        data = json.load(f)
except:
    data = []

for i, item in enumerate(data):
    ts = item.get('timestamp', '')
    platform = item.get('platform', '?')
    device_name = item.get('device_name', '?')
    test = item.get('test_target', '')
    # 상대 시간 계산
    try:
        dt = datetime.datetime.strptime(ts, '%Y-%m-%d %H:%M:%S')
        diff = datetime.datetime.now() - dt
        secs = int(diff.total_seconds())
        if secs < 60: rel = f'{secs}초 전'
        elif secs < 3600: rel = f'{secs // 60}분 전'
        elif secs < 86400: rel = f'{secs // 3600}시간 전'
        elif secs < 604800: rel = f'{secs // 86400}일 전'
        else: rel = ts
    except:
        rel = ts

    # 플랫폼 라벨
    plat_label = 'iOS' if platform == 'ios' else 'Android'

    # 테스트 이름 (짧게)
    if test:
        test_short = test.replace('integration_test/', '')
    else:
        test_short = '전체 (all)'

    print(f'  {i+1}) [{plat_label}] {device_name} - {test_short}  ({rel})')
" 2>/dev/null
}

# 히스토리 저장 (중복 제거, 최대 MAX_HISTORY개)
save_history() {
  local platform="$1"
  local device_id="$2"
  local device_name="$3"
  local test_target="$4"
  local verbose="$5"
  local flavor="$6"
  local dart_defines="$7"
  local command="$8"

  python3 -c "
import json, datetime, os

HISTORY_FILE = '$HISTORY_FILE'
MAX = $MAX_HISTORY

# 기존 히스토리 로드
try:
    with open(HISTORY_FILE, 'r') as f:
        data = json.load(f)
except:
    data = []

# 새 항목
new_item = {
    'timestamp': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    'platform': '$platform',
    'device_id': '$device_id',
    'device_name': '$device_name',
    'test_target': '$test_target',
    'verbose': $( [[ "$verbose" == "true" ]] && echo "True" || echo "False" ),
    'flavor': '$flavor',
    'dart_defines': '$dart_defines'.split(',') if '$dart_defines' else [],
    'command': '$command'
}

# 중복 제거 (같은 platform + device_id + test_target 조합)
data = [
    item for item in data
    if not (
        item.get('platform') == new_item['platform']
        and item.get('device_id') == new_item['device_id']
        and item.get('test_target') == new_item['test_target']
    )
]

# 맨 앞에 추가
data.insert(0, new_item)

# 최대 개수 유지
data = data[:MAX]

# 저장
with open(HISTORY_FILE, 'w') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
" 2>/dev/null
}

# ──────────────────────────────────────────────
# 터미널 기본색을 흰색으로 강제 설정
# ──────────────────────────────────────────────
echo -n "${WHITE}"

# ──────────────────────────────────────────────
# 프로젝트 루트 이동
# ──────────────────────────────────────────────
cd "$SCRIPT_DIR"

# patrol CLI 존재 확인
if ! command -v patrol >/dev/null 2>&1; then
  if dart pub global run patrol_cli --version >/dev/null 2>&1; then
    PATROL_CMD="dart pub global run patrol_cli"
  else
    print_error "patrol CLI가 설치되어 있지 않습니다. 'dart pub global activate patrol_cli' 로 설치하세요."
  fi
else
  PATROL_CMD="patrol"
fi

# integration_test 디렉토리 확인
if [[ ! -d "integration_test" ]]; then
  print_error "integration_test/ 디렉토리가 없습니다. 프로젝트 루트에서 실행하세요."
fi

# ──────────────────────────────────────────────
# 히스토리 확인 → 빠른 실행 or 마법사
# ──────────────────────────────────────────────
print_header

HISTORY_COUNT=$(load_history_count)
USE_HISTORY=false

if [[ "$HISTORY_COUNT" -gt 0 ]]; then
  echo "${WHITE}${BOLD}[최근 실행 기록]${RESET}"
  echo "────────────────────────────────────────"

  print_history_list

  echo ""
  echo "  0) ${BOLD}새 설정으로 실행${RESET}"
  echo ""

  while true; do
    read -rp "  선택 (0-${HISTORY_COUNT}): " history_choice
    if [[ "$history_choice" =~ ^[0-9]+$ ]] && (( history_choice >= 0 && history_choice <= HISTORY_COUNT )); then
      break
    else
      echo "  ${RED}0~${HISTORY_COUNT} 범위의 숫자를 입력하세요.${RESET}"
    fi
  done

  if [[ "$history_choice" -gt 0 ]]; then
    USE_HISTORY=true
    HIST_IDX=$((history_choice - 1))

    # 히스토리에서 설정 복원
    PLATFORM=$(load_history_item "$HIST_IDX" "platform")
    SELECTED_DEVICE=$(load_history_item "$HIST_IDX" "device_id")
    SELECTED_DEVICE_NAME=$(load_history_item "$HIST_IDX" "device_name")
    SELECTED_TEST=$(load_history_item "$HIST_IDX" "test_target")
    HIST_VERBOSE=$(load_history_item "$HIST_IDX" "verbose")
    HIST_FLAVOR=$(load_history_item "$HIST_IDX" "flavor")
    HIST_COMMAND=$(load_history_item "$HIST_IDX" "command")

    if [[ "$SELECTED_TEST" == "" ]]; then
      SELECTED_TEST_DISPLAY="전체 (all)"
    else
      SELECTED_TEST_DISPLAY="$SELECTED_TEST"
    fi

    # verbose는 항상 ON (기본값)
    VERBOSE_FLAG="--verbose"
    FLAVOR_FLAG=""
    DART_DEFINE_FLAGS=()

    echo ""
    print_selected "히스토리 #${history_choice} 설정 로드 완료"

    # iOS 시뮬레이터 부팅 확인 (히스토리 복원 시)
    if [[ "$PLATFORM" == "ios" ]]; then
      sim_state=$(xcrun simctl list devices 2>/dev/null | grep "$SELECTED_DEVICE" | grep -o "(Booted)\|(Shutdown)" | tr -d '()' || echo "")
      if [[ "$sim_state" == "Shutdown" ]]; then
        echo ""
        while true; do
          read -rp "  시뮬레이터가 꺼져있습니다. 부팅할까요? (Y/n): " boot_answer
          if [[ -z "$boot_answer" ]] || [[ "$boot_answer" =~ ^[Yy]$ ]]; then
            echo "  시뮬레이터 부팅 중..."
            xcrun simctl boot "$SELECTED_DEVICE" 2>/dev/null || true
            open -a Simulator 2>/dev/null || true
            echo "  ${GREEN}부팅 완료${RESET}"
            break
          elif [[ "$boot_answer" =~ ^[Nn]$ ]]; then
            break
          else
            echo "  ${RED}Y 또는 N을 입력하세요.${RESET}"
          fi
        done
      fi
    fi
  fi
fi

# ──────────────────────────────────────────────
# 마법사 모드 (히스토리 미사용 시)
# ──────────────────────────────────────────────
if [[ "$USE_HISTORY" == false ]]; then

  # ── STEP 1: 플랫폼 선택 ──
  print_step "STEP 1" "플랫폼 선택"

  echo "  1) Android"
  echo "  2) iOS Simulator"
  echo ""

  while true; do
    read -rp "  선택 (1-2): " platform_choice
    case "$platform_choice" in
      1) PLATFORM="android"; break ;;
      2) PLATFORM="ios"; break ;;
      *) echo "  ${RED}1 또는 2를 입력하세요.${RESET}" ;;
    esac
  done

  if [[ "$PLATFORM" == "android" ]]; then
    print_selected "Android"
  else
    print_selected "iOS Simulator"
  fi

  # ── STEP 2: 디바이스 선택 ──
  print_step "STEP 2" "디바이스 선택"

  declare -a DEVICE_IDS=()
  declare -a DEVICE_NAMES=()

  if [[ "$PLATFORM" == "android" ]]; then
    while IFS= read -r line; do
      if [[ "$line" == *"android"* ]] || [[ "$line" == *"Android"* ]]; then
        device_id=$(echo "$line" | awk -F '•' '{print $2}' | xargs)
        device_name=$(echo "$line" | awk -F '•' '{print $1}' | xargs)
        if [[ -n "$device_id" ]]; then
          DEVICE_IDS+=("$device_id")
          DEVICE_NAMES+=("$device_name")
        fi
      fi
    done < <(flutter devices 2>/dev/null)

    if [[ ${#DEVICE_IDS[@]} -eq 0 ]]; then
      print_error "연결된 Android 디바이스가 없습니다. 에뮬레이터를 실행하세요."
    fi

    for i in "${!DEVICE_IDS[@]}"; do
      echo "  $((i+1))) ${DEVICE_NAMES[$i]}  (${DEVICE_IDS[$i]})"
    done

  else
    current_runtime=""
    while IFS= read -r line; do
      if [[ "$line" =~ ^--\ (.+)\ --$ ]]; then
        current_runtime="${BASH_REMATCH[1]}"
        continue
      fi
      if [[ "$line" =~ ^[[:space:]]+(.+)\ \(([A-F0-9-]+)\)\ \((Booted|Shutdown)\) ]]; then
        device_name="${BASH_REMATCH[1]}"
        device_id="${BASH_REMATCH[2]}"
        device_state="${BASH_REMATCH[3]}"

        if [[ "$device_state" == "Booted" ]]; then
          state_label="${GREEN}Booted${RESET}"
        else
          state_label="Shutdown"
        fi

        DEVICE_IDS+=("$device_id")
        DEVICE_NAMES+=("$device_name [$current_runtime] ($state_label)")
      fi
    done < <(xcrun simctl list devices available 2>/dev/null)

    if [[ ${#DEVICE_IDS[@]} -eq 0 ]]; then
      print_error "사용 가능한 iOS 시뮬레이터가 없습니다."
    fi

    for i in "${!DEVICE_IDS[@]}"; do
      echo "  $((i+1))) ${DEVICE_NAMES[$i]}  (${DEVICE_IDS[$i]})"
    done
  fi

  echo ""
  while true; do
    read -rp "  선택 (1-${#DEVICE_IDS[@]}): " device_choice
    if [[ "$device_choice" =~ ^[0-9]+$ ]] && (( device_choice >= 1 && device_choice <= ${#DEVICE_IDS[@]} )); then
      SELECTED_DEVICE="${DEVICE_IDS[$((device_choice-1))]}"
      SELECTED_DEVICE_NAME="${DEVICE_NAMES[$((device_choice-1))]}"
      break
    else
      echo "  ${RED}1~${#DEVICE_IDS[@]} 범위의 숫자를 입력하세요.${RESET}"
    fi
  done

  print_selected "$SELECTED_DEVICE_NAME"

  # iOS 시뮬레이터 부팅 확인
  if [[ "$PLATFORM" == "ios" ]]; then
    sim_state=$(xcrun simctl list devices 2>/dev/null | grep "$SELECTED_DEVICE" | grep -o "(Booted)\|(Shutdown)" | tr -d '()' || echo "")
    if [[ "$sim_state" == "Shutdown" ]]; then
      echo ""
      while true; do
        read -rp "  시뮬레이터가 꺼져있습니다. 부팅할까요? (Y/n): " boot_answer
        if [[ -z "$boot_answer" ]] || [[ "$boot_answer" =~ ^[Yy]$ ]]; then
          echo "  시뮬레이터 부팅 중..."
          xcrun simctl boot "$SELECTED_DEVICE" 2>/dev/null || true
          open -a Simulator 2>/dev/null || true
          echo "  ${GREEN}부팅 완료${RESET}"
          break
        elif [[ "$boot_answer" =~ ^[Nn]$ ]]; then
          break
        else
          echo "  ${RED}Y 또는 N을 입력하세요.${RESET}"
        fi
      done
    fi
  fi

  # ── STEP 3: 테스트 파일 선택 ──
  print_step "STEP 3" "테스트 파일 선택"

  declare -a TEST_FILES=()

  while IFS= read -r file; do
    TEST_FILES+=("$file")
  done < <(find integration_test -name "*_test.dart" ! -name "test_bundle.dart" ! -path "*/helpers/*" | sort)

  if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    print_error "integration_test/ 에 테스트 파일이 없습니다."
  fi

  echo "  0) ${BOLD}전체 실행 (all)${RESET}"
  for i in "${!TEST_FILES[@]}"; do
    echo "  $((i+1))) ${TEST_FILES[$i]}"
  done

  echo ""
  while true; do
    read -rp "  선택 (0-${#TEST_FILES[@]}): " test_choice
    if [[ "$test_choice" =~ ^[0-9]+$ ]] && (( test_choice >= 0 && test_choice <= ${#TEST_FILES[@]} )); then
      break
    else
      echo "  ${RED}0~${#TEST_FILES[@]} 범위의 숫자를 입력하세요.${RESET}"
    fi
  done

  if [[ "$test_choice" -eq 0 ]]; then
    SELECTED_TEST=""
    SELECTED_TEST_DISPLAY="전체 (all)"
  else
    SELECTED_TEST="${TEST_FILES[$((test_choice-1))]}"
    SELECTED_TEST_DISPLAY="$SELECTED_TEST"
  fi

  print_selected "$SELECTED_TEST_DISPLAY"

  # verbose는 항상 ON (기본값)
  VERBOSE_FLAG="--verbose"
  FLAVOR_FLAG=""
  DART_DEFINE_FLAGS=()

fi  # END 마법사 모드

# ──────────────────────────────────────────────
# 명령어 조립 & 미리보기
# ──────────────────────────────────────────────
print_step "STEP 4" "최종 명령어 확인"

# 명령어 조립
CMD_PARTS=($PATROL_CMD "test")

if [[ -n "${SELECTED_TEST:-}" ]]; then
  CMD_PARTS+=("--target" "$SELECTED_TEST")
fi

CMD_PARTS+=("--device" "$SELECTED_DEVICE")

# verbose 항상 ON
CMD_PARTS+=("--verbose")

# 복사 가능한 한 줄 명령어 생성
ONELINER=""
for part in "${CMD_PARTS[@]}"; do
  if [[ -z "$ONELINER" ]]; then
    ONELINER="$part"
  else
    ONELINER="$ONELINER $part"
  fi
done

echo ""
echo "${WHITE}${BOLD}  설정 요약${RESET}"
echo "  플랫폼:    ${PLATFORM:-}"
echo "  디바이스:  ${SELECTED_DEVICE_NAME:-$SELECTED_DEVICE}"
echo "  테스트:    ${SELECTED_TEST_DISPLAY:-}"
echo "  verbose:   ON (기본)"
echo ""
echo "${GREEN}${BOLD}  실행 명령어:${RESET}"
echo ""
echo "  $ONELINER"
echo ""

# ──────────────────────────────────────────────
# 실행 확인 (Y/y/Enter = 실행, N/n = 취소, 그 외 = 재입력)
# ──────────────────────────────────────────────
while true; do
  read -rp "  실행하시겠습니까? (Y/n): " run_answer
  if [[ -z "$run_answer" ]] || [[ "$run_answer" =~ ^[Yy]$ ]]; then
    break
  elif [[ "$run_answer" =~ ^[Nn]$ ]]; then
    echo ""
    echo "  ${YELLOW}취소되었습니다. 위 명령어를 복사하여 직접 실행할 수 있습니다.${RESET}"
    echo ""
    exit 0
  else
    echo "  ${RED}Y 또는 N을 입력하세요.${RESET}"
  fi
done

# ──────────────────────────────────────────────
# 히스토리 저장
# ──────────────────────────────────────────────
# 디바이스 이름에서 ANSI 색상 코드 제거하여 저장
CLEAN_DEVICE_NAME=$(echo "${SELECTED_DEVICE_NAME:-}" | sed 's/\x1b\[[0-9;]*m//g')

save_history \
  "${PLATFORM:-}" \
  "${SELECTED_DEVICE:-}" \
  "$CLEAN_DEVICE_NAME" \
  "${SELECTED_TEST:-}" \
  "true" \
  "" \
  "" \
  "$ONELINER"

# ──────────────────────────────────────────────
# 실행
# patrol CLI는 dim(\033[2m) 코드로 로그를 회색 표시함
# sed로 dim 코드를 제거하고, reset(\033[0m) 후 흰색 복원
# ──────────────────────────────────────────────
echo ""
echo "${GREEN}${BOLD}  테스트 실행 중...${RESET}"
echo "────────────────────────────────────────"
echo ""

# set +e: patrol 종료 코드를 직접 처리
set +e

# patrol 출력을 파이프로 받아 dim 코드 제거 + reset 후 흰색 복원
# macOS sed: -l (line-buffered), GNU sed: -u (unbuffered)
SED_LINE_OPT=""
if sed -l '' </dev/null 2>/dev/null; then
  SED_LINE_OPT="-l"  # macOS BSD sed
elif sed -u '' </dev/null 2>/dev/null; then
  SED_LINE_OPT="-u"  # GNU sed
fi

${CMD_PARTS[@]} 2>&1 | sed $SED_LINE_OPT \
  -e $'s/\033\\[2m//g' \
  -e $'s/\033\\[0m/\033[0m\033[38;5;15m/g'
PATROL_EXIT=${PIPESTATUS[0]}

# 터미널 색상 복원
printf '%s' "${_SGR0:-}"

exit ${PATROL_EXIT:-0}
