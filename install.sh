#!/bin/sh
# install.sh — Symlink AI engineering standards into a target project.
#
# Usage:
#   /path/to/ai-engineering-standards/install.sh [target_dir]
#
# If target_dir is omitted, the current working directory is used.
#
# This script symlinks (does not copy) AGENTS.md and .claude/ from this repo
# into the target project, so every target stays in sync with a single
# source of truth. Existing files are never silently overwritten.
#
# POSIX sh compatible. Safe to run multiple times (idempotent).

set -eu

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

# Directory this script lives in (the standards repo), resolved to an
# absolute path even if invoked via a relative path or through a symlink.
SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
    /*) : ;;
    *) SCRIPT_PATH="$(pwd)/$SCRIPT_PATH" ;;
esac
SOURCE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

TARGET_DIR="${1:-$(pwd)}"
case "$TARGET_DIR" in
    /*) : ;;
    *) TARGET_DIR="$(pwd)/$TARGET_DIR" ;;
esac

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: target directory does not exist: $TARGET_DIR" >&2
    exit 1
fi

if [ "$SOURCE_DIR" = "$TARGET_DIR" ]; then
    echo "Error: target directory is the standards repo itself. Run this from/against a different project." >&2
    exit 1
fi

echo "Standards source: $SOURCE_DIR"
echo "Target project:   $TARGET_DIR"
echo ""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# link_item SRC DEST
# Creates a symlink at DEST pointing to SRC. Refuses to clobber an existing
# real file/dir. If DEST is already a symlink pointing at SRC, it's a no-op.
link_item() {
    src="$1"
    dest="$2"

    if [ -L "$dest" ]; then
        existing_target="$(readlink "$dest")"
        if [ "$existing_target" = "$src" ]; then
            echo "  OK      $dest (already linked)"
            return 0
        else
            echo "  SKIP    $dest -> exists as a symlink to a different target ($existing_target)"
            echo "          Remove it manually if you want to relink: rm '$dest'"
            return 0
        fi
    fi

    if [ -e "$dest" ]; then
        echo "  SKIP    $dest -> already exists and is not a symlink we manage."
        echo "          Move or remove it manually if you want to replace it with a link."
        return 0
    fi

    ln -s "$src" "$dest"
    echo "  LINKED  $dest -> $src"
}

# ---------------------------------------------------------------------------
# Link AGENTS.md
# ---------------------------------------------------------------------------

echo "Linking root files..."
link_item "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"

# ---------------------------------------------------------------------------
# Link .claude/ contents
# ---------------------------------------------------------------------------

echo ""
echo "Linking .claude/ ..."

mkdir -p "$TARGET_DIR/.claude"

link_item "$SOURCE_DIR/.claude/CLAUDE.md" "$TARGET_DIR/.claude/CLAUDE.md"

# rules/ and skills/ are linked as whole directories, not file-by-file, so
# that adding a new rule/skill upstream shows up in every target
# automatically without re-running install.sh.
link_item "$SOURCE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"
link_item "$SOURCE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Done. $TARGET_DIR now points at the standards in $SOURCE_DIR."
echo "Existing files, if any were skipped above, were left untouched — remove"
echo "them manually and re-run this script if you want them replaced with links."
