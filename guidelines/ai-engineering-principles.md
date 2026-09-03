# AI Engineering Principles

> A human-readable synthesis of the reasoning behind `AGENTS.md`, `.claude/`,
> and every rule and skill in this repository. The rules tell an agent *what*
> to do. This document explains *why*, for the humans who own the outcome.

---

## 1. Accountability doesn't transfer to the model

An AI agent can write code, run commands, and even write tests — but it
cannot be held accountable for a production incident, and it cannot feel the
cost of being wrong. The human who merges the PR owns the outcome, full stop,
regardless of how much of the diff was AI-generated.

This has a concrete implication for how these rules are designed: every gate
in this repo (spec-first, testing, verification evidence, bounded PRs) exists
to keep a human genuinely in the loop on the decisions that matter, rather
than in a purely ceremonial "approve" role rubber-stamping something they
never really evaluated. An agent that produces a plausible-looking 2,000-line
diff and says "done, tests pass" (without evidence) has quietly shifted all
the accountability risk onto whoever approves it without truly checking. Small
PRs, explicit verification evidence, and spec-first planning are how we keep
the human's approval meaningful instead of theatrical.

## 2. Product taste doesn't come from the model either

Models are very good at producing *a* solution to a stated problem. They are
much worse — not because of any fundamental limitation, but because they lack
the context — at knowing whether the stated problem is the *right* problem,
whether the obvious solution has a hidden cost the business can't afford, or
whether "good enough" here should actually mean "excellent" because this is a
high-stakes surface.

This is why `anti-surrender` exists as an explicit checkpoint rather than
trusting the agent to always volunteer pushback. Left unprompted, an agent
optimizing for "complete the request quickly and pleasantly" will tend to
take the path of least resistance: implement the literal ask, pick whichever
ambiguous interpretation is easiest to build, and avoid the friction of
disagreeing with the human. That's a reasonable default in a lot of contexts,
but it's actively dangerous for consequential decisions. Product taste — the
judgment about what's actually worth building, and how well — has to come
from the human. The agent's job is to make sure that judgment gets exercised
deliberately, with real trade-offs on the table, instead of getting skipped
because skipping it was more convenient in the moment.

## 3. "Intent debt" is the AI-era version of technical debt

Technical debt is the gap between the code you wrote and the code you would
have written with more time. **Intent debt** is a related but distinct
problem specific to AI-assisted engineering: it's the gap between what a
human actually needed and what got built, accumulating silently because an
agent optimized for satisfying the literal prompt rather than the underlying
goal.

Intent debt is more dangerous than ordinary technical debt for two reasons:

- **It's invisible in the diff.** Code that does the wrong (but plausible)
  thing looks the same in a PR as code that does the right thing. Traditional
  code review, skimmed quickly, won't catch it.
- **It compounds silently.** Every subsequent feature gets built on the
  slightly-wrong foundation, and each one makes the eventual correction more
  expensive, because more things now depend on the wrong behavior.

The spec-first workflow is the primary defense against intent debt: by
forcing an explicit restatement of the goal, non-goals, and edge cases
*before* code gets written, it creates a checkpoint where a misunderstanding
gets caught while it's still cheap to fix — a paragraph to edit, not a
production system to migrate.

## 4. Context preservation is not optional in an agentic workflow

Human engineers build up institutional context automatically, through
repeated exposure to a codebase over months or years. An AI agent starts each
session with none of that, no matter how many previous sessions worked on the
same codebase. Left unaddressed, this means:

- Architectural decisions get silently re-litigated, because nobody recorded
  why the first decision was made.
- Work gets abandoned mid-flight with no record of what was done, what's
  left, or what was learned — the next session (human or AI) has to
  rediscover all of it from scratch, or worse, doesn't realize there's
  anything to rediscover and duplicates or contradicts the earlier work.
- Chesterton's Fence gets violated constantly: code that looks removable
  because "the reason isn't visible from here" often has a reason that simply
  never got written down anywhere durable.

This is why context preservation is treated as a first-class engineering
practice in this repo, not an afterthought: ADRs for durable rationale,
`state.md` for session-to-session handoff, and the Chesterton's Fence
requirement to actively go looking for context (via `git blame`/history)
before assuming there isn't any.

## 5. Verification evidence is the only thing that actually de-risks AI output

A model reporting "this works" and a model reporting "this works, here's the
test command and its actual output" carry very different amounts of
information, even though both sound confident. Confidence is cheap for a
language model to produce regardless of whether it's warranted — it's a
property of the output style, not a reliable signal of correctness.

