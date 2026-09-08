#!/bin/sh
# update.sh -- one-command way to pull the latest standards and keep your
# personal Claude Code setup (~/.claude) in sync with this repo.
#
# Usage:
#   /path/to/ai-engineering-standards/update.sh [--dry-run]
#
# Equivalent to running, from inside this repo:
#   git pull
#   ./install.sh --user --sync
#
# --sync means: if CLAUDE.md/rules/skills under ~/.claude already exist as
# real (non-symlinked) content -- typically stale copies left over from an
# install on a machine that couldn't create real symlinks at the time --
# each one is renamed aside as a timestamped backup (never deleted) and
# replaced with a real symlink. Once every target is a real symlink, this
# script (or a plain `git pull`) is the only thing you ever need to run
# again to pick up future changes.
#
# This is for a personal, single-owner ~/.claude setup. It is a poor fit
# for a shared team repo, where a colleague's real customization might be
# sitting at one of these paths -- use install.sh (without --sync) there
# instead, which merges/coexists rather than replacing.
#
# Pass --dry-run to preview exactly what would change, including what
# --sync would back up, without pulling or writing anything.
#
# POSIX sh compatible.

set -eu

# Resolve this script's own directory the same way install.sh does, so
# `update.sh` works correctly even when invoked via a relative path or a
# symlink to it (e.g. a shell alias pointing at this file).
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
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

DRY_RUN=0
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --help|-h)
            cat <<'USAGE'
Usage: update.sh [--dry-run]

Pulls the latest standards (git pull) and runs install.sh --user --sync
to keep ~/.claude in sync with this repo. See the comment at the top of
this file, or install.sh --help, for what --sync does in detail.
USAGE
            exit 0
            ;;
        *) echo "Error: unknown option: $arg" >&2; echo "Usage: update.sh [--dry-run]" >&2; exit 1 ;;
    esac
done

if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY RUN — not pulling, and install.sh will preview only."
    echo ""
else
    echo "Pulling latest standards into $SCRIPT_DIR ..."
    git -C "$SCRIPT_DIR" pull
    echo ""
fi

if [ "$DRY_RUN" -eq 1 ]; then
    exec "$SCRIPT_DIR/install.sh" --user --sync --dry-run
else
    exec "$SCRIPT_DIR/install.sh" --user --sync
fi
