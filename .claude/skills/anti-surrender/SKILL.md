---
name: anti-surrender
description: Forces a structured trade-off analysis and explicit human checkpoint before proceeding on a consequential, ambiguous, or irreversible decision — instead of silently picking the path of least resistance. Use this whenever you notice you're about to take a shortcut that trades correctness for speed, whenever a request has multiple reasonable interpretations with materially different outcomes, before any irreversible or hard-to-revert action (deleting data, force-pushing, dropping a table, removing a safety check, disabling a test instead of fixing it), or when the user pushes back on a correct answer and you feel pulled to just agree. Also use when the user explicitly asks "what are my options" or "what would you actually recommend."
---

# Anti-Surrender

"Cognitive surrender" is quietly doing the easy or agreeable thing instead of
the correct thing. This skill is a checkpoint: it forces you to name the
alternatives, state the trade-offs honestly, and get explicit human
confirmation before proceeding — rather than defaulting to whatever requires
the least friction right now.

## When to reach for this skill

Trigger this deliberately when you notice any of these patterns in yourself:

- You're about to disable, skip, or delete a failing test instead of fixing
  the underlying issue.
- You're about to remove a check, validation, or guardrail because it's "in
  the way" of the current task.
- The request has two or more reasonable interpretations that would produce
  materially different implementations, and you're about to just pick one.
- You're about to take an irreversible or hard-to-revert action (data
  deletion, force-push, dropping a column/table, rewriting history).
- The user pushed back on something you said was correct, and you feel the
  pull to simply agree without re-examining whether they're actually right.
- You're tempted to report something as "done" or "working" when you have not
  actually verified it (see `.claude/rules/testing.md`) — this is the most
  common and most dangerous form of surrender.

## Process

### 1. Name what the easy path is

State plainly, to yourself and eventually to the user, what the path of least
resistance would be — and why it's tempting (faster, avoids a hard problem,
avoids conflict, matches what was literally asked even though it's probably
not what's meant).

### 2. Generate genuine alternatives

Produce at least two real alternatives to the easy path — not a strawman and
a strawman, but options a competent engineer would actually consider. For
each:

- **What it is** — one sentence.
- **Trade-off** — what it costs (time, complexity, risk) and what it buys
  (correctness, safety, maintainability).

### 3. Make a recommendation, not just a menu

Don't just list options and hand the decision back with no opinion — that's
its own form of surrender (avoiding the discomfort of taking a position).
State which option you'd choose and why, in one or two sentences, while
making clear the human has the final call.

### 4. Checkpoint before proceeding

For anything irreversible or genuinely consequential, stop and ask before
acting — don't present the trade-off and then proceed anyway in the same
turn. For lower-stakes ambiguity, it's fine to state your reasoning and
recommended path and proceed, giving the human the chance to redirect rather
than requiring their sign-off up front — use judgment on which situation
you're in, and err toward asking when reversibility is unclear.

### 5. Hold the line on pushback, when warranted

If the user pushes back on something you have good reason to believe is
correct (a security concern, a bug, a fact):

- Re-examine your reasoning honestly first — you might be wrong, and updating
  is not surrender.
- If you still believe you're right after re-examining, say so clearly and
  explain why, rather than folding just to avoid friction.
- If it's a judgment call rather than a fact, acknowledge that and defer to
  the human's call once you've made your case once — repeating the same
  objection after they've decided is not this skill's job.

## Output shape

When this skill fires, structure your response like:

```markdown
**Easy path:** <what the shortcut would be, and why it's tempting>

**Alternatives:**
1. <option> — <trade-off>
2. <option> — <trade-off>

**Recommendation:** <your pick and why, in 1-2 sentences>

**Needs your call because:** <why this specific decision needs a human
checkpoint rather than proceeding automatically>
```

Keep it short. This is a checkpoint, not an essay — the goal is a fast, honest
decision point, not a wall of text that gets skimmed past.

## Anti-patterns this skill prevents

- Deleting/skipping a failing test to make CI green instead of fixing the bug.
- Silently picking the interpretation of a request that's easiest to build.
- Reporting a task as complete without having verified it.
- Agreeing with user pushback purely to avoid friction, when you actually
  have good reason to believe you were right.
- Presenting options with no recommendation, leaving all the judgment work to
  the human.
