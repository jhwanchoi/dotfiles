#!/bin/bash
# Step 2: Gemini 현자 최종 검토
# Input: $1 = Claude 제안 (요약본), $2 = GPT 검증 결과
# Output: Gemini 검토 결과

CLAUDE_PROPOSAL="$1"
GPT_RESULT="$2"
# Gemini: 1M tokens (~4M chars) 지원
# 안전하게 200K chars (~50K tokens) 로 설정
MAX_CLAUDE=150000
MAX_GPT=50000

# 입력 길이 제한
CLAUDE_PROPOSAL=$(echo "$CLAUDE_PROPOSAL" | head -c $MAX_CLAUDE)
GPT_RESULT=$(echo "$GPT_RESULT" | head -c $MAX_GPT)

GEMINI_PROMPT="당신은 현명한 중재자입니다. Claude의 제안과 GPT의 검증 의견을 모두 고려하여 최종 판단을 내려주세요.
동의하는 부분, 추가 우려사항, 최종 권고안을 제시하세요.
(한국어, 5줄 이내, 핵심만)

=== Claude의 제안 ===
$CLAUDE_PROPOSAL

=== GPT의 검증 의견 ===
$GPT_RESULT"

gemini -p "$GEMINI_PROMPT" 2>/dev/null | grep -v "^Loaded cached" | head -10
