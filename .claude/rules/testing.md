# Rule: Testing & Verification Standards

## When this rule applies

This rule applies to every code change, without exception, before you report
a task as complete. It is loaded at session start alongside `CLAUDE.md`, so
it's always in effect — there's no need to invoke it.

For how tests should be *written* (readable, DAMP over DRY), see
`.claude/rules/resilience.md` §4. For a systematic checklist of the boundary
conditions to cover on async/network code, use the `edge-case-audit` skill.

## Core requirement

**No task is complete without verification evidence produced in this
session.** "I believe this works" is not evidence. "I ran `<command>` and got
`<actual output>`" is evidence.

## Test-driven boundary checks

Before implementing a change:

1. Identify what test coverage already exists for the code you're touching.
   If none exists and the change is non-trivial, that's itself a finding —
   flag it and propose adding coverage as part of the change.
2. Identify the boundary conditions that matter for this change specifically:
   empty/null inputs, min/max values, concurrent access, permission
   boundaries, network/IO failure, malformed data. Not every change needs
   every category, but you should actively consider each one rather than only
   testing the happy path.
3. Write or update tests to cover the new/changed behavior *and* the boundary
   conditions identified above, before or alongside the implementation —
   don't leave test-writing as an afterthought bolted on at the end.

## Execution standard

Before reporting a change as complete:

- **Run the actual test suite** (or the correctly-scoped subset — e.g. just
  the affected package, not necessarily the whole monorepo if that's
  impractical) using the project's real test command. Don't assume; check
  `package.json`, `Makefile`, `pyproject.toml`, CI config, or ask if it's not
  discoverable.
- **Show the real output**: pass/fail counts, and the actual failure text for
  anything that failed. Do not paraphrase a failure as "minor" without
  showing what it actually says.
- **Run build/typecheck/lint** if the project has them configured, and report
  their status too — a change that passes tests but breaks the build is not
  done.
- If you fixed a bug, show the failing test **before** your fix (or describe
  the manual repro) and the passing test **after**, so the fix is actually
  demonstrated rather than assumed.
- If tests cannot be run in your current environment (missing dependencies,
  no network, no test runner available), say this explicitly and clearly —
  do not present unverified code as verified.

## What "done" looks like in a report to the human

A complete status report includes:

1. What changed (brief).
2. What you ran to verify it (exact command).
3. What the output was (real, not paraphrased-from-memory).
4. Anything you could *not* verify, and why.

## Anti-patterns this rule prevents

- Claiming "all tests pass" without having run them this session.
- Writing tests that only cover the happy path.
- Silently skipping test execution because it's slow or inconvenient.
- Describing a fix as complete based on code inspection alone, when running
  it was possible and was skipped.
