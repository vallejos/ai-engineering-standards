---
name: spec-first
description: Converts an informal, vague, or underspecified coding request into a structured spec/PRD with goals, non-goals, constraints, edge cases, and a step-by-step implementation plan. Use this whenever the user asks for a new feature, a non-trivial fix, or says things like "build me X", "add support for Y", "refactor Z" — especially when the request is short, casual, or leaves obvious gaps (unclear scope, no mention of edge cases, no acceptance criteria). Also use when the user explicitly asks to "spec this out", "make a plan first", "write a PRD", or invokes plan mode. Do not use for genuinely trivial one-line changes (typo fixes, config value tweaks) — those can proceed directly per AGENTS.md.
---

# Spec-First

Turn a vague prompt into a concrete, reviewable spec *before* any production
code gets written. This is the executable counterpart to
`.claude/rules/spec-first.md` — that rule says a spec is required; this skill
is how you produce one well and consistently.

## When to reach for this skill

- The user's request implies a change but doesn't fully define success
  ("add rate limiting to the API", "make search faster", "support CSV export").
- The request is a single sentence describing a feature with real complexity
  hiding underneath it.
- The user explicitly asks for a plan, spec, or PRD before code.
- You (Claude) notice mid-task that the original request was more ambiguous
  than it first appeared — stop and re-spec rather than guessing forward.

Skip this skill for trivial, fully-specified changes — see
`.claude/rules/spec-first.md` for the trivial/non-trivial boundary.

## Process

### 1. Extract what's already known

Before asking the user anything, mine the conversation and codebase for
answers you can derive yourself:

- Is there an existing pattern in the codebase for similar features? (e.g. how
  are other API endpoints rate-limited, how is other tabular data exported?)
- Did the user mention any constraint in passing (a deadline, a library
  preference, a system it needs to integrate with)?
- Are there existing tests, types, or interfaces that imply the intended
  shape of the solution?

Only ask the user about genuine gaps — don't make them re-answer what's
already inferable.

### 2. Fill the template

Produce a spec using this structure. Keep it tight — a page, not an essay.

```markdown
# Spec: <feature/fix name>

## Goal
What outcome this achieves, and for whom. One or two sentences, framed around
the user-visible or system-visible result, not the implementation.

## Non-goals
What's explicitly out of scope for this change. This is what prevents scope
creep and sets reviewer expectations.

## Constraints
Technical constraints (existing architecture, performance budget, backward
compatibility requirements), product constraints (must ship behind a flag,
must match existing UX pattern), and organizational constraints (must reuse
approved library X, can't touch module Y right now).

## Edge cases
The inputs/states that are easy to miss. At minimum, consider and note
whether each applies:
- Empty / null / missing input
- Maximum size / volume / rate
- Concurrent access / race conditions
- Permission and authorization boundaries
- Partial failure (network, IO, downstream service down)
- Backward compatibility with existing data/callers

## Implementation plan
Ordered, concrete steps. Each step should be small enough to verify
independently and, ideally, land as its own commit or small PR per
`.claude/rules/git-workflow.md`.

1. ...
2. ...
3. ...

## Open questions
Anything genuinely uncertain. Flag it here rather than silently resolving it
with a guess. If any of these are blocking, ask the user before proceeding to
implementation.
```

### 3. Surface trade-offs explicitly

If there's more than one reasonable implementation approach, name at least
two and state the trade-off in a sentence each (e.g. "Option A: cache at the
API layer — simpler, but stale data risk. Option B: cache at the DB query
layer — more consistent, more invasive change."). Recommend one, but let the
human override.

### 4. Get sign-off on blocking questions

If the spec surfaces an open question that would materially change the
implementation (not a minor detail), ask the user before writing code. Don't
let "keep momentum" become an excuse to guess on something that matters.

### 5. Hand off to implementation

Once the spec is stable:
- For small tasks, proceed directly to implementation, following the plan
  section step by step, verifying each step per `.claude/rules/testing.md`.
- For larger features, save the spec as a markdown file (e.g.
  `docs/specs/<feature-name>.md`) so it persists independently of the chat
  session and can be referenced by future sessions or other engineers.

## Anti-patterns this skill prevents

- Starting to code on a one-sentence request and discovering the real scope
  three files in.
- Specs that are so long nobody reads them before approving.
- Silently resolving an ambiguous requirement in whichever direction is
  easiest to implement.
- Treating "the user didn't mention edge cases" as license to ignore them.
