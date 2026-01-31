#!/bin/bash
# uninstall.sh - Remove qmd-claude-history integration

set -e

echo "Uninstalling QMD Claude History Integration..."
echo ""

# Stop and unload LaunchAgent
if launchctl list | grep -q "com.user.qmd-claude-history"; then
    echo "Stopping LaunchAgent..."
    launchctl unload "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist" 2>/dev/null || true
fi

# Remove LaunchAgent
if [[ -f "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist" ]]; then
    echo "Removing LaunchAgent..."
    rm "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist"
fi

# Remove converter script
if [[ -f "${HOME}/.local/bin/convert-claude-history.sh" ]]; then
    echo "Removing converter script..."
    rm "${HOME}/.local/bin/convert-claude-history.sh"
fi

# Ask about converted history
read -p "Remove converted conversation history? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing converted history..."
    rm -rf "${HOME}/.claude/converted-history"
    echo "Note: Original JSONL files in ~/.claude/projects/ are preserved"
else
    echo "Preserving converted history at ~/.claude/converted-history/"
fi

# Remove skill
if [[ -d "${HOME}/.claude/skills/qmd-claude-history" ]]; then
    echo "Removing skill..."
    rm -rf "${HOME}/.claude/skills/qmd-claude-history"
fi

# Ask about QMD collections
echo ""
echo "To remove QMD collections, run:"
echo "  qmd collection list"
echo "  qmd collection remove <name>"
echo ""

echo "✓ Uninstall complete"
