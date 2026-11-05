#!/usr/bin/env bash
# 공통 경로/함수. 직접 실행하지 않습니다. (install.sh, start.sh 등에서 source)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/llama-server.log"
PID_FILE="$SCRIPT_DIR/llama-server.pid"

OS_NAME="$(uname -s 2>/dev/null || echo unknown)"
ARCH_NAME="$(uname -m 2>/dev/null || echo unknown)"

log()  { printf '\033[1;32m[llama-chat]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# 로컬에 설치된 llama 실행 파일을 찾는다.
# 성공 시 SERVE_CMD 배열을 채운다.  예) SERVE_CMD=(llama serve) 또는 (llama-server)
resolve_llama() {
    local candidates=()
    local c

    if [ -n "${LLAMA_BIN:-}" ]; then
        candidates+=("$LLAMA_BIN")
    else
        # install.sh 가 설치하는 위치들 (Linux/macOS 공통)
        candidates+=(
            "$SCRIPT_DIR/bin/llama"
            "$HOME/.local/bin/llama"
            "$HOME/.llama-app/llama"
        )
        c="$(command -v llama 2>/dev/null || true)"
        [ -n "$c" ] && candidates+=("$c")
        # install.sh 의 GitHub 릴리스 대체 설치 경로
        candidates+=("$SCRIPT_DIR/llama.cpp/llama")
    fi

    for c in "${candidates[@]}"; do
        [ -x "$c" ] || continue
        # 통합 CLI 인지 확인 (serve 서브커맨드 존재)
        if "$c" help 2>/dev/null | grep -q 'serve'; then
            SERVE_CMD=("$c" serve)
            LLAMA_KIND="unified"
            return 0
        fi
    done

    # 구버전/직접 빌드한 llama-server 바이너리
    local servers=(
        "$SCRIPT_DIR/llama.cpp/build/bin/llama-server"
        "$SCRIPT_DIR/llama.cpp/llama-server"
    )
    c="$(command -v llama-server 2>/dev/null || true)"
    [ -n "$c" ] && servers+=("$c")

    for c in "${servers[@]}"; do
        [ -x "$c" ] || continue
        SERVE_CMD=("$c")
        LLAMA_KIND="server"
        return 0
    done

    return 1
}

# 프로세스가 실제로 살아 있는지 확인 (좀비 프로세스 제외)
process_alive() {
    local pid="$1"
    kill -0 "$pid" 2>/dev/null || return 1
    local stat
    stat="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
    case "$stat" in
        ''|Z*) return 1 ;;
    esac
    return 0
}

# 실행 중인 서버의 PID 를 출력 (없으면 빈 문자열)
running_pid() {
    [ -f "$PID_FILE" ] || return 0
    local pid
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
    [ -n "$pid" ] || return 0
    if process_alive "$pid"; then
        echo "$pid"
    else
        rm -f "$PID_FILE"
    fi
}

health_host() {
    case "$1" in
        0.0.0.0|::|"[::]"|"") echo "127.0.0.1" ;;
        *) echo "$1" ;;
    esac
}

# 포트가 이미 사용 중인지 확인 (Linux: ss/lsof, macOS: lsof)
port_in_use() {
    local port="$1"
    if have ss; then
        ss -ltnH "sport = :$port" 2>/dev/null | grep -q . && return 0
    fi
    if have lsof; then
        lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && return 0
    fi
    return 1
}

# 기본 브라우저로 URL 열기 (Linux/macOS)
open_url() {
    local url="$1"
    if [ "$OS_NAME" = "Darwin" ] && have open; then
        open "$url" >/dev/null 2>&1 &
    elif have xdg-open; then
        xdg-open "$url" >/dev/null 2>&1 &
    else
        warn "브라우저를 자동으로 열 수 없습니다. 직접 접속하세요: $url"
    fi
}

# 소스 빌드 안내 (공통)
print_build_help() {
    cat >&2 <<'EOF'

소스에서 직접 빌드하는 방법:

  # Ubuntu/Debian
  sudo apt install -y build-essential cmake git

  # macOS (Homebrew)
  brew install cmake git

  git clone https://github.com/ggml-org/llama.cpp
  cd llama.cpp
  cmake -B build -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build build -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
  ./build/bin/llama-server --version

빌드 후 이 폴더의 start.sh 가 build/bin/llama-server 를 자동으로 찾습니다.

EOF
}
