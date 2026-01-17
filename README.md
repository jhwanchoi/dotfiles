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
| `dotpush [msg]` | .zshrc 변경사항을 GitHub에 push |
| `dotpull` | 최신 dotfiles pull 받아서 설치 |
| **기타** ||
| `cmds` | 전체 명령어 목록 보기 |

### .claude/settings.json

Claude Code 플러그인 설정:
- claude-hud (statusline)
- mdpg-prompts (ai, backend, frontend, data, devops, mlops 등)
- atlassian

## 요구사항

- zsh
- jq
- bun (claude-hud용)
- AWS CLI (Bedrock 사용 시)
