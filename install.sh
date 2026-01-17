#!/bin/bash
set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES"

# .zshrc
ln -sf "$DOTFILES/.zshrc" ~/.zshrc
echo "✓ Linked .zshrc"

# .claude/settings.json
mkdir -p ~/.claude
if [[ -f ~/.claude/settings.json ]]; then
  echo "⚠ ~/.claude/settings.json already exists, backing up to settings.json.bak"
  cp ~/.claude/settings.json ~/.claude/settings.json.bak
fi
sed "s|\$HOME|$HOME|g" "$DOTFILES/.claude/settings.json.template" > ~/.claude/settings.json
echo "✓ Created .claude/settings.json"

echo ""
echo "Done! Run 'source ~/.zshrc' or open a new terminal."
