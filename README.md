# dotfiles

개인 개발 환경 설정 파일들.

## 설치

```bash
git clone git@github.com:jhwanchoi/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

## 포함된 설정

### .zshrc

| 명령어 | 설명 |
|--------|------|
| **Aliases** ||
| `ll` | ls -al |
| `clr` | clear |
| **Docker** ||
| `d` / `dc` | docker / docker compose |
| `dps` / `dpa` | 컨테이너 목록 (실행중 / 전체) |
| `di` | 이미지 목록 |
| `dlog` / `dex` | logs -f / exec -it |
| `dstop` / `drm` | stop / rm |
| `dcu` / `dcd` | compose up -d / down |
| **Kubernetes** ||
| `k` | kubectl |
| `kgp` / `kgs` / `kgd` / `kga` | get pods/svc/deploy/all |
| `klog` / `kex` | logs -f / exec -it |
| `kd` / `kdel` | describe / delete |
| `kctx` / `kctxs` | context 변경 / 목록 |
| `kns` / `knss` | namespace 변경 / 목록 |
| **AWS** ||
| `awswho [profile]` | AWS caller identity 확인 |
| `awsconfig <profile>` | AWS profile 전환 |
| **Ports** ||
| `ports` | 열린 포트 목록 (PORT/PID/PROCESS) |
| `killport <port>` | 지정한 포트의 프로세스 종료 |
| **File Utils** ||
| `peek <file> [lines]` | 파일 앞뒤 N줄 보기 (기본 20줄) |
| `search <pattern> [file]` | 파일 또는 현재 디렉토리에서 검색 |
| **Claude Code** ||
| `claude` | Claude 실행 (Bedrock 설정 시 확인 프롬프트) |
| `cc` | 모드 선택 후 Claude 실행 |
| `claude-bedrock-opus` | Bedrock Opus 4.5로 실행 (AWS 자동 로그인) |
| `claude-bedrock-sonnet` | Bedrock Sonnet 4.5로 실행 (AWS 자동 로그인) |
| **Dotfiles** ||
| `dotpush [msg]` | 설정 동기화 후 GitHub에 push (.claude/.codex/.gemini) |
| `dotpull` | 최신 dotfiles pull 및 설정 복원 |
| **기타** ||
| `cmds` | 전체 명령어 목록 보기 |

---

## @debate - Multi-Model Collaboration

Claude Code에서 여러 AI 모델이 협업하여 코드/설계를 검토하는 시스템.

### 사용법

```
@debate API 설계해줘
```

### 토론 흐름

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 @debate 시작 - Multi-Model Debate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1/4] 🎭 Claude (창작자) 제안:
───────────────────────────────────────────────────
(Claude의 초기 응답)

[2/4] 🔬 GPT (분석가) 검증 중...
───────────────────────────────────────────────────
(문제점, 엣지케이스, 보안 취약점 분석)

[3/4] 🔮 Gemini (현자) 최종 검토 중...
───────────────────────────────────────────────────
(Claude + GPT 의견 종합, 최종 권고)

[4/4] ⚖️ 종합 판결
───────────────────────────────────────────────────
(공통점, 충돌 해결, 핵심 개선사항 리스트)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Claude는 위 피드백을 반영하여 답변을 개선하세요.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 모델별 역할

| 모델 | 역할 | 제공자 |
|------|------|--------|
| 🎭 Claude | 창작자 - 초기 제안 | Anthropic (Subscription/Bedrock) |
| 🔬 GPT | 분석가 - 비판적 검증 | AWS Bedrock (GPT OSS 120B) |
| 🔮 Gemini | 현자 - 종합 판단 | Google (Gemini CLI) |
| ⚖️ 종합 | 재판관 - 최종 결론 | Gemini |

### 컨텍스트 한도

| 모델 | 입력 한도 |
|------|-----------|
| GPT OSS 120B | 100,000자 (~25K 토큰) |
| Gemini | 150,000자 (~50K 토큰) |

---

## CLI 설정

### .claude/

Claude Code 설정 및 hooks.

```
.claude/
├── settings.json              # 플러그인 설정
└── hooks/
    ├── multi-model-review.sh  # @debate 오케스트레이터
    ├── debate-step1-gpt.sh    # GPT 검증
    ├── debate-step2-gemini.sh # Gemini 검토
    └── debate-step3-synthesis.sh # 종합 판결
```

**플러그인:**
- claude-hud (statusline)
- mdpg-prompts (ai, backend, frontend, data, devops, mlops 등)
- atlassian

### .codex/

OpenAI Codex CLI 설정 (AWS Bedrock 연동).

```toml
# config.toml
profile = "bedrock-120b"

[profiles.bedrock-120b]
model = "openai.gpt-oss-120b-1:0"
model_provider = "bedrock"

[model_providers.bedrock]
name = "bedrock"
base_url = "https://bedrock-runtime.ap-northeast-1.amazonaws.com/openai/v1"
env_key = "BEDROCK_API_KEY"
wire_api = "chat"
```

### .gemini/

Google Gemini CLI 설정.

---

## 요구사항

### 필수
- zsh
- jq
- bun (claude-hud용)

### CLI 도구
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) - `npm install -g @google/gemini-cli`
- [Codex CLI](https://github.com/openai/codex) - `npm install -g @openai/codex`

### 선택
- AWS CLI (Bedrock 사용 시)
- Docker (docker 명령어 사용 시)
- kubectl (kubernetes 명령어 사용 시)

---

## 환경변수 (로컬 전용)

`~/.secrets` 파일에 저장 (git 추적 안 함):

```bash
# API Keys
export BEDROCK_API_KEY="your-bedrock-api-key"
```
