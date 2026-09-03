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
# of replacing it. If an individual item's name collides with something the
# target already has (e.g. their own rules/testing.md), ours is added under
# a prefixed name (ai-engineering-standards-testing.md) so BOTH files
# coexist and both are actually loaded, rather than ours being silently
# dropped. AGENTS.md and .claude/CLAUDE.md are the one exception: those are
# single fixed filenames read by convention, so a renamed copy wouldn't be
# picked up automatically — if one already exists, it's left untouched and
# you'll need to merge that one manually.
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

# Fixed prefix used to disambiguate a name collision inside rules/ or
# skills/. Fixed (not derived from the clone directory name) so the
# resulting filename is predictable no matter what someone names their
# local clone of this repo.
PREFIX="ai-engineering-standards"

# link_item_coexist SRC DEST_DIR NAME
# Like link_item, but for items inside a directory we're merging into
# (rules/*.md, skills/*/) where BOTH our item and a pre-existing same-named
# item need to actually take effect — not just avoid data loss. Skipping
# entirely would silently drop our rule/skill, which defeats the point of
# installing this repo.
#
# - If DEST_DIR/NAME doesn't exist, or is already our own symlink: link it
#   there directly, same as link_item.
# - If DEST_DIR/NAME exists as a REAL file/dir that belongs to the target
#   project (not ours): leave it completely untouched, and instead link our
#   item under a prefixed name (PREFIX-NAME) so both coexist and both are
#   still picked up — Claude Code loads every file under .claude/rules/ and
#   every directory under .claude/skills/, so a second, distinctly-named
#   file/dir works exactly as well as the original name would have.
link_item_coexist() {
    src="$1"
    dest_dir="$2"
    name="$3"
    primary_dest="$dest_dir/$name"

    if [ -L "$primary_dest" ]; then
        existing_target="$(readlink "$primary_dest")"
        if [ "$existing_target" = "$src" ]; then
            echo "  OK      $primary_dest (already linked)"
            return 0
        fi
        # A symlink to something else at this exact name is unusual (could
        # be a leftover from a differently-configured install) — treat the
        # name as taken and fall through to the coexist path below rather
        # than silently overwriting someone else's symlink.
    elif [ ! -e "$primary_dest" ]; then
        ln -s "$src" "$primary_dest"
        echo "  LINKED  $primary_dest -> $src"
        return 0
    fi

    # Name is taken by something real (or a foreign symlink) that isn't
    # ours — coexist under a prefixed name instead of skipping, so this
    # rule/skill still actually gets loaded.
    alt_name="${PREFIX}-${name}"
    alt_dest="$dest_dir/$alt_name"

    if [ -L "$alt_dest" ]; then
        alt_existing_target="$(readlink "$alt_dest")"
        if [ "$alt_existing_target" = "$src" ]; then
            echo "  OK      $alt_dest (already linked; '$name' was taken by an existing file)"
            return 0
        fi
    fi

    if [ -e "$alt_dest" ]; then
        # Extremely unlikely (would require a real file already named
        # PREFIX-NAME) — at this point we genuinely can't safely proceed
        # for this one item without risking a clobber, so skip with a clear
        # explanation rather than guessing further.
        echo "  SKIP    $name -> both '$name' and '$alt_name' are already taken in $dest_dir/"
        echo "          Resolve the naming conflict manually, then re-run this script."
        return 0
    fi

    ln -s "$src" "$alt_dest"
    echo "  COEXIST $alt_dest -> $src"
    echo "          ('$name' already exists in $dest_dir/ and was left untouched;"
    echo "          ours was added as '$alt_name' so both are loaded)"
}

# merge_dir SRC_DIR DEST_DIR
# Links a whole directory in the common case (DEST_DIR doesn't exist yet, or
# is already a symlink we manage), so new items added upstream show up
# automatically without re-running this script.
#
# If DEST_DIR already exists as a REAL directory (i.e. the target project
# already has its own .claude/rules or .claude/skills with content in it),
# we do NOT replace or touch anything already in it. Instead we link each
# item inside SRC_DIR into DEST_DIR individually via link_item_coexist,
# which renames on a name collision rather than skipping — so our rules and
# skills are guaranteed to actually take effect alongside whatever's
# already there, not silently dropped because a name happened to match.
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
    # Never replace it — merge our items into it individually, coexisting
    # under a prefixed name on any collision rather than dropping the item.
    echo "  MERGE   $dest_dir/ already exists with its own content -> adding items individually (nothing existing is touched)"
    for item in "$src_dir"/*; do
        [ -e "$item" ] || continue
        name="$(basename "$item")"
        link_item_coexist "$item" "$dest_dir" "$name"
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
echo "SKIP means an item (only ever AGENTS.md or .claude/CLAUDE.md, or a"
echo "genuine double-collision) was left completely untouched with no"
echo "change made. MERGE means an existing .claude/rules or .claude/skills"
echo "directory was preserved as-is, with our items added into it. COEXIST"
echo "means one of our items had the same name as something already there,"
echo "so it was added under a prefixed name instead — both now coexist and"
echo "both are loaded."
