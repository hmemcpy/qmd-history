# QMD Claude History

Automatic indexing and search for Claude Code conversation history using QMD.

## What This Does

Converts Claude's JSONL conversation history into searchable Markdown collections. Each project gets its own QMD collection that Claude can search when you ask about past work.

## Features

- **Auto-activation** - Skill activates when you ask about past work (no commands needed)
- **Per-project collections** - Each project gets its own searchable history
- **Auto-conversion** - New conversations converted automatically every 30 minutes
- **Incremental updates** - Only new/changed files are processed
- **Semantic search** - Use `--semantic` flag for conceptual queries
- **96% token reduction** - Returns snippets instead of full files

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/hmemcpy/qmd-claude-history/main/install.sh | bash
```

### Manual Install

```bash
git clone https://github.com/hmemcpy/qmd-claude-history.git
cd qmd-claude-history
./install.sh
```

### Prerequisites

**1. Install Bun** (if not already installed)
```bash
curl -fsSL https://bun.sh/install | bash
```

**2. Install QMD**
```bash
bun install -g https://github.com/tobi/qmd
```

On macOS, also install SQLite for extension support:
```bash
brew install sqlite
```

**3. Install jq**
```bash
brew install jq
```

**4. Verify installation**
```bash
qmd status      # Should show index and collections
which qmd       # Should show ~/.bun/bin/qmd
which jq         # Should show /usr/local/bin/jq or similar
```

**Note:** QMD will automatically download GGUF models (~2GB total) on first use:
- Embedding model: ~300MB
- Reranker model: ~640MB
- Query expansion model: ~1.1GB

## Usage

Once installed, Claude will automatically search its own conversation history when you ask about past work. **No commands needed** - just ask naturally!

### Automatic Activation

The skill activates when you ask things like:
- "What did we work on last week?"
- "How did I implement X?"
- "Remind me about the Y project"
- "What was our approach to Z?"

### Manual Search

For precise control, use direct QMD commands:

```bash
# Search current project's history
/qmd "how did we implement authentication" --collection claude-myproject-conversations

# Search with semantic matching
/qmd "deployment process" --semantic --collection claude-myproject-conversations

# Search across all projects
/qmd "docker setup"
```

### Manual Update

If you need to update immediately (normally runs every 30 min automatically):

```bash
convert-claude-history.sh && qmd update && qmd embed
```

## How It Works

1. **Skill** (`~/.claude/skills/qmd-claude-history/SKILL.md`) teaches Claude when and how to search history
2. **Converter** (`convert-claude-history.sh`) extracts conversations from `~/.claude/projects/`
3. **LaunchAgent** runs the converter every 30 minutes automatically
4. **QMD collections** are created per-project for fast searching
5. **Auto-activation** - Claude loads the skill automatically when you ask about past work

## Project Structure

```
~/.claude/
├── projects/                    # Claude's original JSONL history
├── converted-history/           # Converted Markdown files
│   ├── myproject/
│   │   ├── 2026-01-31-session1.md
│   │   └── 2026-01-30-session2.md
│   └── otherproject/
├── plans/                       # Claude's plan documents (also indexed)
└── skills/
    └── qmd-claude-history/
        └── SKILL.md             # This skill's instructions
```

## Collection Naming

Collections follow the pattern: `claude-<project-name>-conversations`

Example projects:
- `claude-toolkata-conversations`
- `claude-scrolltunes-conversations`
- `claude-myapp-conversations`

## Search Strategy

| Type | Command | Best For |
|------|---------|----------|
| **BM25** | `/qmd <query>` | Specific terms, keywords, file names |
| **Semantic** | `/qmd <query> --semantic` | Concepts where wording varies |
| **Hybrid** | `qmd query "<query>"` | Maximum recall (slower) |

## Troubleshooting

### LaunchAgent not running?

```bash
launchctl list | grep qmd-claude-history
launchctl load ~/Library/LaunchAgents/com.user.qmd-claude-history.plist
```

### Missing collections?

```bash
# Re-run conversion and indexing
convert-claude-history.sh
qmd collection list
qmd embed
```

### Clear and rebuild all

```bash
rm -rf ~/.claude/converted-history
convert-claude-history.sh
# Then recreate collections manually
```

## Uninstall

```bash
./uninstall.sh
```

Or manually:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.qmd-claude-history.plist
rm ~/Library/LaunchAgents/com.user.qmd-claude-history.plist
rm ~/.local/bin/convert-claude-history.sh
rm -rf ~/.claude/skills/qmd-claude-history
# Optional: remove converted history
rm -rf ~/.claude/converted-history
```

## License

MIT
