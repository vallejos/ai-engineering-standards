# Rule: Git Workflow & Context Preservation

## When this rule applies

This rule applies whenever you're about to commit, open a PR, or wrap up a
session that involved a non-trivial architectural decision or left work
mid-flight.

## Commit hygiene

- **Small, coherent commits.** One logical change per commit. A commit should
  be revertible on its own without breaking unrelated things.
- **Commit messages** follow Conventional Commits style:
  `type(scope): short description`, where `type` is one of `feat`, `fix`,
  `refactor`, `test`, `docs`, `chore`, `perf`, `build`, `ci`.
  - Body (when needed): explain *why*, not just what — the diff already shows
    what changed.
  - Reference the issue/ticket if one exists.
- Do not mix formatting-only changes with behavioral changes in the same
  commit.

## PR sizing and titles

- **Target ~150 lines of diff or less** per PR. Decompose larger features
  into a sequence of small, independently reviewable PRs that land safely
  even if a later PR in the sequence is delayed.
- **Semantic PR titles**, same convention as commits:
  `type(scope): what this PR does`, e.g. `feat(auth): add refresh token rotation`.
- **PR description template:**

  ```markdown
  ## What
  <1-3 sentences: what this changes>

  ## Why
  <the problem this solves, or the spec/issue it implements>

  ## How
  <notable implementation decisions, especially non-obvious trade-offs>

  ## Verification
  <exact commands run + summarized output — see .claude/rules/testing.md>

  ## Chesterton's Fence notes
  <if anything was removed/refactored: why it was safe to do so>
  ```

- If a task genuinely can't be split below ~150 lines (e.g. a generated
  migration, a mechanical repo-wide rename), say so explicitly in the PR
  description and explain how the human should review it differently (e.g.
  "review the script that generated this, not the diff itself").

## Architectural decision tracking

For any decision that future engineers (human or AI) would benefit from
understanding the rationale for — choice of library, data model shape,
significant trade-off between two valid approaches — record it as a
lightweight Architecture Decision Record (ADR):

- Location: `docs/adr/NNNN-short-title.md` (create the directory if it
  doesn't exist yet).
- Minimal template:

  ```markdown
  # NNNN. Short title

  Status: Accepted | Superseded by NNNN | Deprecated
  Date: YYYY-MM-DD

  ## Context
  What problem or force made this decision necessary.

  ## Decision
  What we decided.

  ## Consequences
  What this makes easier, harder, or forecloses.
  ```

- Not every commit needs an ADR. Use judgment: if reverting this decision
  later would require re-deriving *why* it was made, write it down now while
  the context is fresh.

## Context preservation across sessions (`state.md`)

AI agent sessions are stateless between invocations. To avoid losing context
mid-task:

- Maintain a `state.md` at the repo root (or task-specific location if
  working across multiple parallel efforts) with:

  ```markdown
  # State — <task/feature name>

  ## Status
  In progress | Blocked | Ready for review

  ## What's done
  - ...

  ## What's left
  - ...

  ## Key decisions made this session
  - ...

  ## Open questions / blockers
  - ...

  ## Next step
  <the single next concrete action — so the next session, human or AI, can
  resume immediately without re-deriving context>
  ```

- Update `state.md` **before** ending a session if the task is not fully
  complete — treat "I ran out of context/turns" the same as "I'm handing this
  off to someone else."
- Delete or archive `state.md` once the task is merged and complete — it's a
  working document, not permanent documentation. Durable rationale belongs in
  ADRs or code comments, not in `state.md`.

## Anti-patterns this rule prevents

- Giant PRs that are effectively unreviewable.
- Commit messages that say "fix stuff" with no rationale.
- Losing architectural context because it only ever existed in a chat
  transcript.
- A task silently going stale because the next session has no idea where the
  last one left off.
