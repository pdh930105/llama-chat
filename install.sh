#!/usr/bin/env bash
# ============================================================
# llama.cpp 설치 스크립트 (CPU 전용, Linux/macOS/WSL2)
#   1) 공식 설치 스크립트(llama.app) 사용
#   2) 실패하면 GitHub 릴리스의 OS/아키텍처별 바이너리로 대체
# ============================================================
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

INSTALL_ROOT="$SCRIPT_DIR/llama.cpp"

case "$OS_NAME" in
    Linux|Darwin|FreeBSD) ;;
    MINGW*|MSYS*|CYGWIN*)
        die "Windows에서는 WSL2(Ubuntu)를 사용하세요. 자세한 내용은 README.md 를 참고하세요." ;;
    *)
        warn "검증되지 않은 OS 입니다: $OS_NAME (계속 시도합니다)" ;;
esac

have curl || die "'curl' 이 필요합니다."
have tar  || die "'tar' 가 필요합니다."

# ------------------------------------------------------------
# 이미 설치되어 있으면 종료
# ------------------------------------------------------------
if resolve_llama; then
    log "이미 llama.cpp 가 설치되어 있습니다."
    if [ "$LLAMA_KIND" = "unified" ]; then
        "${SERVE_CMD[0]}" version 2>/dev/null | head -2 || true
        echo "  실행 파일: ${SERVE_CMD[0]}"
    else
        echo "  실행 파일: ${SERVE_CMD[0]}"
    fi
    echo
    log "다음 단계: ./download-model.sh  →  ./start.sh"
    exit 0
fi

# ------------------------------------------------------------
# 임시 디렉터리 (Linux/macOS 공통)
# ------------------------------------------------------------
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/llama-install.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT INT TERM

# ------------------------------------------------------------
# 1) 공식 설치 (llama.app)
# ------------------------------------------------------------
log "llama.cpp 공식 설치 스크립트를 실행합니다 (https://llama.app/install.sh)"
TMP_INSTALL="$TMP_DIR/install.sh"

if curl -fsSL --max-time 120 https://llama.app/install.sh -o "$TMP_INSTALL" &&
   sh "$TMP_INSTALL"; then
    hash -r 2>/dev/null || true
    :
fi

# 공식 설치가 PATH에 바로 안 잡힐 수 있으므로 후보를 다시 확인
if resolve_llama; then
    log "설치 완료: ${SERVE_CMD[0]}"
    "${SERVE_CMD[0]}" version 2>/dev/null | head -2 || true
    echo
    log "다음 단계: ./download-model.sh  →  ./start.sh"
    exit 0
fi

# ------------------------------------------------------------
# 2) 대체 설치: GitHub 릴리스 바이너리
# ------------------------------------------------------------
warn "공식 설치 스크립트로 설치하지 못했습니다. GitHub 릴리스 바이너리로 시도합니다."

case "$OS_NAME:$ARCH_NAME" in
    Linux:x86_64|Linux:amd64)   ASSET_SUFFIX="ubuntu-x64" ;;
    Linux:aarch64|Linux:arm64)  ASSET_SUFFIX="ubuntu-arm64" ;;
    Darwin:arm64)               ASSET_SUFFIX="macos-arm64" ;;
    Darwin:x86_64)              ASSET_SUFFIX="macos-x64" ;;
    *)
        warn "이 OS/아키텍처용 사전 빌드 바이너리가 없습니다: $OS_NAME $ARCH_NAME"
        print_build_help
        exit 1
        ;;
esac

log "최신 릴리스 버전 확인 중..."
RELEASES_JSON="$(curl -fsSL --max-time 60 \
    "https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=30" || true)"
TAG="$(printf '%s' "$RELEASES_JSON" \
    | tr ',' '\n' \
    | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"b[0-9][0-9]*"' \
    | head -1 \
    | grep -o 'b[0-9][0-9]*' || true)"

if [ -z "$TAG" ]; then
    warn "릴리스 버전을 확인하지 못했습니다."
    print_build_help
    exit 1
fi

ASSET="llama-${TAG}-bin-${ASSET_SUFFIX}.tar.gz"
URL="https://github.com/ggml-org/llama.cpp/releases/download/${TAG}/${ASSET}"

log "다운로드: $ASSET"
mkdir -p "$INSTALL_ROOT"
TMP_TAR="$TMP_DIR/llama-bin.tar.gz"

if ! curl -fL --retry 3 --max-time 900 "$URL" -o "$TMP_TAR"; then
    warn "바이너리 다운로드 실패: $URL"
    print_build_help
    exit 1
fi

log "압축 해제: $INSTALL_ROOT"
rm -rf "$INSTALL_ROOT"
mkdir -p "$INSTALL_ROOT"
tar xzf "$TMP_TAR" -C "$INSTALL_ROOT" --strip-components=1

if [ ! -x "$INSTALL_ROOT/llama" ]; then
    warn "압축을 풀었지만 llama 실행 파일을 찾지 못했습니다."
    print_build_help
    exit 1
fi

if ! "$INSTALL_ROOT/llama" version >/dev/null 2>&1; then
    warn "내려받은 llama 바이너리가 실행되지 않습니다. (glibc 버전 등이 맞지 않을 수 있습니다)"
    print_build_help
    exit 1
fi

log "설치 완료: $INSTALL_ROOT/llama"
"$INSTALL_ROOT/llama" version | head -2
echo
log "다음 단계: ./download-model.sh  →  ./start.sh"
