---
trigger: always — applies to every task regardless of size
applies_to: "**/*"
---

# Rule: Agent Behavioral Guardrails

## When this rule loads

Unlike the other rules in this directory, this one isn't scoped to a
particular kind of file or task — it defines non-negotiable behaviors for
*how* you operate as an agent in this codebase, on every task, large or
small. It's the behavioral counterpart to `anti-surrender`
(`.claude/skills/anti-surrender/SKILL.md`): that skill is a structured
checkpoint you invoke deliberately; this rule is the baseline you're always
operating under, whether or not you've explicitly invoked anything.

## 1. Surface technical assumptions before writing code

Any non-trivial implementation rests on assumptions — about data shape, about
how an existing system behaves, about what "correct" means for an edge case
the request didn't specify. State the assumptions you're making *before* you
start writing, not buried in a comment discovered during review:

- "I'm assuming `userId` is always present on this object based on the type
  definition — flag me if that's not guaranteed at runtime."
- "I'm assuming this endpoint should return 404 rather than an empty array
  when the resource doesn't exist, to match the pattern in
  `orders_controller`."

This isn't about asking permission for every micro-decision — it's about
making your reasoning visible so a wrong assumption gets caught in seconds,
not after the code ships.

## 2. Stop and ask when requirements or codebase patterns conflict

If the request conflicts with itself, or conflicts with an established
pattern in the codebase, do not silently resolve the conflict in whichever
direction is easiest to implement. Stop and surface the conflict:

- The request asks for behavior that contradicts an existing, apparently
  intentional pattern elsewhere in the codebase — say so and ask which should
  win, rather than assuming the new request is automatically correct.
- Two parts of the same request imply different things (e.g. "make this
  endpoint idempotent" and "always create a new record on each call" can't
  both be fully true) — name the contradiction explicitly.
- A requirement is technically impossible or would require a breaking change
  the request didn't mention — say so before attempting a workaround that
  papers over the real issue.

This is a direct extension of the spec-first discipline
(`.claude/rules/spec-first.md` §4): the earlier a real conflict surfaces, the
cheaper it is to resolve.

## 3. Push back on bad technical patterns, security risks, or tech debt

Silence is not neutral — implementing a request without comment implicitly
signals "this is fine." If it isn't, say so, once, clearly, before or while
implementing:

- **Security risks:** SQL built via string concatenation, secrets logged or
  hardcoded, missing authorization checks, insecure deserialization — flag
  these even if the request didn't ask you to review security, and even if
  raising it adds friction.
- **Bad technical patterns:** an approach that will clearly cause problems at
  the codebase's actual scale (e.g. an N+1 query, unbounded recursion on
  user-controlled input, a race condition in concurrent access) — name the
  problem and propose the fix, don't implement it as-asked and hope it's
  fine.
- **Tech debt being introduced, not just encountered:** if the request itself
  would add debt (a hardcoded value that should be configurable, a copy-paste
  of existing logic instead of reusing it), say so — you don't have to
  refuse to implement it, but the human should get to make that trade-off
  knowingly rather than have it happen silently.

State the concern once, with the reasoning, then proceed as directed unless
it's genuinely unsafe to do so (see `AGENTS.md` §7 on security baseline) —
this isn't about blocking on every disagreement, it's about making sure
disagreements get seen.

## 4. Prefer simple, obvious solutions over clever abstractions

Default to the most direct implementation that solves the actual problem in
front of you:

- Don't introduce a generic framework, plugin system, or configuration layer
  to solve a problem that currently has exactly one concrete instance. Build
  the concrete thing; generalize later if a second concrete need actually
  materializes.
- Prefer code that a mid-level engineer unfamiliar with this specific
  codebase could read and understand in one pass, over a more "elegant"
  version that requires understanding a custom abstraction first.
- Cleverness has a real, ongoing cost — every future reader (human or agent)
  pays the tax of decoding it. Simplicity has a one-time cost of possibly
  writing a few more lines. Default to paying the one-time cost.
- This doesn't mean avoiding necessary complexity where the problem is
  genuinely complex — it means not manufacturing complexity the problem
  doesn't actually have.

## 5. Enforce strict file scope bounding

Touch what the task requires, and nothing else:

- Do not modify files outside the scope of the current task, even if you
  notice something else that could be improved while you're in the
  neighborhood. Note it instead (to the human, or in `state.md` per
  `.claude/rules/git-workflow.md`) and let it be a separate, deliberate task.
- Do not run repo-wide reformatting, renaming, or "while I'm here" cleanups
  as a side effect of an unrelated change — this is what turns a 40-line PR
  into an unreviewable 2,000-line diff (see `AGENTS.md` §5 on bounded PRs).
- If accomplishing the task genuinely requires touching a file that seems
  out of scope (a shared type definition, a config file consumed by multiple
  modules), say so explicitly and explain why it's necessary, rather than
  touching it silently as an unremarked-upon part of a larger diff.
- Read-only exploration (searching, viewing files to understand context) is
  unrestricted and encouraged — this rule is about what you *write to*, not
  what you're allowed to look at.

## Anti-patterns this rule prevents

- A wrong assumption discovered in code review that could have been caught
  in one sentence up front.
- A real requirements conflict silently "resolved" in whichever direction
  was easiest to code.
- A security or scaling problem shipped without comment because raising it
  felt like friction.
- An over-engineered abstraction built for a future need that never
  materializes.
- A small, reviewable task turning into a sprawling diff because unrelated
  files got touched along the way.
