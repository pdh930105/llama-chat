#!/usr/bin/env bash
# ============================================================
# llama.cpp 서버 종료 (Linux/macOS/WSL2)
# ============================================================
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PID="$(running_pid)"
if [ -z "$PID" ]; then
    log "실행 중인 서버가 없습니다."
    rm -f "$PID_FILE"
    exit 0
fi

log "서버 종료 중... (PID $PID)"

kill -TERM "$PID" 2>/dev/null || true

i=0
while [ "$i" -lt 10 ]; do
    if ! process_alive "$PID"; then
        rm -f "$PID_FILE"
        log "종료 완료."
        exit 0
    fi
    i=$((i + 1))
    sleep 1
done

warn "정상 종료되지 않아 강제 종료합니다."
kill -KILL "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
log "종료 완료."
