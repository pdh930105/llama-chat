#!/usr/bin/env bash
# ============================================================
# 모델 다운로드 (Hugging Face → 로컬 캐시)
#   기본 저장 위치: ~/.cache/huggingface/hub
#   (HF_HOME 환경변수로 변경 가능)
#   Linux / macOS / WSL2 공통
# ============================================================
set -euo pipefail

# shellcheck source=lib.sh
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# shellcheck source=config.sh
source "$SCRIPT_DIR/config.sh"

resolve_llama || die "llama.cpp 가 설치되어 있지 않습니다. 먼저 ./install.sh 를 실행하세요."

MODEL="${MODEL_REPO}:${MODEL_QUANT}"
HF_CACHE="${HF_HOME:-$HOME/.cache/huggingface}/hub"

if [ "$LLAMA_KIND" != "unified" ]; then
    warn "이 버전에는 'llama download' 명령이 없습니다."
    warn "모델은 ./start.sh 첫 실행 시 자동으로 다운로드됩니다."
    exit 0
fi

log "모델 다운로드: $MODEL"
log "저장 위치: $HF_CACHE"

if [ "${ENABLE_VISION:-0}" = "1" ]; then
    # 이미지 입력을 사용하려면 멀티모달 프로젝터(mmproj, 약 672MB)도 필요합니다.
    log "이미지 입력(mmproj)도 함께 다운로드합니다."
    "${SERVE_CMD[0]}" download -hf "$MODEL"
else
    # 텍스트 채팅만 사용하므로 멀티모달 프로젝터(mmproj)는 받지 않는다.
    if ! "${SERVE_CMD[0]}" download -hf "$MODEL" --no-mmproj; then
        warn "--no-mmproj 옵션 없이 다시 시도합니다."
        "${SERVE_CMD[0]}" download -hf "$MODEL"
    fi
fi

echo
log "다운로드 완료. 이제 ./start.sh 로 서버를 실행하세요."
