#!/bin/bash
# Step 3: 종합 판결
# Input: $1 = Claude 요약, $2 = GPT 결과, $3 = Gemini 결과
# Output: 최종 종합 판결

CLAUDE_SUMMARY="$1"
GPT_RESULT="$2"
GEMINI_RESULT="$3"
# Gemini: 1M tokens 지원
# 종합은 요약된 내용이므로 각 50K chars로 충분
MAX_INPUT=50000

# 입력 길이 제한
CLAUDE_SUMMARY=$(echo "$CLAUDE_SUMMARY" | head -c $MAX_INPUT)
GPT_RESULT=$(echo "$GPT_RESULT" | head -c $MAX_INPUT)
GEMINI_RESULT=$(echo "$GEMINI_RESULT" | head -c $MAX_INPUT)

SYNTHESIS_PROMPT="다음 토론 내용을 바탕으로 최종 결론을 내려주세요:
1. 세 의견의 공통점
2. 의견 충돌이 있다면 어느 쪽이 더 타당한지
3. Claude가 반영해야 할 핵심 개선사항 (번호 리스트)
(한국어, 5줄 이내)

=== Claude 제안 요약 ===
$CLAUDE_SUMMARY

=== GPT 의견 ===
$GPT_RESULT

=== Gemini 의견 ===
$GEMINI_RESULT"

gemini -p "$SYNTHESIS_PROMPT" 2>/dev/null | grep -v "^Loaded cached" | head -8
