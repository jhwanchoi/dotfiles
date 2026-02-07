# ============================================
# PATH
# ============================================
export PATH="$HOME/.local/bin:$PATH"
export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# ============================================
# SECRETS (API keys in ~/.secrets, not tracked by git)
# ============================================
[ -f ~/.secrets ] && source ~/.secrets

# ============================================
# ALIASES
# ============================================
alias ll='ls -al'
alias clr='clear'

# docker
alias d='docker'
alias dc='docker compose'
alias dlog='docker logs -f'
alias dex='docker exec -it'
alias dstop='docker stop'
alias drm='docker rm'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

# kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kga='kubectl get all'
alias klog='kubectl logs -f'
alias kex='kubectl exec -it'
alias kd='kubectl describe'
alias kdel='kubectl delete'
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# ============================================
# FUNCTIONS
# ============================================
# aws
awswho() { [[ -n "$1" ]] && aws sts get-caller-identity --profile "$1" || aws sts get-caller-identity; }
awsconfig() { export AWS_PROFILE=$1; echo "Switched to AWS profile: $1"; }

# claude code
_claude_check_aws() {
  if ! aws sts get-caller-identity --profile prod --no-verify-ssl &>/dev/null; then
    echo "⚠ AWS prod profile not authenticated. Please configure it using 'aws configure --profile prod' or ensure your credentials are valid."
    # aws sso login --profile prod || { echo "✗ AWS SSO login failed"; return 1; }
    return 1 # SSO를 사용하지 않으므로 인증되지 않았으면 실패 처리
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
  export NODE_TLS_REJECT_UNAUTHORIZED=0
  command claude "$@"
}

claude-bedrock-sonnet() {
  _claude_check_aws || return 1
  _claude_set_bedrock "global.anthropic.claude-sonnet-4-5-20250929-v1:0" "Sonnet 4.5"
  export NODE_TLS_REJECT_UNAUTHORIZED=0
  command claude "$@"
}

claude-bedrock-opus46() {
  _claude_check_aws || return 1
  _claude_set_bedrock "global.anthropic.claude-opus-4-6-v1" "Opus 4.6"
  export NODE_TLS_REJECT_UNAUTHORIZED=0
  command claude "$@"
}

cc() {
  echo "Select Claude mode:"
  select mode in "Subscription" "Bedrock Opus 4.6" "Bedrock Opus 4.5" "Bedrock Sonnet 4.5" "Cancel"; do
    case $mode in
      "Subscription")       _claude_set_subscription; command claude "$@" ;;
      "Bedrock Opus 4.6")   claude-bedrock-opus46 "$@" ;;
      "Bedrock Opus 4.5")   claude-bedrock-opus "$@" ;;
      "Bedrock Sonnet 4.5") claude-bedrock-sonnet "$@" ;;
      "Cancel")             return ;;
    esac
    break
  done
}

# list commands (pretty output)
ports() {
  echo "\033[1;36mPORT\tPID\tPROCESS\033[0m"
  echo "────\t───\t───────"
  lsof -iTCP -sTCP:LISTEN -nP 2>/dev/null | awk 'NR>1 {split($9,a,":"); printf "%s\t%s\t%s\n", a[length(a)], $2, $1}' | sort -n | uniq
}

dps() {
  echo "\033[1;36mCONTAINER\tIMAGE\t\tSTATUS\033[0m"
  echo "─────────\t─────\t\t──────"
  docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null
}

dpa() {
  echo "\033[1;36mCONTAINER\tIMAGE\t\tSTATUS\033[0m"
  echo "─────────\t─────\t\t──────"
  docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' 2>/dev/null
}

di() {
  echo "\033[1;36mREPOSITORY\tTAG\tSIZE\033[0m"
  echo "──────────\t───\t────"
  docker images --format '{{.Repository}}\t{{.Tag}}\t{{.Size}}' 2>/dev/null
}

kctxs() {
  echo "\033[1;36mCONTEXTS\033[0m"
  echo "────────"
  local current=$(kubectl config current-context 2>/dev/null)
  kubectl config get-contexts -o name 2>/dev/null | while read ctx; do
    [[ "$ctx" == "$current" ]] && echo "● \033[1;32m$ctx\033[0m (current)" || echo "  $ctx"
  done
}

knss() {
  echo "\033[1;36mNAMESPACES\033[0m"
  echo "──────────"
  local current=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
  [[ -z "$current" ]] && current="default"
  kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | while read ns; do
    [[ "$ns" == "$current" ]] && echo "● \033[1;32m$ns\033[0m (current)" || echo "  $ns"
  done
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
  echo "→ Syncing config files to dotfiles..."

  # .claude (hooks, settings.json.template)
  mkdir -p ~/dotfiles/.claude/hooks
  cp -r ~/.claude/hooks/* ~/dotfiles/.claude/hooks/ 2>/dev/null
  # settings.json → template 변환 ($HOME을 $HOME 리터럴로 치환)
  sed "s|$HOME|\$HOME|g" ~/.claude/settings.json > ~/dotfiles/.claude/settings.json.template 2>/dev/null

  # .codex (config.toml)
  mkdir -p ~/dotfiles/.codex
  cp ~/.codex/config.toml ~/dotfiles/.codex/ 2>/dev/null

  # .gemini (settings.json only - no credentials)
  mkdir -p ~/dotfiles/.gemini
  cp ~/.gemini/settings.json ~/dotfiles/.gemini/ 2>/dev/null

  echo "✓ Config files synced"

  cd ~/dotfiles && git add -A && git commit -m "${1:-Update dotfiles}" && git push
  cd - > /dev/null
  echo "✓ Dotfiles pushed"
}

dotpull() {
  cd ~/dotfiles && git pull
  cd - > /dev/null

  echo "→ Restoring config files..."

  # .claude
  mkdir -p ~/.claude/hooks
  cp -r ~/dotfiles/.claude/hooks/* ~/.claude/hooks/ 2>/dev/null
  # template → settings.json 변환 ($HOME 리터럴을 실제 경로로 치환)
  sed "s|\$HOME|$HOME|g" ~/dotfiles/.claude/settings.json.template > ~/.claude/settings.json 2>/dev/null

  # .codex
  mkdir -p ~/.codex
  cp ~/dotfiles/.codex/config.toml ~/.codex/ 2>/dev/null

  # .gemini
  mkdir -p ~/.gemini
  cp ~/dotfiles/.gemini/settings.json ~/.gemini/ 2>/dev/null

  echo "✓ Config files restored"

  ~/dotfiles/install.sh
}

# help
cmds() {
  cat <<'EOF'
== Aliases ==
  ll                         ls -al
  clr                        clear

== Docker ==
  d / dc                     docker / docker compose
  dps / dpa                  ps / ps -a
  di                         images
  dlog / dex                 logs -f / exec -it
  dstop / drm                stop / rm
  dcu / dcd                  compose up -d / down

== Kubernetes ==
  k                          kubectl
  kgp / kgs / kgd / kga      get pods/svc/deploy/all
  klog / kex                 logs -f / exec -it
  kd / kdel                  describe / delete
  kctx / kctxs               switch context / list contexts
  kns / knss                 switch namespace / list namespaces

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
  claude-bedrock-opus46      Bedrock Opus 4.6 (auto AWS login)
  claude-bedrock-opus        Bedrock Opus 4.5 (auto AWS login)
  claude-bedrock-sonnet      Bedrock Sonnet 4.5 (auto AWS login)

== Dotfiles ==
  dotpush [msg]              Sync configs (.claude/.codex/.gemini) & push
  dotpull                    Pull latest & restore configs
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
