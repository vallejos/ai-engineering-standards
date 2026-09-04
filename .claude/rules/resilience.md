# Rule: Resilience, Web Vitals, and DAMP Testing

## When this rule applies

This rule applies whenever you're writing or touching: any network call or
other async I/O, UI states that depend on that I/O (loading, error, empty,
partial data), test files, or the design of a non-trivial architectural
change (new service, data model change, cross-cutting refactor, new external
dependency). The throughline is a simple one — most production incidents
aren't caused by the happy path being wrong, they're caused by the *unhappy*
path never being handled at all, or by a decision that was never actually
compared against an alternative. This rule exists to make the unhappy path
and the design trade-off first-class citizens instead of an afterthought.

## 1. Explicit failure recovery

Every network call or other fallible async operation needs an explicit answer
to three questions: *how long do we wait, what do we do if it fails once, and
what does the user see while any of that is happening?*

- **Timeouts.** No network call should be allowed to hang indefinitely. Set an
  explicit timeout appropriate to the operation (a search-as-you-type request
  and a large file upload have very different reasonable timeouts — don't
  copy-paste one default everywhere without thinking about it).
- **Retry logic.** For transient failures (network blips, 5xx responses,
  timeouts), retry with backoff rather than failing immediately on the first
  attempt — but cap the number of retries and never retry non-idempotent
  operations (e.g. a payment charge) without an idempotency key. Don't retry
  4xx client errors; they won't succeed on repetition.
- **Graceful UI fallbacks.** Every loading state needs a corresponding error
  state and empty state, not just a happy-path render. A spinner that never
  resolves into either data or an error message is a bug. Design (or reuse)
  a fallback for: request pending, request failed, request succeeded with
  empty results.

## 2. Graceful System Degradation

A service under real duress doesn't get to choose between "fully working" and
"fully down" — the actual failure mode in production is somewhere in between,
and that in-between has to be designed on purpose, not discovered live during
an incident.

