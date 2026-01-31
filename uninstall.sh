#!/bin/bash
# uninstall.sh - Remove qmd-claude-history integration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Helper functions
info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
section() { echo -e "${CYAN}${BOLD}$1${NC}"; }

# Function to print centered text in a box
print_box() {
    local text="$1"
    local width=60
    local padding=$(( (width - ${#text}) / 2 ))
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC}%${padding}s${BOLD}%s${NC}%$(($width - $padding - ${#text}))s${BLUE}║${NC}\n" "" "$text" ""
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to print section header
section_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Function to wait for user
wait_for_user() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read
}

# Welcome page
page_welcome() {
    clear
    print_box "QMD Claude History Uninstaller"
    
    section "What Will Be Removed"
    echo "  ✗ LaunchAgent (auto-updates)"
    echo "  ✗ Converter script"
    echo "  ✗ Skill files"
    echo "  ? Converted history (optional)"
    echo "  ? CLAUDE.md section (optional)"
    echo ""
    
    section "What Will Be Preserved"
    echo "  ✓ Original JSONL files in ~/.claude/projects/"
    echo "  ✓ QMD collections (manual removal required)"
    echo ""
    
    echo -n "Continue with uninstallation? (y/N): "
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
}

# Stop services
page_stop_services() {
    clear
    section_header "Step 1: Stopping Services"
    
    if launchctl list | grep -q "com.user.qmd-claude-history"; then
        section "Stopping LaunchAgent..."
        launchctl unload "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist" 2>/dev/null || true
        info "LaunchAgent stopped"
    else
        warn "LaunchAgent not running"
    fi
    
    wait_for_user
}

# Remove files
page_remove_files() {
    clear
    section_header "Step 2: Removing Files"
    
    if [[ -f "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist" ]]; then
        section "Removing LaunchAgent..."
        rm "${HOME}/Library/LaunchAgents/com.user.qmd-claude-history.plist"
        info "LaunchAgent removed"
    else
        warn "LaunchAgent not found"
    fi
    
    if [[ -f "${HOME}/.local/bin/convert-claude-history.sh" ]]; then
        section "Removing converter script..."
        rm "${HOME}/.local/bin/convert-claude-history.sh"
        info "Converter script removed"
    else
        warn "Converter script not found"
    fi
    
    if [[ -d "${HOME}/.claude/skills/qmd-claude-history" ]]; then
        section "Removing skill..."
        rm -rf "${HOME}/.claude/skills/qmd-claude-history"
        info "Skill removed"
    else
        warn "Skill not found"
    fi
    
    wait_for_user
}

# Handle converted history
page_converted_history() {
    clear
    section_header "Step 3: Converted History"
    
    if [[ -d "${HOME}/.claude/converted-history" ]]; then
        section "About Converted History"
        echo "The converted-history directory contains Markdown versions"
        echo "of your Claude conversations."
        echo ""
        echo "Location: ${HOME}/.claude/converted-history"
        echo ""
        echo "Note: Original JSONL files in ~/.claude/projects/ will be preserved."
        echo ""
        
        echo -n "Remove converted conversation history? (y/N): "
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            section "Removing converted history..."
            rm -rf "${HOME}/.claude/converted-history"
            info "Converted history removed"
        else
            echo ""
            info "Preserving converted history at ~/.claude/converted-history/"
        fi
    else
        info "No converted history found"
    fi
    
    wait_for_user
}

# Handle CLAUDE.md
page_claude_md() {
    clear
    section_header "Step 4: CLAUDE.md Configuration"
    
    local CLAUDE_MD="${HOME}/.claude/CLAUDE.md"
    
    if [[ -f "$CLAUDE_MD" ]] && grep -q "qmd-claude-history" "$CLAUDE_MD" 2>/dev/null; then
        section "About CLAUDE.md Section"
        echo "The installer added a section to your CLAUDE.md file that"
        echo "tells Claude to automatically activate the qmd-claude-history"
        echo "skill when you ask about past work."
        echo ""
        echo "Location: ${HOME}/.claude/CLAUDE.md"
        echo ""
        
        echo -n "Remove qmd-claude-history section from CLAUDE.md? (y/N): "
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            section "Removing CLAUDE.md section..."
            # Create backup
            cp "$CLAUDE_MD" "${CLAUDE_MD}.backup.$(date +%Y%m%d%H%M%S)"
            
            # Remove the section (everything from "## Memory & Context Retrieval" to next ## or end)
            # This is a simple approach - removes lines from the section header to the next major section
            awk '
                /^## Memory & Context Retrieval/ {
                    skip = 1
                    next
                }
                skip && /^## [^#]/ {
                    skip = 0
                }
                !skip { print }
            ' "$CLAUDE_MD" > "${CLAUDE_MD}.tmp" && mv "${CLAUDE_MD}.tmp" "$CLAUDE_MD"
            
            info "CLAUDE.md section removed"
            info "Backup created: ${CLAUDE_MD}.backup.*"
        else
            echo ""
            info "Preserving CLAUDE.md section"
            echo ""
            echo "To remove manually later, edit:"
            echo "  ${HOME}/.claude/CLAUDE.md"
            echo ""
            echo "Look for the section titled:"
            echo "  ## Memory & Context Retrieval"
        fi
    else
        info "No qmd-claude-history section found in CLAUDE.md"
    fi
    
    wait_for_user
}

# QMD collections info
page_collections() {
    clear
    section_header "Step 5: QMD Collections"
    
    section "Important Note"
    echo "QMD collections are NOT automatically removed."
    echo ""
    echo "To remove QMD collections manually, run:"
    echo ""
    echo -e "  ${CYAN}# List all collections${NC}"
    echo "  qmd collection list"
    echo ""
    echo -e "  ${CYAN}# Remove specific collection${NC}"
    echo "  qmd collection remove <name>"
    echo ""
    echo "Example:"
    echo "  qmd collection remove claude-toolkata-conversations"
    echo ""
    
    wait_for_user
}

# Completion page
page_completion() {
    clear
    print_box "Uninstallation Complete!"
    
    section "What Was Removed"
    echo "  ✓ LaunchAgent (auto-updates)"
    echo "  ✓ Converter script"
    echo "  ✓ Skill files"
    echo ""
    
    section "What Was Preserved"
    echo "  ✓ Original JSONL files in ~/.claude/projects/"
    echo "  ✓ QMD collections (manual removal required)"
    echo ""
    
    section "To Reinstall Later"
    echo "  curl -fsSL https://raw.githubusercontent.com/hmemcpy/qmd-claude-history/main/install.sh | bash"
    echo ""
    
    echo -e "${YELLOW}Press Enter to exit...${NC}"
    read
}

# Main uninstallation flow
main() {
    page_welcome
    page_stop_services
    page_remove_files
    page_converted_history
    page_claude_md
    page_collections
    page_completion
    
    clear
    echo -e "${GREEN}${BOLD}Uninstallation complete!${NC}"
}

# Run main function
main
