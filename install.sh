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
# If the target project already has its own .claude/rules or .claude/skills
# directory with real content in it, that directory is left completely
# alone — this script merges our rules/skills into it item-by-item instead
# of replacing it, so an existing custom setup is enhanced, not clobbered.
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

# merge_dir SRC_DIR DEST_DIR
# Links a whole directory in the common case (DEST_DIR doesn't exist yet, or
# is already a symlink we manage), so new items added upstream show up
# automatically without re-running this script.
#
# If DEST_DIR already exists as a REAL directory (i.e. the target project
# already has its own .claude/rules or .claude/skills with content in it),
# we do NOT replace or merge-delete anything in it. Instead we link each
# item inside SRC_DIR individually into DEST_DIR, so our rules/skills are
# added alongside whatever's already there. Any item that would collide with
# an existing same-named file/dir in DEST_DIR is skipped (via link_item),
# same non-destructive guarantee as everywhere else in this script.
merge_dir() {
    src_dir="$1"
    dest_dir="$2"

    if [ -L "$dest_dir" ]; then
        existing_target="$(readlink "$dest_dir")"
        if [ "$existing_target" = "$src_dir" ]; then
            echo "  OK      $dest_dir/ (already linked)"
        else
            echo "  SKIP    $dest_dir/ -> exists as a symlink to a different target ($existing_target)"
            echo "          Remove it manually if you want to relink: rm '$dest_dir'"
        fi
        return 0
    fi

    if [ ! -e "$dest_dir" ]; then
        ln -s "$src_dir" "$dest_dir"
        echo "  LINKED  $dest_dir/ -> $src_dir/ (whole directory)"
        return 0
    fi

    if [ ! -d "$dest_dir" ]; then
        echo "  SKIP    $dest_dir -> already exists and is not a directory."
        echo "          Move or remove it manually if you want to link a directory here."
        return 0
    fi

    # DEST_DIR already exists as a real directory with its own content.
    # Never replace it — merge our items into it individually instead.
    echo "  MERGE   $dest_dir/ already exists with its own content -> adding items individually (nothing existing is touched)"
    for item in "$src_dir"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        link_item "$item" "$dest_dir/$name"
    done
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

# rules/ and skills/ are linked as a whole directory when the target doesn't
# already have one of its own (the common case) — this means a new rule or
# skill added upstream shows up in every target automatically without
# re-running install.sh. If the target already has its own .claude/rules or
# .claude/skills with real content in it, we never replace or touch that
# directory — we merge our items into it individually instead, so someone's
# existing custom setup is enhanced, not clobbered.
merge_dir "$SOURCE_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"
merge_dir "$SOURCE_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo ""
echo "Done. $TARGET_DIR now points at the standards in $SOURCE_DIR."
echo "Anything marked SKIP above already existed and was left completely"
echo "untouched. Anything marked MERGE means an existing .claude/rules or"
echo ".claude/skills directory was preserved as-is, with our items added"
echo "alongside it rather than replacing it."
