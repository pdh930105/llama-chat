#!/usr/bin/env bash
# ============================================================
# llama.cpp 서버 실행 (CPU 전용 + 내장 Web UI)
#   - 백그라운드 실행, PID/로그 관리
#   - 준비되면 Web UI / API 주소 출력
#   - Linux / macOS / WSL2 지원
# ============================================================
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

resolve_llama || die "llama.cpp 가 설치되어 있지 않습니다. 먼저 ./install.sh 를 실행하세요."

# ------------------------------------------------------------
# 이미 실행 중인지 확인
# ------------------------------------------------------------
PID="$(running_pid)"
CHECK_HOST="$(health_host "$HOST")"
URL="http://${CHECK_HOST}:${PORT}"

if [ -n "$PID" ]; then
    log "이미 실행 중입니다 (PID $PID)"
    echo "  Web UI: ${URL}"
    echo "  종료  : ./stop.sh"
    exit 0
fi

# ------------------------------------------------------------
# 포트 사용 여부 확인
# ------------------------------------------------------------
if port_in_use "$PORT"; then
    die "포트 ${PORT} 이(가) 이미 사용 중입니다. config.sh 의 PORT 를 바꾸거나 ./stop.sh 를 실행하세요."
fi

mkdir -p "$LOG_DIR"

# ------------------------------------------------------------
# 실행 인자
# ------------------------------------------------------------
ARGS=(
    -hf "${MODEL_REPO}:${MODEL_QUANT}"
    -c "$CTX_SIZE"
    -t "$THREADS"
    -tb "$THREADS_BATCH"
    --host "$HOST"
    --port "$PORT"
    --alias "$MODEL_ALIAS"
    --reasoning "$REASONING"
)

# 이미지 입력(비전)은 기본적으로 켭니다. CPU에서는 mmproj 로딩/이미지 처리에
# 시간과 메모리가 더 들기 때문에 ENABLE_VISION=0 으로 끌 수 있습니다.
if [ "${ENABLE_VISION:-0}" = "1" ]; then
    VISION_STATE="on"
else
    VISION_STATE="off"
    ARGS+=(--no-mmproj)
fi

if [ "$PARALLEL" -ge 1 ] 2>/dev/null; then
    ARGS+=(-np "$PARALLEL")
fi
if [ -n "$API_KEY" ]; then
    ARGS+=(--api-key "$API_KEY")
fi

# ------------------------------------------------------------
# 백그라운드 실행
#   macOS 에는 setsid 가 없으므로 nohup 만 사용합니다.
# ------------------------------------------------------------
log "모델: ${MODEL_REPO}:${MODEL_QUANT}"
log "스레드: ${THREADS} (배치 ${THREADS_BATCH}) / 컨텍스트: ${CTX_SIZE} / thinking: ${REASONING} / 이미지: ${VISION_STATE}"
log "로그: $LOG_FILE"

: > "$LOG_FILE"
if have setsid; then
    setsid nohup "${SERVE_CMD[@]}" "${ARGS[@]}" >>"$LOG_FILE" 2>&1 &
else
    nohup "${SERVE_CMD[@]}" "${ARGS[@]}" >>"$LOG_FILE" 2>&1 &
fi
PID=$!
echo "$PID" > "$PID_FILE"

# ------------------------------------------------------------
# 준비될 때까지 대기 (/health 가 200 이면 완료)
# ------------------------------------------------------------
log "서버 준비를 기다리는 중... (첫 실행은 모델 다운로드로 오래 걸릴 수 있습니다)"
START_TS=$(date +%s)
NEXT_NOTICE=15

while :; do
    if ! kill -0 "$PID" 2>/dev/null; then
        rm -f "$PID_FILE"
        warn "서버가 종료되었습니다. 로그 마지막 부분:"
        tail -n 30 "$LOG_FILE" >&2 || true
        exit 1
    fi

    CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "${URL}/health" 2>/dev/null || true)"
    if [ "$CODE" = "200" ]; then
        break
    fi

    ELAPSED=$(( $(date +%s) - START_TS ))
    if [ "$ELAPSED" -ge "$START_TIMEOUT" ]; then
        warn "준비 대기 시간(${START_TIMEOUT}초)을 초과했습니다. 로그를 확인하세요: $LOG_FILE"
        kill "$PID" 2>/dev/null || true
        rm -f "$PID_FILE"
        exit 1
    fi

    if [ "$ELAPSED" -ge "$NEXT_NOTICE" ]; then
        echo "  ... ${ELAPSED}초 경과 (모델 다운로드/로딩 중)"
        NEXT_NOTICE=$((NEXT_NOTICE + 15))
    fi
    sleep 2
done

# ------------------------------------------------------------
# 완료 안내
# ------------------------------------------------------------
echo
log "준비 완료!"
echo "  Web UI : ${URL}"
echo "  API    : ${URL}/v1  (OpenAI 호환)"
[ -n "$API_KEY" ] && echo "  API 키 : config.sh 의 API_KEY 값 사용"
echo "  로그   : $LOG_FILE"
echo "  종료   : ./stop.sh"
echo

if [ "${OPEN_BROWSER:-0}" = "1" ]; then
    open_url "$URL"
fi
