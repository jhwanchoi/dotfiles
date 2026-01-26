#!/bin/bash
# Step 1: GPT 분석가 검증
# Input: $1 = Claude 제안 (요약본)
# Output: GPT 검증 결과

CLAUDE_PROPOSAL="$1"
# GPT OSS 120B: 128K tokens (~500K chars) 지원
# 안전하게 100K chars (~25K tokens) 로 설정
MAX_INPUT=100000

# 입력 길이 제한
CLAUDE_PROPOSAL=$(echo "$CLAUDE_PROPOSAL" | head -c $MAX_INPUT)

GPT_PROMPT="당신은 엄격한 코드/설계 분석가입니다. 다음 제안을 비판적으로 검토하세요.
문제점, 엣지케이스, 성능 이슈, 보안 취약점을 찾아주세요.
(한국어, 5줄 이내, 핵심만)

=== Claude의 제안 ===
$CLAUDE_PROPOSAL"

RESULT=$(echo "$GPT_PROMPT" | codex exec --profile bedrock-120b --skip-git-repo-check - 2>&1 &
PID=$!
sleep 90 && kill $PID 2>/dev/null &
wait $PID 2>/dev/null) || true

# 결과 정제
echo "$RESULT" \
    | grep -v "^OpenAI Codex\|^--------\|^workdir:\|^model:\|^provider:\|^approval:\|^sandbox:\|^session id:\|^deprecated:\|^mcp startup:\|^user$\|^codex$\|^reasoning effort:\|^reasoning summaries:" \
    | sed 's/<reasoning>[^<]*<\/reasoning>//g' \
    | sed '/^$/d' \
    | tail -10
