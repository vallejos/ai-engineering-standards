@../AGENTS.md

# CLAUDE.md — Global Claude Code Configuration

This file configures Claude Code for this project (or, when installed via
`install.sh`, for any target project). It assumes and extends the universal
principles in `../AGENTS.md`, which is imported above so it loads into
context automatically — Claude Code reads `CLAUDE.md`, not `AGENTS.md`, so
the `@` import line is what makes the shared baseline actually take effect.
Everything below is Claude Code-specific: style conventions, terminal safety,
and the quality gates that must pass before a change is considered done.

---

## How to use this file

- `AGENTS.md` (repo root) = what to do and why, portable across tools.
- `CLAUDE.md` (this file) = how Claude Code specifically should behave.
- `.claude/rules/*.md` = topic-specific rules, loaded at session start with
  the same priority as this file. None are path-scoped, because they describe
  behavior rather than file types — so they are always in effect.
- `.claude/skills/*` = invokable skills for structured workflows, loaded on
  demand when you invoke them or when Claude judges them relevant.

---

## Code Style

- Match the existing style of the file/module you're editing over any
  personal or generic preference. Consistency within a codebase beats
  "correctness" of style in the abstract.
- Prefer explicit, readable code over clever one-liners. Optimize for the next
  engineer (human or AI) reading this in six months without your context.
- Naming: descriptive over terse. `userAccountBalance` beats `uab`. Avoid
  abbreviations unless they're already idiomatic in this codebase.
- Comments explain *why*, not *what* — the code already says what it does. Add
  a comment when the reasoning isn't obvious from the code alone (a
  workaround, a non-obvious constraint, a link to the issue that caused it).
- No dead code left "just in case." If it's not used, remove it or explain in
  the PR why it's being kept.
- Don't reformat or restyle code you weren't asked to touch. Whitespace-only
  diffs on unrelated lines make review harder and violate the bounded-PR rule.

---

## Terminal Execution Safety

Claude Code can run shell commands directly. The following rules are
mandatory, not suggestions:

1. **Read before you run.** Understand what a command does before executing
   it, especially anything piped from the internet (`curl | sh`) or involving
   `sudo`.
2. **Never run destructive commands without explicit confirmation for that
   specific action:**
   - `rm -rf`, `git push --force` / `--force-with-lease`, `git reset --hard`
   - Database drops/truncates, migrations that are not reversible
   - Any command that rewrites git history on a shared branch
   - Bulk deletes of files, branches, or cloud resources
3. **Never commit or print secrets.** If a command would output an API key,
   token, or credential, redact it before including it in your response.
4. **Prefer dry-runs first** when a tool supports one (`terraform plan` before
   `apply`, `--dry-run` flags, etc.) and show the human the plan before
   executing.
5. **Long-running or background commands** must be clearly flagged as such,
   with a way for the human to check status, rather than silently left
   running.
6. **Environment changes** (installing global packages, modifying shell
   config, changing system settings) require explicit confirmation — don't
   assume the sandbox/session is disposable unless you've confirmed it is.

---

## Quality Gates

A task is not "done" until all of the following are true. State the status of
each explicitly when you report completion — don't just say "done."

- [ ] **Spec exists** for anything non-trivial (see `.claude/rules/spec-first.md`)
- [ ] **Tests written or updated** for the behavior that changed
- [ ] **Tests actually run**, with real output shown (see `.claude/rules/testing.md`)
- [ ] **Build/typecheck/lint pass**, if the project has them
- [ ] **Edge cases audited** for any change touching network calls, async
      code, subscriptions, or UI loading/error states (run the
      `edge-case-audit` skill; see `.claude/rules/resilience.md`)
- [ ] **Cleanup pass done** — no dead code, unused imports, or leftover
      debugging residue (run the `code-simplify` skill before opening a PR)
- [ ] **Chesterton's Fence checked** for anything removed or refactored
      (see `AGENTS.md` §2)
- [ ] **Diff is bounded** (~150 lines) or explicitly justified if not (see
      `.claude/rules/git-workflow.md`)
- [ ] **No secrets, no destructive actions taken without confirmation**
- [ ] **state.md updated** if this session made an architectural decision or
      left work in a non-obvious intermediate state (see
      `.claude/rules/git-workflow.md`)

If any box can't be checked, say so plainly instead of reporting success.

---

## Communication Defaults

- Lead with the actual answer or result, not a restatement of the request.
- When something failed or is uncertain, say that first — don't bury it under
  a summary of what went well.
- Show real command output for anything you claim to have verified. A
  one-line "tests pass" without evidence is not acceptable for non-trivial
  changes.
- If you disagree with the requested approach, say so once, briefly, with the
  trade-off — then proceed as directed unless the human asks you to hold.