- **Explicit fallbacks and circuit breakers.** Any call to a dependency
  (internal service, third-party API, database) that can be slow or
  unavailable needs a defined fallback — a cached/stale value, a
  reduced-fidelity response, or a fast, explicit failure — never an unbounded
  wait that ties up the caller. Wrap flaky dependencies in a circuit breaker
  (or the framework's equivalent) that trips after repeated failures and
  stops sending load to a struggling downstream, rather than piling more
  requests onto something that's already failing.
- **Shed load by priority, not evenly.** A system under duress should degrade
  its least-critical functionality first and keep its most-critical path
  alive longest, not fail uniformly across every feature. That requires
  knowing, before an incident, which parts of the system must stay up versus
  which can be paused, queued, or degraded to protect the critical path —
  and holding the critical-path pieces to a correspondingly higher bar for
  testing and resilience, the way a live-video system has to treat its
  playback and delivery path as higher-tier than everything feeding into it.
- **Design the degraded state before you need it, not during the incident.**
  Decide what "bandwidth-constrained" or "reduced fidelity" actually means
  for this system at design time. A fallback improvised under pressure is a
  fallback that's never been tested. If a spec for a new system doesn't say
  what it does under duress, that's a gap in the spec per
  `.claude/rules/spec-first.md`, not an acceptable omission — real incident
  reviews consistently produce exactly this kind of finding (how do we
  direct traffic when we're congested, what do we degrade first) precisely
  because it wasn't decided in advance.
- **No hard failure where a degraded response is possible.** Prefer "return
  cached/stale data with a staleness indicator" or "disable a non-critical
  widget" over "500 the whole page" whenever the failing dependency isn't
  actually required for the primary user-facing outcome.

## 3. No silent drops

An error that is caught and discarded is strictly worse than an error that
crashes loudly, because it hides the failure from everyone — the user, the
logs, and future engineers debugging a symptom three layers away from the
actual cause.

- Never write a `catch` block (or `.catch()`, or a swallowed promise
  rejection) that does nothing or only logs a bare message with no context.
- Every caught error must be logged with **structured context**: what
  operation was being attempted, what the relevant identifiers were (request
  ID, user/session ID where appropriate, resource ID), and the actual
  error/stack — not just `console.log("error")` or `except: pass`.
- If an error is genuinely safe to ignore (e.g. an expected 404 on an
  existence check), say so explicitly in a comment — don't leave a silent
  catch block that looks like a bug to the next reader.
- Async errors that occur outside a request/response cycle (background jobs,
  event listeners, fire-and-forget calls) need the same treatment — these are
  the ones most likely to vanish silently because there's no caller waiting
  to notice the failure.

## 4. User-perceived performance over client abstractions

Prioritize what the user actually experiences over what's architecturally
elegant on the client:

- **Critical-path rendering first.** Get the largest contentful element
  (LCP — Largest Contentful Paint) on screen as fast as possible. Don't block
  it behind non-essential client-side work: analytics initialization,
  below-the-fold data fetching, or a heavy client-side state/abstraction layer
  that isn't needed to render what the user sees first.
- **Prefer server-rendered or statically-available critical content** over
  client-side-only rendering when the framework supports it, specifically for
  above-the-fold content.
- **Don't over-abstract for hypothetical flexibility.** A generic, deeply
  layered client-side data-fetching abstraction that adds latency or bundle
  size to solve a problem you don't have yet is a real, measurable cost
  (slower LCP, more JS to parse and execute) traded for a hypothetical future
  benefit. Prefer the simpler, faster, more direct implementation until
  there's a concrete reason to generalize.
- **Measure, don't assume.** When performance is a stated concern, use real
  metrics (Core Web Vitals — LCP, INP, CLS — or the equivalent for the
  platform) to justify the trade-off, rather than a vague sense that one
  approach "feels faster."

## 5. Design-Doc Guardrails for Architectural Changes

`.claude/rules/spec-first.md` requires a spec for any non-trivial change. For
changes that are specifically *architectural* — a new service, a data model
change, a cross-cutting refactor, a new external dependency, anything other
systems or teams will build on top of — that spec needs a sharper edge than
the general template, because the cost of a wrong call compounds the longer
other things depend on it.

- Before implementation starts, the spec must explicitly include:
  - **Goals** — sharpened enough that a reviewer can tell a passable design
    from a good one, not just "what this is for" restated.
  - **Non-goals** — named explicitly rather than left implicit, so scope
    creep has something concrete to be checked against later.
  - **Alternatives considered** — at least one other real approach, with a
    stated reason it was rejected. A design doc with no alternatives section
    is a decision with no visible reasoning behind it: nobody downstream can
    tell whether the chosen approach was actually compared to anything, or
    was just the first idea that came to mind.
- This extends the existing spec-first template
  (`.claude/rules/spec-first.md`) — add an "Alternatives Considered"
  subsection to that spec for architectural-scope changes rather than
  maintaining a second, parallel document format.
- Apply the same skepticism to "this is too small for a design doc" that
  `.claude/rules/spec-first.md` applies to "too small for a spec": the bar is
  whether other systems or teams will build on this decision, not how many
  lines of code it takes to implement. A project being small in scope today
  doesn't mean the decision underneath it is small.
- If there's no reviewer available to send the doc to, the "alternatives
  considered" section still has to exist — write it for the human who
  approves the change, so they're evaluating a decision instead of
  rubber-stamping the only option they were shown.

## 6. DAMP test design

Tests are documentation that happens to be executable. Optimizing test setup
code for DRY-ness the same way you'd optimize production code usually makes
tests *worse*, because it hides the specific inputs and expectations that
make a test meaningful behind layers of shared setup a reader has to
chase down.

- Prefer **DAMP** (Descriptive And Meaningful Phrases) over aggressive DRY in
  test code. Some duplication across tests is an acceptable, even desirable,
  cost if it means each test is readable in isolation.
- A test failure should be diagnosable by reading the one failing test, not
  by tracing through three layers of shared helpers/fixtures to figure out
  what input actually produced the failure.
- It's fine — good, even — to inline the specific values a test cares about
  directly in the test body, even if that value also appears in five other
  tests, when doing so makes the test's intent obvious at a glance.
- Reserve shared setup/helpers for things that are genuinely incidental to
  the test's purpose (e.g. spinning up a test database connection), not for
  the specific inputs/assertions that are the actual point of the test.
- Name tests descriptively enough that a failure in CI is understandable from
  the test name alone, before even opening the file.

## 7. Anti-Rationalization Protocol

Skipping tests, specs, or docs "just this once" is how test debt and
intent debt (see `guidelines/ai-engineering-principles.md`) actually
accumulate — one reasonable-sounding exception at a time. When you notice
yourself reaching for one of these justifications, treat it as a signal to
stop and do the work properly, or to explicitly flag the trade-off to the
human rather than silently skipping it.

| Common excuse | Why it doesn't hold up |
|---|---|
| "It's just a small change, it doesn't need a test." | Small changes are exactly the ones that get merged without careful review — the test is what catches the regression the reviewer will miss. |
| "I'll add tests/docs in a follow-up PR." | Follow-up PRs for cleanup are the most commonly-deprioritized kind of work. Ship the test with the change or don't ship the change. |
| "The existing code doesn't have tests either, so this matches the pattern." | Matching a bad existing pattern doesn't fix it, it doubles down on it. Flag the gap instead of extending it silently. |
| "This is a hotfix, there's no time to test it properly." | An untested hotfix under time pressure is exactly the condition most likely to cause a second incident. At minimum, add a regression test for the specific failure being fixed. |
| "The logic is simple enough that it's obviously correct." | "Obviously correct" code is disproportionately represented in postmortems. If it's really that simple, the test costs almost nothing to write. |
| "Nobody will read the docs/spec anyway." | The primary reader of a spec is often the agent or engineer picking this back up in six months with zero memory of today's context — including a future instance of you. |
| "The test suite is slow, I don't want to add more to it." | A slow suite is a separate problem to fix (parallelize, split unit/integration tiers) — it's not a reason to reduce coverage. |
| "This is throwaway/prototype code, standards don't apply." | Prototype code has a well-documented tendency to end up in production unchanged. If it's genuinely throwaway, say so explicitly and get sign-off that it won't ship as-is. |
| "It's a small service, it doesn't need a design doc." | Size of implementation isn't the bar — whether other systems or teams will build on this decision is. A ten-line service other things depend on needs the same "alternatives considered" scrutiny as a large one. |
| "We can add a fallback later if this turns out to be critical." | Graceful degradation can't be retrofitted after the fact onto a system that was never designed to shed load — the usual way this gets discovered is during the incident that actually needed it. |

## Anti-patterns this rule prevents

- A `fetch` call with no timeout that hangs a UI indefinitely on a bad
  connection.
- A dependency call with no circuit breaker that keeps hammering a struggling
  downstream instead of failing fast and shedding load.
- A `catch {}` block that makes a real production error invisible.
- A client-side abstraction layer that delays LCP for the sake of
  "clean architecture."
- An architectural decision shipped with no alternatives considered, so no
  one downstream can tell whether it was actually compared to anything.
- A test suite so DRY that a single failure requires reading four files to
  understand what broke.
- Test/doc debt accumulating one "just this once" at a time.