That's the whole rationale for the outer-loop verification requirement: it
replaces "trust the agent's confidence" with "trust the evidence the agent
produced this session." It also creates a useful, low-cost habit for the
agent itself — actually running the test suite surfaces problems (flaky
tests, missed edge cases, environment issues) that pure code review, by a
human or a model, would miss.

## 6. Portability matters because standards shouldn't be vendor lock-in

The specific tool an engineer uses to write code with AI assistance — Claude
Code, Cursor, Copilot, Gemini CLI, whatever comes next — is far less
important than the standards governing how that assistance gets used. Tying
your engineering discipline to one vendor's proprietary config format means
re-deriving (or losing) that discipline every time the tooling landscape
shifts, which — given how fast this space is moving — will be often.

`AGENTS.md` exists specifically to be the tool-agnostic core: the principles
that should hold regardless of which agent is reading them. `.claude/`
provides the same standards with tool-specific mechanics (always-on rules,
invokable skills, and a `CLAUDE.md` that imports `AGENTS.md` since Claude
Code doesn't read it natively) layered on top for Claude Code users, but
nothing in `.claude/` should ever contradict `AGENTS.md` — if it does, that's
a bug in this repo, not a feature.

## 7. Why ~150 lines per PR, specifically

There's nothing magic about 150 as opposed to 100 or 200 — the actual
principle is "small enough that a human reviewer can hold the entire change
in their head and genuinely evaluate it, rather than skimming and trusting."
150 lines is a reasonable default for that in most codebases; adjust it for
your own team's review bandwidth and the nature of the change (a
well-isolated data migration might reasonably be larger; a change touching
five call sites of a risky function might need to be smaller).

The bounded-PR rule exists because AI agents can produce large diffs *fast*,
much faster than a human reviewer can meaningfully evaluate them. Without an
explicit size discipline, the natural failure mode is "reviewer approves a
large diff they didn't actually fully understand" — which quietly reintroduces
the accountability gap described in principle #1.

## 8. The unhappy path is where incidents actually live

Most production incidents aren't caused by the happy path being wrong. They're
caused by the *unhappy* path never being handled at all: the request that
times out instead of failing, the error that gets caught and silently
discarded, the listener that never gets cleaned up, the empty state that
renders as a blank screen. AI agents are especially prone to this because a
prompt almost always describes what should happen when things work, and
rarely describes what should happen when they don't — so an agent optimizing
for the literal request will build the happy path beautifully and leave the
rest to chance.

`resilience.md` sets the standard (explicit timeouts, retries, and fallbacks;
no silently swallowed errors; user-perceived performance over architectural
elegance), and `edge-case-audit` is the concrete checklist for verifying that
standard was actually met before shipping. The anti-rationalization table in
`resilience.md` exists for the same reason: the unhappy path gets skipped one
reasonable-sounding excuse at a time, and naming those excuses up front makes
them harder to reach for.

## 9. Simplicity is a deliverable, not a byproduct

Working code and shippable code are not the same thing. The natural residue
of active development — abandoned approaches, unused imports, defensive
nesting that outlived its purpose, a clever abstraction built for a second
use case that never arrived — is invisible to the person who wrote it and
expensive for everyone who reads it afterward, including the next AI session
with no memory of why any of it is there.

`behaviors.md` pushes toward the simple, obvious solution from the start, and
`code-simplify` is the explicit post-implementation pass that removes what
accumulated anyway, then re-runs the tests to prove nothing changed. Treating
that pass as a required step rather than an optional nicety is what keeps a
codebase readable across many AI-assisted changes instead of gradually
silting up.

---

## Summary

Every rule in this repository traces back to one of these ideas:

| Principle | Rule/skill that enforces it |
|---|---|
| Accountability doesn't transfer to the model | Bounded PRs, verification evidence (`git-workflow.md`, `testing.md`) |
| Product taste has to come from humans | `anti-surrender` skill, `behaviors.md` |
| Intent debt is the silent failure mode | `spec-first` rule and skill |
| Context preservation across sessions | ADRs, `state.md` (`git-workflow.md`) |
| Confidence ≠ correctness | Outer-loop verification (`testing.md`, `AGENTS.md` §4) |
| Standards shouldn't be vendor lock-in | `AGENTS.md` as the portable core, imported by `CLAUDE.md` |
| Small diffs keep review meaningful | Bounded PR sizing (`git-workflow.md`) |
| The unhappy path is where incidents live | `resilience.md`, `edge-case-audit` skill |
| Simplicity is a deliverable | `behaviors.md`, `code-simplify` skill |

None of this is about distrusting AI agents categorically. It's about
recognizing that speed without accountable verification just moves risk
downstream — onto whoever has to debug the production incident, re-derive
lost context, or untangle intent debt months later. These standards are the
mechanism for keeping speed and accountability together instead of trading
one for the other.
