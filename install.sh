#!/bin/sh
# install.sh — Symlink AI engineering standards into a target project, or
# into your personal Claude Code user profile.
#
# Usage:
#   /path/to/ai-engineering-standards/install.sh [--dry-run] [target_dir]
#   /path/to/ai-engineering-standards/install.sh --user [--dry-run]
#
# Project mode (default): installs AGENTS.md, .claude/CLAUDE.md,
# .claude/rules/, and .claude/skills/ into target_dir (current directory if
# omitted). Use this per-repo, and for the AGENTS.md baseline that Cursor,
# Copilot, Gemini CLI, and Codex read at a project root.
#
# User mode (--user): installs into ~/.claude/ instead — CLAUDE.md, rules/,
# and skills/ only. Per the Claude Code docs, personal rules in
# ~/.claude/rules/ apply to every project on the machine automatically, so
# this is the one-time setup instead of re-running install.sh in every repo.
# AGENTS.md is deliberately skipped in this mode: no tool reads a copy of it
# sitting in $HOME, so installing it there would just be inert clutter.
# target_dir cannot be given in --user mode; the target is always $HOME.
#
# Pass --dry-run (or -n) to see exactly what would happen without writing
# anything — recommended the first time you run this against a location that
# already has its own AGENTS.md or .claude/ content, which is the normal
# case for --user mode on a laptop you've been using Claude Code on already.
#
# This script symlinks (does not copy) files from this repo into the target,
# so every target stays in sync with a single source of truth. Existing
# files are never silently overwritten.
#
# If the target already has its own .claude/rules or .claude/skills
# directory with real content in it, that directory is left completely
# alone — this script merges our rules/skills into it item-by-item instead
# of replacing it. If an individual item's name collides with something the
# target already has (e.g. their own rules/testing.md), ours is added under
# a prefixed name (ai-engineering-standards-testing.md) so BOTH files
# coexist and both are actually loaded, rather than ours being silently
# dropped.
#
# AGENTS.md and .claude/CLAUDE.md can't use that same coexist trick — only
# one file of each exact name is ever read by convention, so a renamed copy
# wouldn't be picked up automatically. Instead, if either already exists as
# a real file, its content is left completely untouched and ours is
# appended as a clearly delimited, regenerated-on-every-run block at the
# end of the file — so any tool reading that file gets both sets of
# instructions in the same read, and re-running this script keeps the
# appended block in sync without ever touching what's above it.
#
# POSIX sh compatible. Safe to run multiple times (idempotent).

set -eu

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------

DRY_RUN=0
USER_MODE=0
TARGET_ARG=""

# Counts symlink attempts that didn't produce a real symlink, so the script
# can keep going (report every item, not just the first failure) and still
# exit non-zero at the end for scripted/CI callers. See do_ln for why this
# can't just be "ln's exit code was non-zero".
SYMLINK_FAILURES=0

usage() {
    cat <<'USAGE'
Usage: install.sh [--dry-run] [target_dir]
       install.sh --user [--dry-run]

Project mode (default): symlinks/merges AGENTS.md and .claude/ into
target_dir (current directory if omitted).

User mode (--user): installs only .claude/CLAUDE.md, rules/, and skills/
into ~/.claude/, which Claude Code applies to every project on this
machine automatically. AGENTS.md is skipped (no tool reads it from $HOME).
Cannot be combined with an explicit target_dir.

Options:
  --user          Install into ~/.claude/ instead of a project directory.
  --dry-run, -n   Show exactly what would be linked, merged, or modified,
                  without touching anything on disk.
  --help, -h      Show this help and exit.
USAGE
}

for arg in "$@"; do
    case "$arg" in
        --user) USER_MODE=1 ;;
        --dry-run|-n) DRY_RUN=1 ;;
        --help|-h) usage; exit 0 ;;
        -*) echo "Error: unknown option: $arg" >&2; usage >&2; exit 1 ;;
        *)
            if [ -n "$TARGET_ARG" ]; then
                echo "Error: more than one target directory given." >&2
                usage >&2
                exit 1
            fi
            TARGET_ARG="$arg"
            ;;
    esac
