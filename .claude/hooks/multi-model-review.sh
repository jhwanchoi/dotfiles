#!/bin/bash
# Multi-Model Review Hook
# Claude 응답 후 GPT/Gemini로 자동 검증

DEBUG_LOG="/tmp/claude-hook-debug.log"
REVIEW_OUTPUT="/tmp/claude-review-output.txt"

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# 무한루프 방지
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# transcript 파일 확인
[[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]] && exit 0

# 마지막 사용자 메시지와 Claude 응답 추출
LAST_USER=$(jq -s '[.[] | select(.type == "user")] | last | .message.content // empty' "$TRANSCRIPT_PATH" 2>/dev/null)
LAST_ASSISTANT=$(jq -s '[.[] | select(.type == "assistant")] | last | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] | join("\n") else . end // empty' "$TRANSCRIPT_PATH" 2>/dev/null | head -c 5000)

# ============================================
# 실질적인 조건 체크
# ============================================

# 1. 응답이 200자 미만이면 스킵 (의미있는 내용이 아님)
[[ ${#LAST_ASSISTANT} -lt 200 ]] && { echo "$(date): Skip - too short (${#LAST_ASSISTANT} chars)" >> "$DEBUG_LOG"; exit 0; }

# 2. 사용자 요청 키워드 체크 (코드/설계/구현 관련)
USER_KEYWORDS="구현|implement|작성|write|만들|create|수정|modify|fix|버그|bug|추가|add|삭제|delete|remove|리팩|refactor|설계|design|아키텍처|architecture|최적화|optimiz|테스트|test|API|함수|function|클래스|class|모듈|module|컴포넌트|component|스키마|schema|마이그|migrat|배포|deploy|설정|config"

if ! echo "$LAST_USER" | grep -qiE "$USER_KEYWORDS"; then
    echo "$(date): Skip - no action keywords in user message" >> "$DEBUG_LOG"
    exit 0
fi

# 3. Claude 응답에 코드가 포함되어 있는지 체크 (``` 또는 실제 코드 패턴)
HAS_CODE=false
if echo "$LAST_ASSISTANT" | grep -qE '```|def |function |class |const |let |var |import |from |export |return |if \(|for \(|while \('; then
    HAS_CODE=true
fi

# 4. 코드가 없으면 설계/아키텍처 관련 키워드 체크
DESIGN_KEYWORDS="구조|structure|패턴|pattern|레이어|layer|서비스|service|모델|model|인터페이스|interface|의존성|dependency|모듈|module"

if [[ "$HAS_CODE" == "false" ]]; then
    if ! echo "$LAST_ASSISTANT" | grep -qiE "$DESIGN_KEYWORDS"; then
        echo "$(date): Skip - no code or design content" >> "$DEBUG_LOG"
        exit 0
    fi
fi

echo "$(date): Proceeding with review (len=${#LAST_ASSISTANT}, hasCode=$HAS_CODE)" >> "$DEBUG_LOG"

# ============================================
# 리뷰 실행
# ============================================

REVIEW_PROMPT="다음 코드/설계 내용을 검토하고 잠재적 문제점이나 개선사항을 지적해줘 (한국어, 3줄 이내, 핵심만):

$LAST_ASSISTANT"

# 리뷰 결과 수집
REVIEW_RESULT=""

# Gemini 리뷰
GEMINI_RESULT=$(gemini -p "$REVIEW_PROMPT" 2>/dev/null | grep -v "^Loaded cached" | head -10)
if [[ -n "$GEMINI_RESULT" ]]; then
    REVIEW_RESULT+="✅ [Gemini]:
$GEMINI_RESULT

"
fi

# Codex 리뷰 (reasoning 태그 제거, timeout 대신 & + sleep + kill)
CODEX_RESULT=$(echo "$REVIEW_PROMPT" | codex exec --profile bedrock-20b --skip-git-repo-check - 2>&1 &
CODEX_PID=$!
sleep 25 && kill $CODEX_PID 2>/dev/null &
wait $CODEX_PID 2>/dev/null) || true

CODEX_RESULT=$(echo "$CODEX_RESULT" \
    | grep -v "^OpenAI Codex\|^--------\|^workdir:\|^model:\|^provider:\|^approval:\|^sandbox:\|^session id:\|^deprecated:\|^mcp startup:\|^user$\|^codex$" \
    | sed 's/<reasoning>[^<]*<\/reasoning>//g' \
    | sed '/^$/d' \
    | tail -10)

if [[ -n "$CODEX_RESULT" ]]; then
    REVIEW_RESULT+="🔍 [Codex]:
$CODEX_RESULT"
fi

# 결과가 있으면 stderr로 출력하고 exit 2 (Claude에게 전달)
if [[ -n "$REVIEW_RESULT" ]]; then
    echo "" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🔄 Multi-Model Review" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "$REVIEW_RESULT" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

    echo "$(date): Review sent to Claude" >> "$DEBUG_LOG"
    exit 2  # stderr를 Claude에게 전달
fi

echo "$(date): No review result" >> "$DEBUG_LOG"
