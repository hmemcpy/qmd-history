# QMD Claude History

Automatic indexing and search for AI assistant conversation history using [QMD](https://github.com/tobi/qmd).

![Skill Activation Example](image.png)

*Just ask about past work and your AI assistant automatically searches your conversation history*

## Features

- **Auto-activation** - Searches activate when you ask about past work
- **Multi-assistant support** - Works with Claude Code, Amp, Opencode
- **Per-project collections** - Each project gets its own searchable history
- **Auto-conversion** - New conversations converted every 30 minutes
- **Semantic search** - Conceptual queries with `--semantic` flag
- **96% token reduction** - Returns snippets instead of full files

## Quick Start

```bash
# Install
curl -fsSL https://raw.githubusercontent.com/hmemcpy/qmd-claude-history/main/install.sh | bash

# Or clone and run
git clone https://github.com/hmemcpy/qmd-claude-history.git
cd qmd-claude-history
npm install
npm start
```

The installer features:
- Auto-detection of installed AI assistants
- Multiselect for choosing which to configure
- Visual progress indicators
- Automatic prerequisite checking

## Prerequisites

- **Bun**: `curl -fsSL https://bun.sh/install | bash`
- **QMD**: `bun install -g https://github.com/tobi/qmd`
- **jq**: `brew install jq`
- **SQLite** (macOS): `brew install sqlite`

## Usage

Just ask naturally:
- "What did we work on last week?"
- "How did I implement X?"
- "Remind me about the Y project"

Or search manually:
```bash
# Keyword search
qmd search "query" --collection claude-<project>-conversations

# Semantic search
qmd vsearch "query" --collection claude-<project>-conversations
```

## How It Works

1. **Converter** - Extracts conversations from `~/.claude/projects/`
2. **LaunchAgent** - Auto-converts every 30 minutes
3. **QMD collections** - Per-project searchable indexes
4. **Skill/Agent config** - Auto-activation instructions for AI assistants

## Uninstall

```bash
./uninstall.sh
```

## License

MIT