done

if [ "$USER_MODE" -eq 1 ] && [ -n "$TARGET_ARG" ]; then
    echo "Error: --user installs into \$HOME/.claude and can't take an explicit target_dir ($TARGET_ARG)." >&2
    usage >&2
    exit 1
fi


# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------

# Directory this script lives in (the standards repo), resolved to an
# absolute path even if invoked via a relative path or through a symlink.
# Symlinks to the script are followed manually because `readlink -f` isn't
# POSIX and doesn't exist on stock macOS. Without this, invoking the script
# through e.g. ~/bin/standards-install -> repo/install.sh would resolve
# SOURCE_DIR to ~/bin and silently create dangling symlinks in the target.
SCRIPT_PATH="$0"
while [ -L "$SCRIPT_PATH" ]; do
    link_target="$(readlink "$SCRIPT_PATH")"
    case "$link_target" in
        /*) SCRIPT_PATH="$link_target" ;;
        *)  SCRIPT_PATH="$(dirname "$SCRIPT_PATH")/$link_target" ;;
    esac
done
case "$SCRIPT_PATH" in
    /*) : ;;
    *) SCRIPT_PATH="$(pwd)/$SCRIPT_PATH" ;;
esac
SOURCE_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Sanity-check that SOURCE_DIR really is the standards repo before we link
# anything from it — a wrong SOURCE_DIR would otherwise produce dangling links.
for required in AGENTS.md .claude/CLAUDE.md .claude/rules .claude/skills; do
    if [ ! -e "$SOURCE_DIR/$required" ]; then
        echo "Error: $SOURCE_DIR does not look like the standards repo (missing $required)." >&2
        exit 1
    fi
done

if [ "$USER_MODE" -eq 1 ]; then
    if [ -z "${HOME:-}" ]; then
        echo "Error: --user requires \$HOME to be set." >&2
        exit 1
    fi
    TARGET_DIR="$HOME"
else
    TARGET_DIR="${TARGET_ARG:-$(pwd)}"
    case "$TARGET_DIR" in
        /*) : ;;
        *) TARGET_DIR="$(pwd)/$TARGET_DIR" ;;
    esac
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: target directory does not exist: $TARGET_DIR" >&2
    exit 1
fi

if [ "$SOURCE_DIR" = "$TARGET_DIR" ]; then
    echo "Error: target directory is the standards repo itself. Run this from/against a different project." >&2
    exit 1
fi

echo "Standards source: $SOURCE_DIR"
if [ "$USER_MODE" -eq 1 ]; then
    echo "Target:           $TARGET_DIR (user mode — ~/.claude only, no AGENTS.md)"
else
    echo "Target project:   $TARGET_DIR"
fi
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Mode:             DRY RUN — nothing will be written"
fi
echo ""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# do_ln SRC DEST / do_mkdir DIR / do_replace TMP DEST
# Every mutating filesystem operation goes through one of these so --dry-run
# can intercept it in exactly one place.
do_ln() {
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi

    ln_error="$(ln -s "$1" "$2" 2>&1)"
    ln_status=$?

    # Trusting ln's exit code alone is not enough: some `ln` builds on
    # Windows (Git Bash/MSYS without Developer Mode or an elevated shell)
    # silently fall back to *copying* the source instead of creating a
    # symlink, and still exit 0. A copy looks identical to a real symlink to
    # every caller of do_ln, but it will never track upstream changes, and
    # on the next run it gets mistaken for the target's own pre-existing
    # content by link_or_embed/sync_managed_block — which then appends a
    # second full copy as a "managed block" on top of the first, corrupting
    # the file. Checking -L after the fact catches both a hard failure and
    # this silent-copy fallback.
    if [ "$ln_status" -ne 0 ] || [ ! -L "$2" ]; then
        # Safe to remove unconditionally: every call site only reaches
        # do_ln after confirming $2 didn't already exist, so this can only
        # ever delete the bogus copy/partial output ln itself just produced
        # for this exact call, never anything the user (or an earlier run)
        # put there.
        rm -rf "$2"
        echo "  ERROR   could not create a real symlink at $2" >&2
        if [ -n "$ln_error" ]; then
            echo "          $ln_error" >&2
        else
            echo "          'ln -s' exited 0 but left a regular file/directory" >&2
            echo "          instead of a symlink — seen on Windows when Developer" >&2
            echo "          Mode / admin rights aren't available." >&2
        fi
        echo "          Fix: enable Developer Mode (Windows) or run this from WSL," >&2
        echo "          then re-run install.sh." >&2
        SYMLINK_FAILURES=$((SYMLINK_FAILURES + 1))
        return 1
    fi
}

do_mkdir() {
    if [ "$DRY_RUN" -eq 1 ]; then return 0; fi
    if ! mkdir_error="$(mkdir -p "$1" 2>&1)"; then
        echo "Error: could not create directory $1" >&2
        echo "  $mkdir_error" >&2
        echo "  (a parent path segment likely exists already as a regular file)" >&2
        exit 1
    fi
}

do_replace() {
    if [ "$DRY_RUN" -eq 1 ]; then rm -f "$1"; return 0; fi
    mv "$1" "$2"
}

# sync_managed_block SRC DEST LABEL
# For files where only one filename is ever read by convention (AGENTS.md,
# .claude/CLAUDE.md) — so a coexist-under-a-different-name strategy wouldn't
# actually get picked up by any tool. If DEST already exists as a real file
# (not our symlink), we can't symlink it without either destroying the
# target's own content or refusing to add ours. Instead, we append our
# content as a clearly delimited, regenerated-on-every-run block:
#
# - The target's own original content is left completely untouched, in
#   place, above the block.
# - Our content is embedded in full (not just a reference/pointer) between
#   marker comments, so any tool reading DEST gets our instructions in the
#   same read — a link/pointer only works if the tool chooses to go fetch
#   it, which isn't guaranteed.
# - On every re-run, the block between the markers is replaced with the
#   current content of SRC, so it stays in sync the same way a symlink
#   would — everything outside the markers is never touched.
sync_managed_block() {
    src="$1"
    dest="$2"
    label="$3"
    begin_marker="<!-- BEGIN ai-engineering-standards:${label} (managed block — regenerated by install.sh; hand edits here will be overwritten on re-run) -->"
    end_marker="<!-- END ai-engineering-standards:${label} -->"

    tmp_base="$(mktemp)"
    tmp_new="$(mktemp)"

    if grep -qF "$begin_marker" "$dest" 2>/dev/null; then
        # Strip the old managed block (markers inclusive) so we can replace
        # it with a fresh copy; everything outside it passes through as-is.
        awk -v b="$begin_marker" -v e="$end_marker" '
            $0 == b { skip = 1; next }
            $0 == e { skip = 0; next }
            !skip   { print }
        ' "$dest" > "$tmp_base"
        action="updated (was already present from a previous run)"
    else
        cp "$dest" "$tmp_base"
        action="added"
    fi

    # Trim trailing blank lines. Without this, each re-run would leave
    # behind the single blank separator line from the previous run (since
    # it sits just before BEGIN, outside the stripped block), and the file
    # would grow by one blank line every time this script runs.
    tmp_trimmed="$(mktemp)"
    awk '
        { lines[NR] = $0 }
        END {
            last = NR
            while (last > 0 && lines[last] ~ /^[ \t]*$/) last--
            for (i = 1; i <= last; i++) print lines[i]
        }
    ' "$tmp_base" > "$tmp_trimmed"
    mv "$tmp_trimmed" "$tmp_base"

    {
        cat "$tmp_base"
        echo ""
        echo "$begin_marker"
        cat "$src"
        echo ""
        echo "$end_marker"
    } > "$tmp_new"

    do_replace "$tmp_new" "$dest"
    rm -f "$tmp_base"

    echo "  MERGED  $dest -> your existing content is untouched; the"
    echo "          $label standards were $action as a managed block at the end"
    echo "          of the file (kept in sync automatically on future re-runs)"
}

# link_or_embed SRC DEST LABEL
# Entry point for AGENTS.md and .claude/CLAUDE.md: symlink when possible
# (fresh target, or a target where we already own the symlink), fall back to
# sync_managed_block when the target already has its own real file there.
link_or_embed() {
    src="$1"
    dest="$2"
    label="$3"

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

    if [ ! -e "$dest" ]; then
        if do_ln "$src" "$dest"; then
            echo "  LINKED  $dest -> $src"
        fi
        return 0
    fi

    if [ ! -f "$dest" ]; then
        echo "  SKIP    $dest -> exists and is not a regular file, can't merge into it."
        echo "          Move or remove it manually if you want to link/merge here."
        return 0
    fi

    sync_managed_block "$src" "$dest" "$label"
}

# Fixed prefix used to disambiguate a name collision inside rules/ or
# skills/. Fixed (not derived from the clone directory name) so the
# resulting filename is predictable no matter what someone names their
# local clone of this repo.
PREFIX="ai-engineering-standards"

# link_item_coexist SRC DEST_DIR NAME
# For items inside a directory we're merging into (rules/*.md, skills/*/)
# where BOTH our item and a pre-existing same-named item need to actually
# take effect — not just avoid data loss. Skipping entirely would silently
# drop our rule/skill, which defeats the point of installing this repo.
#
# - If DEST_DIR/NAME doesn't exist, or is already our own symlink: link it
#   there directly.
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
        if do_ln "$src" "$primary_dest"; then
            echo "  LINKED  $primary_dest -> $src"
        fi
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

    if do_ln "$src" "$alt_dest"; then
        echo "  COEXIST $alt_dest -> $src"
        echo "          ('$name' already exists in $dest_dir/ and was left untouched;"
        echo "          ours was added as '$alt_name' so both are loaded)"
    fi
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
        if do_ln "$src_dir" "$dest_dir"; then
            echo "  LINKED  $dest_dir/ -> $src_dir/ (whole directory)"
        fi
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

