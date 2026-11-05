#!/usr/bin/env bash
# ============================================================
# llama-chat 설정
# 이 파일의 값을 바꾼 뒤 ./start.sh 를 다시 실행하면 적용됩니다.
# 환경변수로도 덮어쓸 수 있습니다. 예) PORT=9000 ./start.sh
#
# 지원 환경: Linux, macOS, Windows(WSL2)
# ============================================================

# ------------------------------------------------------------
# 내부 함수: CPU 코어 수 감지 (Linux/macOS 공통)
# ------------------------------------------------------------
_detect_logical_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif command -v getconf >/dev/null 2>&1; then
        getconf _NPROCESSORS_ONLN
    elif command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.ncpu
    else
        echo 4
    fi
}

_detect_physical_cores() {
    local n=""
    if command -v lscpu >/dev/null 2>&1; then
        n="$(lscpu -p=Core,Socket 2>/dev/null | grep -v '^#' | sort -u | wc -l | tr -d ' ')"
    elif command -v sysctl >/dev/null 2>&1; then
        n="$(sysctl -n hw.physicalcpu 2>/dev/null || true)"
    fi
    case "$n" in
        ''|*[!0-9]*) n="" ;;
    esac
    if [ -z "$n" ] || [ "$n" -lt 1 ] 2>/dev/null; then
        _detect_logical_cores
    else
        echo "$n"
    fi
}

# ------------------------------------------------------------
# 1) 모델 (Hugging Face GGUF)
# ------------------------------------------------------------
# 기본: Qwen3.5-4B (Apache-2.0, 한국어 포함 다국어, 약 2.7GB)
MODEL_REPO="${MODEL_REPO:-unsloth/Qwen3.5-4B-GGUF}"
MODEL_QUANT="${MODEL_QUANT:-Q4_K_M}"

# API/Web UI 에서 보이는 모델 이름
MODEL_ALIAS="${MODEL_ALIAS:-qwen3.5-4b}"

# ------------------------------------------------------------
# 2) 서버 주소 / 포트
# ------------------------------------------------------------
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"

# API 인증 키. 비워두면 인증 없음.
# 외부(LAN)에 공개할 때는 반드시 설정하세요.
#   HOST=0.0.0.0 API_KEY=my-secret ./start.sh
API_KEY="${API_KEY:-}"

# ------------------------------------------------------------
# 3) CPU / 메모리
# ------------------------------------------------------------
# 스레드 수: 기본값은 물리 코어 수 (하이퍼스레딩 제외)
THREADS="${THREADS:-$(_detect_physical_cores)}"
# 프롬프트 처리(배치)는 논리 코어까지 쓰는 편이 빠른 경우가 많습니다.
THREADS_BATCH="${THREADS_BATCH:-$(_detect_logical_cores)}"

# 컨텍스트 길이(토큰). 클수록 KV 캐시 메모리 사용량이 늘어납니다.
CTX_SIZE="${CTX_SIZE:-4096}"
# 동시 요청 슬롯 수
PARALLEL="${PARALLEL:-1}"

# 추론(thinking) 모드: on / off / auto
# Qwen3.5 는 기본이 thinking 이라 CPU 에서는 매우 느려집니다. 기본 off 권장.
REASONING="${REASONING:-off}"

# ------------------------------------------------------------
# 4) 기타
# ------------------------------------------------------------
# 첫 실행 시 모델 다운로드 + 로딩을 기다리는 최대 시간(초)
START_TIMEOUT="${START_TIMEOUT:-1800}"

# Web UI 를 자동으로 브라우저에서 열려면 1
OPEN_BROWSER="${OPEN_BROWSER:-0}"
