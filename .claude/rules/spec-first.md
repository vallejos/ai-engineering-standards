# Rule: Spec-First / Plan Mode

## When this rule applies

This rule applies whenever you are about to write or modify production code
and the task is **not** a trivial, obviously-scoped change (typo fix,
one-line config value, formatting). If you're unsure whether a task counts as
trivial, treat it as non-trivial and follow this rule.

## What "Plan Mode" means here

Before writing implementation code:

1. **Restate the task.** In 2-4 sentences, state what's being asked and what
   "done" looks like — the observable behavior change, not just "implement X."
2. **Write or update a short spec.** For a new feature or non-trivial fix,
   produce a lightweight spec covering:
   - **Goal** — what outcome this achieves and for whom
   - **Non-goals** — what's explicitly out of scope, to prevent scope creep
   - **Constraints** — technical, product, or organizational constraints that
     shape the solution
   - **Edge cases** — the inputs/states that are easy to miss (empty states,
     concurrent access, permission boundaries, malformed input)
   - **Implementation plan** — an ordered list of concrete steps, each small
     enough to verify independently
   - **Open questions** — anything you're not sure about; flag rather than
     guess
3. **Surface trade-offs before coding**, not after. If there are two
   reasonable approaches (e.g. "quick patch" vs. "fix the root cause"), name
   both and their trade-offs before picking one.
4. **Get confirmation for anything ambiguous or high-impact.** If the spec
   reveals that your interpretation of the request could go two different
   ways with materially different outcomes, ask before implementing.
5. **Only then write code**, following the plan. If reality diverges from the
   plan mid-implementation (an assumption turns out false), stop and update
   the spec rather than silently improvising around it.

## Where the spec lives

- For small tasks: inline in your response, as a short plan before the diff.
- For larger features: as a markdown file (e.g. `docs/specs/<feature>.md` or
  wherever this project keeps design docs) so it survives the session and can
  be reviewed independently of the code.
- Either way, the spec should be concise — a page, not an essay. This is a
  forcing function for clear thinking, not a bureaucratic deliverable.

## Using the `spec-first` skill

For turning a vague, informal prompt into a structured spec/PRD, invoke the
`spec-first` skill (`.claude/skills/spec-first/SKILL.md`) rather than doing
this ad hoc — it has a consistent template and prompts for the edge cases
people most often forget.

## Anti-patterns this rule prevents

- Jumping straight to a diff for a request that's actually underspecified.
- Discovering edge cases via bug reports instead of during planning.
- Silently picking the more convenient of two interpretations without saying
  so.
- Specs that are so long they never get read — keep it tight.
