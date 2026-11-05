# llama.cpp 로컬 AI 채팅 — 초보자 사용 설명서

이 폴더에는 **내 컴퓨터에서 직접 AI와 대화할 수 있는 프로그램**이 들어 있습니다.
인터넷이나 클라우드 서비스 없이, CPU만으로 한국어 대화가 가능합니다.

- 브라우저에서 채팅 화면(Web UI)을 열어 사용합니다.
- GPU(CUDA)는 필요 없습니다.
- **Linux, macOS, Windows(WSL2)** 에서 동작합니다.
- 한 번 설치하면 다음부터는 **켜고 → 브라우저 접속 → 끄기**만 하면 됩니다.

> **이미 설치와 모델 다운로드를 마쳤다면** [2. 지금 바로 사용하기](#2-지금-바로-사용하기)로 이동하세요.
> 처음 설치한다면 [3. 처음부터 설치하는 방법](#3-처음부터-설치하는-방법)부터 보세요.

---

## 목차

1. [이게 뭔가요?](#1-이게-뭔가요)
2. [지금 바로 사용하기](#2-지금-바로-사용하기)
3. [처음부터 설치하는 방법](#3-처음부터-설치하는-방법)
4. [채팅 화면 사용법](#4-채팅-화면-사용법)
5. [매일 사용하는 방법 요약](#5-매일-사용하는-방법-요약)
6. [설정 바꾸기](#6-설정-바꾸기)
7. [자주 발생하는 문제](#7-자주-발생하는-문제)
8. [초보자를 위한 용어 설명](#8-초보자를-위한-용어-설명)
9. [고급: API로 사용하기](#9-고급-api로-사용하기)
10. [파일 구조](#10-파일-구조)

---

## 1. 이게 뭔가요?

| 용어 | 쉬운 설명 |
|---|---|
| **llama.cpp** | 내 컴퓨터에서 AI 모델을 실행해 주는 프로그램 |
| **모델** | AI의 "두뇌" 파일. 이 폴더에서는 Qwen3.5-4B를 사용합니다. |
| **Web UI** | 브라우저에서 열리는 채팅 화면 |
| **서버** | 채팅 화면과 AI를 연결해 주는 프로그램. 켜 두어야 대화할 수 있습니다. |

### 검증 환경과 성능 예시

| 항목 | 내용 |
|---|---|
| 검증 CPU | Intel Xeon Silver 4210R (10코어) |
| 메모리 사용 | 약 4.3GB |
| 답변 속도 | 약 **5.5 tok/s** (1초에 5~6토큰, 한국어 기준 대략 3~5단어) |
| 모델 | Qwen3.5-4B Q4_K_M (약 2.7GB) |
| 한국어 | 지원 (일상 대화, 번역, 요약 등) |

> 위 수치는 이 저장소를 만든 PC 기준입니다. **CPU 성능에 따라 속도와 메모리 사용량은 달라집니다.**
> 답변이 느리게 느껴지는 것은 CPU만 사용하기 때문이며 정상입니다.
> 더 빠른 답변을 원하면 [6. 설정 바꾸기](#6-설정-바꾸기)에서 더 작은 모델로 바꿀 수 있습니다.

### 지원 환경

| OS | 지원 | 비고 |
|---|---|---|
| Linux (Ubuntu, Debian, Fedora, Arch 등) | ✅ | x86_64 / arm64 |
| macOS (Apple Silicon, Intel) | ✅ | `curl`, `tar` 기본 포함 |
| Windows | ✅ (WSL2) | Ubuntu 터미널에서 사용 |
| Windows (명령 프롬프트/PowerShell) | ❌ | WSL2를 사용하세요 |

필요한 것: `bash`, `curl`, `tar`, 디스크 여유 공간 5GB 이상, RAM 8GB 이상(16GB 권장)

---

## 2. 지금 바로 사용하기

### 2-1. 터미널 열기

| OS | 방법 |
|---|---|
| Ubuntu/Linux | **`Ctrl` + `Alt` + `T`** |
| macOS | Spotlight(`Cmd` + `Space`) → `Terminal` 검색 |
| Windows | WSL2 Ubuntu 터미널 실행 (Windows Terminal에서 Ubuntu 선택) |

macOS에서 `cd ~/llama-chat`이 안 되면, Finder에서 저장소를 내려받은 위치를 확인하세요.

### 2-2. 이 폴더로 이동

터미널에 아래를 입력하고 `Enter`:

```bash
cd ~/llama-chat
```

> `cd`는 "폴더로 이동"이라는 뜻입니다.

### 2-3. 서버 켜기

```bash
./start.sh
```

아래처럼 나오면 성공입니다:

```
[llama-chat] 준비 완료!
  Web UI : http://127.0.0.1:8080
  API    : http://127.0.0.1:8080/v1  (OpenAI 호환)
  종료   : ./stop.sh
```

> 처음 켤 때는 모델을 메모리에 올리느라 1~2분 정도 걸릴 수 있습니다.
> `준비 완료!` 가 나올 때까지 기다리세요.

### 2-4. 브라우저에서 접속

인터넷 브라우저(Firefox, Chrome 등) 주소창에 입력:

```
http://127.0.0.1:8080
```

채팅 화면이 나오면 바로 사용할 수 있습니다.

### 2-5. 서버 끄기

터미널에서:

```bash
./stop.sh
```

> 브라우저 탭을 닫는 것만으로는 서버가 꺼지지 않습니다.
> 사용이 끝나면 `./stop.sh`로 끄면 메모리를 돌려받을 수 있습니다.

---

## 3. 처음부터 설치하는 방법

> **이미 이 저장소를 내려받았다면 3-2로 건너뛰세요.**
> 인터넷 연결이 필요하고, 모델 다운로드에 약 2.7GB를 받습니다.

### 3-1. 저장소 내려받기 (git)

```bash
git clone https://github.com/pdh930105/llama-chat.git
cd llama-chat
```

- `git`이 없다면: Ubuntu는 `sudo apt install -y git`, macOS는 `xcode-select --install`
- 이후 이 폴더로 이동할 때는 `cd ~/llama-chat` (내려받은 위치에 맞게 수정)

### 3-2. 설치 (최초 1회)

먼저 설치 없이 스크립트 상태를 점검할 수 있습니다:

```bash
./test.sh
```

문법과 설정 감지만 확인하며, 아무것도 설치하지 않습니다.

```bash
./install.sh
```

- Linux/macOS 공통으로 llama.cpp 공식 설치 스크립트를 사용합니다.
- 공식 설치가 실패하면 OS/CPU에 맞는 GitHub 릴리스 바이너리로 자동 대체합니다.
- 설치 위치: `~/.local/bin/llama`
- "이미 llama.cpp가 설치되어 있습니다"라고 나오면 건너뛰어도 됩니다.

### 3-3. 모델 다운로드 (최초 1회)

```bash
./download-model.sh
```

- AI 모델(약 2.7GB)을 내려받습니다.
- 저장 위치: `~/.cache/huggingface/hub`
- 다운로드가 끝나면 `다운로드 완료` 메시지가 나옵니다.

### 3-4. 실행

```bash
./start.sh
```

그다음 [2-4. 브라우저에서 접속](#2-4-브라우저에서-접속)과 같습니다.

### 3-5. 만약 "Permission denied"가 나오면

스크립트에 실행 권한이 없는 경우입니다. 한 번만 실행하세요:

```bash
chmod +x *.sh
```

---

## 4. 채팅 화면 사용법

1. 브라우저에서 `http://127.0.0.1:8080` 접속
2. 화면에 모델 이름 **`qwen3.5-4b`** 가 보이는지 확인
   - 안 보이면 모델 선택 목록에서 `qwen3.5-4b`를 고르세요.
3. 아래쪽 입력창에 질문을 입력하고 `Enter` 또는 전송 버튼
4. 답변이 한 글자씩 나타납니다. (CPU라서 조금 느립니다)

### 입력 예시

```text
안녕하세요. 자기소개 해 주세요.
```

```text
다음 문장을 영어로 번역해 줘: 오늘 날씨가 정말 좋네요.
```

```text
파이썬으로 1부터 10까지 더하는 코드를 짜 줘.
```

### 알아두면 좋은 점

- **대화 기록은 서버를 끄면 사라집니다.** (파일로 저장되지 않습니다)
- 새 대화를 시작하려면 화면의 **New Chat / 새 대화** 버튼을 사용하세요.
- 이미지 입력은 꺼 두었습니다. (CPU에서 느리고 메모리를 많이 사용합니다)
- 답변 도중 멈추고 싶으면 화면의 **Stop / 중지** 버튼을 누르세요.

---

## 5. 매일 사용하는 방법 요약

| 하고 싶은 일 | 터미널 명령 |
|---|---|
| 서버 켜기 | `cd ~/llama-chat` → `./start.sh` |
| 채팅 화면 열기 | 브라우저에서 `http://127.0.0.1:8080` |
| 서버 끄기 | `./stop.sh` |
| 실행 중인지 확인 | `curl http://127.0.0.1:8080/health` |
| 설치 전 점검 | `./test.sh` |
| 로그 보기 | `tail -f logs/llama-server.log` |

> 서버가 이미 켜져 있는데 `./start.sh`를 다시 실행하면
> "이미 실행 중입니다"라고 안내하고 브라우저 주소를 알려 줍니다.

---

## 6. 설정 바꾸기

설정은 `config.sh` 파일에 있습니다.
초보자는 아래 정도만 알아도 충분합니다.

### 6-1. 설정 파일 여는 방법 (vim)

터미널에서:

```bash
cd ~/llama-chat
vim config.sh
```

vim이 처음이라면 아래 순서만 기억하세요.

1. **`i` 키**를 누릅니다. → 화면 아래에 `-- INSERT --`가 표시되면 입력 모드입니다.
2. 화살표 키로 이동해서 원하는 값을 수정합니다.
3. 수정이 끝나면 **`Esc` 키**를 누릅니다. → 입력 모드가 끝납니다.
4. **`:wq`** 를 입력하고 `Enter`를 누릅니다. → 저장하고 vim을 종료합니다.

| 하고 싶은 일 | vim 명령 |
|---|---|
| 입력/수정 시작 | `i` |
| 입력 종료 | `Esc` |
| 저장하고 종료 | `:wq` + `Enter` |
| 저장만 하기 | `:w` + `Enter` |
| 저장하지 않고 종료 | `:q!` + `Enter` |

> `Esc`를 누른 뒤 `:`(콜론)을 입력해야 명령이 들어갑니다.
> 실수로 잘못 입력했다면 `Esc` → `u`를 눌러 실행 취소할 수 있습니다.
>
> 수정 후에는 서버를 껐다 켜야 적용됩니다: `./stop.sh` → `./start.sh`

### 6-2. 자주 바꾸는 설정

| 설정 | 기본값 | 설명 |
|---|---|---|
| `PORT` | `8080` | 브라우저 주소의 포트 번호 |
| `CTX_SIZE` | `4096` | AI가 한 번에 기억하는 대화 길이 |
| `THREADS` | 10 | 답변 생성에 쓸 CPU 코어 수 |
| `REASONING` | `off` | 생각 과정 표시 여부 (`off`가 빠름) |

예를 들어 포트를 9000으로 바꾸면 브라우저 주소도 `http://127.0.0.1:9000`이 됩니다.

### 6-3. 더 빠른 모델로 바꾸기 (선택)

답변이 너무 느리면 더 작은 모델을 사용할 수 있습니다.
아래 명령은 **0.8B 모델(약 0.53GB)** 로 바꾸는 예시입니다.

```bash
cd ~/llama-chat
./stop.sh

MODEL_REPO=unsloth/Qwen3.5-0.8B-GGUF \
MODEL_QUANT=Q4_K_M \
MODEL_ALIAS=qwen3.5-0.8b \
./download-model.sh

MODEL_REPO=unsloth/Qwen3.5-0.8B-GGUF \
MODEL_QUANT=Q4_K_M \
MODEL_ALIAS=qwen3.5-0.8b \
./start.sh
```

| 모델 | 크기 | 특징 |
|---|---|---|
| Qwen3.5-0.8B | 0.53GB | 가장 빠름, 품질은 낮음 |
| Qwen3.5-2B | 1.28GB | 빠름, 품질 중간 |
| **Qwen3.5-4B (기본)** | 2.7GB | 느리지만 품질 좋음 |
| EXAONE-4.0-1.2B | 0.81GB | 한국어 특화, 라이선스 확인 필요 |
| Kanana-2-3B | 2.16GB | 한국어 특화, 비공식 GGUF, 라이선스 확인 필요 |

> 모델을 바꿀 때는 `download-model.sh`와 `start.sh`에 **같은 환경변수**를 넣어야 합니다.
> 매번 입력하기 번거로우면 `config.sh`의 `MODEL_REPO`, `MODEL_QUANT`, `MODEL_ALIAS`를 직접 수정하세요.

### 6-4. 같은 네트워크의 다른 기기에서 접속 (고급)

기본값은 이 컴퓨터에서만 접속할 수 있습니다.
휴대폰이나 다른 PC에서 접속하려면 `config.sh`에서:

```bash
HOST=0.0.0.0
API_KEY=my-secret
```

- 접속 주소: `http://<이 컴퓨터의 IP>:8080`
- **API_KEY 없이 외부에 공개하지 마세요.**

---

## 7. 자주 발생하는 문제

### "그런 파일이나 디렉터리가 없습니다" / "No such file or directory"

폴더 위치가 다를 수 있습니다. 먼저 이동하세요:

```bash
cd ~/llama-chat
ls
```

`install.sh`, `start.sh` 등이 보이면 정상입니다.

### "Permission denied"

```bash
chmod +x *.sh
```

### 브라우저에서 접속이 안 됩니다

1. 터미널에 `준비 완료!`가 나왔는지 확인
2. 서버가 켜져 있는지 확인:

```bash
curl http://127.0.0.1:8080/health
```

`{"status":"ok"}` 가 나오면 서버는 정상입니다.
3. 주소가 `http://127.0.0.1:8080`이 맞는지 확인 (`https` 아님)
4. 그래도 안 되면 서버를 껐다 켜세요: `./stop.sh` → `./start.sh`

### "포트 8080이 이미 사용 중입니다"

다른 프로그램이 8080을 쓰고 있습니다.

- 이미 이 서버가 켜져 있는지 확인: `./start.sh`를 다시 실행하면 안내가 나옵니다.
- 아니면 `config.sh`에서 `PORT`를 `8081` 등으로 바꾸세요.

### 답변이 너무 느립니다

- CPU만 사용해서 생기는 정상적인 속도입니다.
- `config.sh`에서 `REASONING=off`인지 확인하세요. (`on`이면 매우 느려집니다)
- 더 작은 모델(0.8B/2B)로 바꾸면 빨라집니다.

### 메모리가 부족하다는 오류가 납니다

`config.sh`에서:

```bash
CTX_SIZE=2048
```

로 낮추고 서버를 다시 켜세요. 다른 무거운 프로그램도 종료해 주세요.

### 모델 다운로드가 실패합니다

인터넷 연결을 확인하세요. 사내망/프록시 환경이라면 터미널에서:

```bash
export HTTPS_PROXY=http://프록시주소:포트
./download-model.sh
```

### 로그를 보고 싶습니다

```bash
tail -f logs/llama-server.log
```

- `Ctrl` + `C` 로 로그 보기에서 빠져나옵니다.
- 서버가 갑자기 꺼졌다면 이 로그의 마지막 부분에 원인이 나옵니다.

---

## 8. 초보자를 위한 용어 설명

| 용어 | 설명 |
|---|---|
| **터미널** | 명령어를 입력하는 검은 창 |
| **명령어** | 터미널에 입력하는 글. `Enter`로 실행 |
| **`cd`** | 폴더를 이동하는 명령 |
| **`./start.sh`** | 현재 폴더의 `start.sh` 파일을 실행 |
| **모델** | AI의 두뇌 파일 (`.gguf`) |
| **GGUF** | llama.cpp에서 사용하는 모델 파일 형식 |
| **양자화(Quantization)** | 모델을 압축해 메모리를 적게 쓰는 기술. `Q4_K_M`은 4비트 압축 |
| **컨텍스트(Context)** | AI가 한 번에 기억할 수 있는 대화 길이. `4096`은 영어 기준 약 3,000단어 (한국어는 그보다 적음) |
| **토큰(Token)** | AI가 글을 처리하는 단위. 한국어는 대략 1~2글자 |
| **tok/s** | 1초에 생성하는 토큰 수. 높을수록 빠름 |
| **서버** | AI와 채팅 화면을 연결하는 프로그램 |
| **Web UI** | 브라우저에서 보이는 채팅 화면 |
| **API** | 다른 프로그램이 AI를 사용할 수 있게 해 주는 창구 |

---

## 9. 고급: API로 사용하기

프로그램에서 AI를 호출할 때 사용합니다. (초보자는 건너뛰어도 됩니다)

```bash
curl http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen3.5-4b",
    "messages": [
      {"role": "user", "content": "안녕하세요! 한국어로 자기소개 해줘."}
    ]
  }'
```

Python 예시:

```python
from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:8080/v1", api_key="not-needed")
res = client.chat.completions.create(
    model="qwen3.5-4b",
    messages=[{"role": "user", "content": "오늘 서울 날씨에 대해 알려줘."}],
)
print(res.choices[0].message.content)
```

주요 주소:

- `GET /health` — 서버 상태 확인
- `GET /v1/models` — 사용 가능한 모델 목록
- `POST /v1/chat/completions` — 채팅 요청

> 터미널에서 Web UI 주소(`/`)를 `curl`로 확인하면 `415` 오류가 날 수 있습니다.
> Web UI는 gzip 압축을 요구하기 때문이며, 브라우저에서는 정상입니다.
> 확인하려면 `curl --compressed http://127.0.0.1:8080/` 를 사용하세요.

---

## 10. 파일 구조

```text
llama-chat/
├── README.md           이 설명서
├── LICENSE             MIT 라이선스
├── config.sh           설정 파일 (모델, 포트, 스레드 등)
├── install.sh          llama.cpp 설치 (최초 1회)
├── download-model.sh   모델 다운로드 (최초 1회)
├── start.sh            서버 켜기
├── stop.sh             서버 끄기
├── test.sh             설치 없이 문법/설정 검사
├── lib.sh              공통 기능 (직접 실행하지 않음)
├── .github/workflows/  Linux/macOS 자동 테스트 (GitHub Actions)
└── logs/
    └── llama-server.log  실행 로그
```

### 아직 안 되는 것 / 제한

- Windows 명령 프롬프트(PowerShell)에서는 직접 실행되지 않습니다. **WSL2 Ubuntu**를 사용하세요.
  ```powershell
  wsl --install -d Ubuntu
  ```
- macOS/Linux 모두 **CPU 추론만** 사용합니다. GPU 가속은 설정하지 않았습니다.
- 첫 실행 시 모델 다운로드(약 2.7GB)와 로딩 때문에 시간이 걸립니다.

### 실제 설치되는 위치
| 항목 | 위치 |
|---|---|
| llama.cpp 실행 파일 | `~/.local/bin/llama` |
| 모델 파일 | `~/.cache/huggingface/hub` |
| 서버 로그 | `logs/llama-server.log` |
| 서버 PID | `llama-server.pid` |

### 수동 설치/업데이트 (고급)

```bash
# 이 저장소 최신 버전으로 업데이트
cd ~/llama-chat
git pull

# llama.cpp 업데이트
llama update

# 소스에서 직접 빌드하는 경우
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build -DGGML_NATIVE=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
./build/bin/llama-server -hf unsloth/Qwen3.5-4B-GGUF:Q4_K_M --no-mmproj -c 4096
```

이 경우 `start.sh`가 `llama.cpp/build/bin/llama-server`를 자동으로 찾습니다.

---

## 참고: 이 구성의 라이선스

- llama.cpp: MIT
- Qwen3.5-4B: Apache-2.0 (상업적 사용 가능)
- EXAONE, Kanana 모델을 사용할 경우 각 모델의 라이선스를 별도로 확인하세요.
