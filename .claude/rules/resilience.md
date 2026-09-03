---
trigger: when writing or reviewing network calls, async code, UI loading/error states, or test files
applies_to: "**/*"
---

# Rule: Resilience, Web Vitals, and DAMP Testing

## When this rule loads

This rule applies whenever you're writing or touching: any network call or
other async I/O, UI states that depend on that I/O (loading, error, empty,
partial data), or test files. The throughline is a simple one — most
production incidents aren't caused by the happy path being wrong, they're
caused by the *unhappy* path never being handled at all. This rule exists to
make the unhappy path a first-class citizen instead of an afterthought.

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

## 2. No silent drops

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

## 3. User-perceived performance over client abstractions

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

## 4. DAMP test design

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

## 5. Anti-Rationalization Protocol

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

## Anti-patterns this rule prevents

- A `fetch` call with no timeout that hangs a UI indefinitely on a bad
  connection.
- A `catch {}` block that makes a real production error invisible.
- A client-side abstraction layer that delays LCP for the sake of
  "clean architecture."
- A test suite so DRY that a single failure requires reading four files to
  understand what broke.
- Test/doc debt accumulating one "just this once" at a time.
