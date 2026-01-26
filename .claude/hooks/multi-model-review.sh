#!/bin/bash
# ============================================
# @debate - Multi-Model Debate Orchestrator
# Claude 🎭 → GPT 🔬 → Gemini 🔮 → 종합 ⚖️
# 단계별 실행 및 출력
# ============================================

HOOKS_DIR="$HOME/.claude/hooks"
STATE_DIR="$HOOKS_DIR/debate-state"
DEBUG_LOG="/tmp/claude-debate-debug.log"

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# 무한루프 방지
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# transcript 파일 확인
[[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]] && exit 0

# 마지막 사용자 메시지와 Claude 응답 추출
LAST_USER=$(jq -s '[.[] | select(.type == "user")] | last | .message.content // empty' "$TRANSCRIPT_PATH" 2>/dev/null)
LAST_ASSISTANT=$(jq -s '[.[] | select(.type == "assistant")] | last | .message.content | if type == "array" then [.[] | select(.type == "text") | .text] | join("\n") else . end // empty' "$TRANSCRIPT_PATH" 2>/dev/null)

# ============================================
# @debate 키워드 체크 (유일한 트리거 조건)
# ============================================
if ! echo "$LAST_USER" | grep -qi "@debate"; then
    exit 0
fi

echo "$(date): @debate triggered" >> "$DEBUG_LOG"

# Claude 응답 전달 (GPT 128K tokens, Gemini 1M tokens 지원)
# GPT에게: 100K chars (~25K tokens)
# 화면 표시용: 2000 chars
CLAUDE_PROPOSAL=$(echo "$LAST_ASSISTANT" | head -c 100000)
CLAUDE_SUMMARY=$(echo "$LAST_ASSISTANT" | head -c 2000)

# ============================================
# 토론 시작 헤더
# ============================================
{
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎯 @debate 시작 - Multi-Model Debate"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
} >&2

# ============================================
# Step 1: Claude 제안 표시
# ============================================
{
    echo ""
    echo "[1/4] 🎭 Claude (창작자) 제안:"
    echo "───────────────────────────────────────────────────"
    echo "$CLAUDE_SUMMARY" | fold -s -w 60 | head -20
    [[ ${#LAST_ASSISTANT} -gt 2000 ]] && echo "  ... ($(( ${#LAST_ASSISTANT} - 2000 ))자 더 있음, 전체 전달됨)"
    echo ""
} >&2

# ============================================
# Step 2: GPT 검증
# ============================================
{
    echo "[2/4] 🔬 GPT (분석가) 검증 중..."
    echo "───────────────────────────────────────────────────"
} >&2

GPT_RESULT=$("$HOOKS_DIR/debate-step1-gpt.sh" "$CLAUDE_PROPOSAL" 2>/dev/null)
if [[ -z "$GPT_RESULT" ]]; then
    GPT_RESULT="(GPT 응답 시간 초과 또는 오류)"
fi

# GPT 결과 저장 및 출력
echo "$GPT_RESULT" > "$STATE_DIR/gpt-result.txt"
{
    echo "$GPT_RESULT"
    echo ""
} >&2

echo "$(date): GPT step completed" >> "$DEBUG_LOG"

# ============================================
# Step 3: Gemini 검토
# ============================================
{
    echo "[3/4] 🔮 Gemini (현자) 최종 검토 중..."
    echo "───────────────────────────────────────────────────"
} >&2

GEMINI_RESULT=$("$HOOKS_DIR/debate-step2-gemini.sh" "$CLAUDE_PROPOSAL" "$GPT_RESULT" 2>/dev/null)
if [[ -z "$GEMINI_RESULT" ]]; then
    GEMINI_RESULT="(Gemini 응답 시간 초과 또는 오류)"
fi

# Gemini 결과 저장 및 출력
echo "$GEMINI_RESULT" > "$STATE_DIR/gemini-result.txt"
{
    echo "$GEMINI_RESULT"
    echo ""
} >&2

echo "$(date): Gemini step completed" >> "$DEBUG_LOG"

# ============================================
# Step 4: 종합 판결
# ============================================
{
    echo "[4/4] ⚖️ 종합 판결"
    echo "───────────────────────────────────────────────────"
} >&2

SYNTHESIS=$("$HOOKS_DIR/debate-step3-synthesis.sh" "$CLAUDE_SUMMARY" "$GPT_RESULT" "$GEMINI_RESULT" 2>/dev/null)
if [[ -z "$SYNTHESIS" ]]; then
    SYNTHESIS="GPT와 Gemini 피드백을 종합하여 개선하세요."
fi

# 종합 결과 저장 및 출력
echo "$SYNTHESIS" > "$STATE_DIR/synthesis.txt"
{
    echo "$SYNTHESIS"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Claude는 위 피드백을 반영하여 답변을 개선하세요."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
} >&2

echo "$(date): @debate completed" >> "$DEBUG_LOG"

# Claude에게 피드백 전달
exit 2
