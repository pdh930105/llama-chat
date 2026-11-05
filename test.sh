#!/usr/bin/env bash
# ============================================================
# 설치 없이 스크립트 문법과 설정 감지를 확인합니다.
#   사용법: ./test.sh
#   Linux / macOS / WSL2 에서 동작합니다.
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

fail() { echo "[test] 실패: $*" >&2; exit 1; }

echo "[test] bash 문법 검사"
for f in *.sh; do
    bash -n "$f" || fail "$f 문법 오류"
    echo "  OK  $f"
done

echo "[test] 설정 감지"
# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

case "$THREADS" in
    ''|*[!0-9]*) fail "THREADS 값이 숫자가 아닙니다: $THREADS" ;;
esac
case "$THREADS_BATCH" in
    ''|*[!0-9]*) fail "THREADS_BATCH 값이 숫자가 아닙니다: $THREADS_BATCH" ;;
esac
case "$CTX_SIZE" in
    ''|*[!0-9]*) fail "CTX_SIZE 값이 숫자가 아닙니다: $CTX_SIZE" ;;
esac
[ "$THREADS" -ge 1 ] || fail "THREADS 는 1 이상이어야 합니다."
[ "$THREADS_BATCH" -ge 1 ] || fail "THREADS_BATCH 는 1 이상이어야 합니다."
[ "$CTX_SIZE" -ge 256 ] || fail "CTX_SIZE 는 256 이상이어야 합니다."
case "$ENABLE_VISION" in
    0|1) ;;
    *) fail "ENABLE_VISION 은 0 또는 1 이어야 합니다: $ENABLE_VISION" ;;
esac
echo "  OK  THREADS=$THREADS THREADS_BATCH=$THREADS_BATCH CTX_SIZE=$CTX_SIZE ENABLE_VISION=$ENABLE_VISION"

echo "[test] 공통 함수 로드"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"
[ -n "$OS_NAME" ] || fail "OS_NAME 을 감지하지 못했습니다."
declare -F resolve_llama >/dev/null || fail "resolve_llama 함수가 없습니다."
declare -F port_in_use >/dev/null || fail "port_in_use 함수가 없습니다."
declare -F process_alive >/dev/null || fail "process_alive 함수가 없습니다."
echo "  OK  OS=$OS_NAME ARCH=$ARCH_NAME"

echo
echo "[test] 모두 통과했습니다."