if [ "$USER_MODE" -eq 1 ]; then
    echo "Skipping AGENTS.md (user mode) -> no tool reads a copy of it from"
    echo "\$HOME; it only matters at a project root. Run this script without"
    echo "--user inside a specific project if you also want AGENTS.md there."
else
    echo "Linking root files..."
    link_or_embed "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md" "AGENTS.md"
fi

# ---------------------------------------------------------------------------
# Link .claude/ contents
# ---------------------------------------------------------------------------

echo ""
echo "Linking .claude/ ..."

do_mkdir "$TARGET_DIR/.claude"

link_or_embed "$SOURCE_DIR/.claude/CLAUDE.md" "$TARGET_DIR/.claude/CLAUDE.md" "CLAUDE.md"

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
if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run complete — nothing was written. Re-run without --dry-run to apply."
elif [ "$SYMLINK_FAILURES" -gt 0 ]; then
    echo "Finished with $SYMLINK_FAILURES symlink error(s) — see ERROR lines above."
    echo "Everything else listed above was applied; re-run after fixing the"
    echo "symlink issue to pick up the rest."
else
    echo "Done. $TARGET_DIR now points at the standards in $SOURCE_DIR."
fi
echo "SKIP means an item was left completely untouched with no change made"
echo "(only for a genuine double-collision, or something that isn't a"
echo "regular file/directory). MERGE means an existing .claude/rules or"
echo ".claude/skills directory was preserved as-is, with our items added"
echo "into it. COEXIST means one of those items had the same name as"
echo "something already there, so it was added under a prefixed name"
echo "instead — both now coexist and both are loaded. MERGED means an"
echo "existing AGENTS.md or .claude/CLAUDE.md kept its own content in place,"
echo "with ours appended as a managed block that stays in sync on re-run."

if [ "$SYMLINK_FAILURES" -gt 0 ]; then
    exit 1
fi
