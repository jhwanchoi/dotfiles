# ============================================
# PATH
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ============================================
# ALIASES
# ============================================
alias ll='ls -al'
alias k='kubectl'
alias clr='clear'

# ============================================
# FUNCTIONS
# ============================================
# aws
awswho() { [[ -n "$1" ]] && aws sts get-caller-identity --profile "$1" || aws sts get-caller-identity; }
awsconfig() { export AWS_PROFILE=$1; echo "Switched to AWS profile: $1"; }

# claude code
_claude_check_aws() {
  if ! aws sts get-caller-identity --profile prod &>/dev/null; then
    echo "⚠ AWS prod profile not authenticated. Running: aws sso login --profile prod"
    aws sso login --profile prod || { echo "✗ AWS SSO login failed"; return 1; }
  fi
  [[ "$AWS_PROFILE" != "prod" ]] && export AWS_PROFILE=prod && echo "→ AWS_PROFILE=prod"
  return 0
}

_claude_set_subscription() {
  jq 'del(.env)' ~/.claude/settings.json > ~/.claude/settings.json.tmp \
    && mv ~/.claude/settings.json.tmp ~/.claude/settings.json \
    && echo "✓ Claude: Subscription mode"
}

_claude_set_bedrock() {
  local model="$1" name="$2"
  jq --arg m "$model" '.env = {CLAUDE_CODE_USE_BEDROCK: "1", AWS_REGION: "ap-northeast-2", ANTHROPIC_MODEL: $m}' \
    ~/.claude/settings.json > ~/.claude/settings.json.tmp \
    && mv ~/.claude/settings.json.tmp ~/.claude/settings.json \
    && echo "✓ Claude: Bedrock $name (ap-northeast-2)"
}

claude() {
  if grep -q "CLAUDE_CODE_USE_BEDROCK" ~/.claude/settings.json 2>/dev/null; then
    echo "⚠ Bedrock mode is currently configured."
    echo "  1) Continue with Bedrock (auto AWS login)"
    echo "  2) Switch to Subscription"
    echo "  3) Cancel"
    read "choice?Select [1-3]: "
    case $choice in
      1) _claude_check_aws || return 1 ;;
      2) _claude_set_subscription ;;
      3) return ;;
      *) echo "Invalid choice"; return 1 ;;
    esac
  fi
  command claude "$@"
}

claude-bedrock-opus() {
  _claude_check_aws || return 1
  _claude_set_bedrock "global.anthropic.claude-opus-4-5-20251101-v1:0" "Opus 4.5"
  command claude "$@"
}

claude-bedrock-sonnet() {
  _claude_check_aws || return 1
  _claude_set_bedrock "global.anthropic.claude-sonnet-4-5-20250929-v1:0" "Sonnet 4.5"
  command claude "$@"
}

cc() {
  echo "Select Claude mode:"
  select mode in "Subscription" "Bedrock Opus 4.5" "Bedrock Sonnet 4.5" "Cancel"; do
    case $mode in
      "Subscription")       _claude_set_subscription; command claude "$@" ;;
      "Bedrock Opus 4.5")   claude-bedrock-opus "$@" ;;
      "Bedrock Sonnet 4.5") claude-bedrock-sonnet "$@" ;;
      "Cancel")             return ;;
    esac
    break
  done
}

# ports
ports() {
  echo "PORT\tPID\tPROCESS"
  lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1 {split($9,a,":"); printf "%s\t%s\t%s\n", a[length(a)], $2, $1}' | sort -n | uniq
}

killport() {
  local pid=$(lsof -ti:$1 2>/dev/null)
  [[ -z "$pid" ]] && echo "Port $1 not in use" && return
  echo "Killing PID $pid on port $1"
  kill -9 $pid && echo "Done"
}

# file utils
peek() {
  local file="$1" lines="${2:-20}"
  echo "=== HEAD $lines ==="
  head -n $lines "$file"
  echo "\n=== TAIL $lines ==="
  tail -n $lines "$file"
}

search() {
  local pattern="$1" file="$2"
  if [[ -z "$file" ]]; then
    grep -rn --color=always "$pattern" . 2>/dev/null | awk -F: '
      $1 != prev { if (prev) print ""; print "\033[1;36m" $1 "\033[0m"; prev = $1 }
      { $1 = ""; sub(/^:/, ""); print "  " $0 }
    '
  else
    grep -n --color=auto "$pattern" "$file"
  fi
}

# dotfiles
dotpush() {
  cp ~/.zshrc ~/dotfiles/.zshrc
  cd ~/dotfiles && git add -A && git commit -m "${1:-Update dotfiles}" && git push
  cd - > /dev/null
  echo "✓ Dotfiles pushed"
}

dotpull() {
  cd ~/dotfiles && git pull
  cd - > /dev/null
  ~/dotfiles/install.sh
}

# help
cmds() {
  cat <<'EOF'
== Aliases ==
  ll                         ls -al
  k                          kubectl
  clr                        clear

== AWS ==
  awswho [profile]           Show AWS caller identity
  awsconfig <profile>        Switch AWS profile

== Ports ==
  ports                      List all listening ports (PORT/PID/PROCESS)
  killport <port>            Kill process on specified port

== File Utils ==
  peek <file> [lines]        Show head & tail of file (default 20 lines)
  search <pattern> [file]    Search pattern in file or current dir

== Claude Code ==
  claude                     Launch Claude (prompts if Bedrock configured)
  cc                         Interactive mode selector
  claude-bedrock-opus        Bedrock Opus 4.5 (auto AWS login)
  claude-bedrock-sonnet      Bedrock Sonnet 4.5 (auto AWS login)

== Dotfiles ==
  dotpush [msg]              Push .zshrc changes to GitHub
  dotpull                    Pull latest and install
EOF
}

# ============================================
# KEYBINDINGS
# ============================================
bindkey '^[[13;2u' self-insert-unmeta

# ============================================
# COMPLETIONS
# ============================================
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ============================================
# PLUGINS / TOOLS
# ============================================
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# ============================================
# STARTUP
# ============================================
cmds
