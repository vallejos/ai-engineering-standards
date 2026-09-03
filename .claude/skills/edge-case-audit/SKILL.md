---
name: edge-case-audit
description: Systematically audits code for unhandled edge cases the happy path misses — high-latency/offline/partial-payload network conditions, memory leaks and uncleaned event listeners, stale state, and missing fallback UI (loading skeletons, error boundaries, user-facing error messages). Use this whenever the user asks to "audit," "stress-test," "harden," or "check the edge cases" of a feature, before shipping anything that fetches data or subscribes to events, or when reviewing a PR that touches network calls, subscriptions, or async state. Also use proactively after implementing a new data-fetching component or feature, even if the user didn't explicitly ask for an audit — treat "implement X" as implicitly including "and make sure X doesn't fall over under real-world network/memory conditions."
---

# Edge-Case Audit

A systematic pass that simulates the conditions Chrome DevTools' network and
performance panels are built to surface — high latency, offline, partial
payloads, memory growth, leaked listeners — but applied to the *code itself*,
not just observed in a live browser session. The goal is to find the bugs
that only show up under real-world conditions, before a user does.

This skill complements `.claude/rules/resilience.md` (which defines the
standard code should meet) by giving you a concrete checklist to actually
verify that standard was met.

## When to run this audit

- After implementing any feature that fetches data, opens a connection
  (WebSocket, SSE, polling), or subscribes to events/listeners.
- Before marking a PR touching async code or UI loading states as complete.
- When the user asks to "audit," "harden," "stress-test," or "check edge
  cases" for a feature.
- When reviewing someone else's (or another agent's) PR that touches network
  calls or subscriptions.

## Process

Work through each of the three sections below. For each item, either confirm
it's handled (and briefly note how/where), or flag it as a gap. Don't skip
sections because "this feature probably doesn't need it" — state briefly why
it's not applicable if you're skipping something, rather than silently moving
past it.

### 1. Network condition audit

Simulate degraded network conditions mentally (or with actual DevTools
throttling / an offline toggle, if you have browser access) and trace what
the code does in each case:

- **High latency (Slow 3G-equivalent).** Does the UI show a loading state
  immediately, or is there a flash of blank/broken content while waiting?
  Is there a timeout so the request doesn't hang forever (see
  `resilience.md` §1)?
- **Offline / connection dropped mid-request.** What happens if the network
  drops after the request starts but before it completes? Does the code
  distinguish "failed to send" from "sent but no response received" where
  that distinction matters (e.g. for non-idempotent operations)?
- **Partial / malformed payload.** What happens if the server returns a
  200 with a truncated JSON body, an unexpected shape (missing field, null
  where an object was expected, empty array where one item was assumed), or
  a payload that's technically valid JSON but semantically wrong for this
  code path? Does parsing/access code assume the happy-path shape without
  guarding against these?
- **Slow-but-eventually-successful requests racing with new requests.** If
  the user can trigger a second request before the first resolves (e.g.
  fast typing in a search box, rapid navigation), does the code handle
  out-of-order responses, or can a stale response overwrite fresher data?

### 2. Memory and lifecycle audit

- **Event listeners.** For every `addEventListener` (or framework
  equivalent — `useEffect` subscriptions, RxJS subscriptions, WebSocket
  `on` handlers), confirm there's a corresponding cleanup
  (`removeEventListener`, effect cleanup function, `unsubscribe`,
  `close`) that actually runs when the component/module unmounts or the
  relevant scope ends.
- **Timers and intervals.** Every `setTimeout`/`setInterval` (or polling
  loop) needs a corresponding `clearTimeout`/`clearInterval` on
  unmount/teardown — otherwise it keeps firing (and potentially holding
  references) after the thing it was updating is gone.
- **Stale closures over unmounted state.** Does an async callback that
  resolves after a component has unmounted (or a scope has ended) attempt to
  update state that no longer exists / isn't safe to touch? Confirm there's
  an unmounted/cancelled check, or that the framework handles this
  automatically and it's not being fought against.
- **Growing collections.** Caches, listener registries, or in-memory queues
  that grow without a bound or eviction policy are a slow leak. Confirm
  there's a cap, TTL, or explicit cleanup path.
- **Stale state persistence.** If state is persisted (localStorage,
  IndexedDB, a global store), confirm old/invalid entries get cleaned up or
  migrated rather than silently accumulating or causing a stale-shape bug
  after a schema change.

### 3. Fallback UI audit

For every async operation that affects what's rendered, confirm all of these
states are handled, not just the success case:

- **Loading state.** Is there a loading indicator (skeleton, spinner) that
  appears without a jarring delay, and disappears cleanly when data
  arrives or fails?
- **Error state.** Is there an error boundary (or equivalent) that catches
  render-time failures, and a distinct, user-legible error message for
  request failures — not a blank screen, an unstyled stack trace, or a
  generic "Something went wrong" with no path forward (retry button, support
  link, etc. as appropriate)?
- **Empty state.** If a request succeeds but returns no data, is that
  visually distinct from both the loading state and an error — does the
  user get a clear "there's nothing here" message rather than an ambiguous
  blank area they might mistake for a bug?
- **Partial-failure state.** For UI composed of multiple independent data
  sources (e.g. a dashboard with several widgets), does one widget's failure
  take down the whole page, or does it fail gracefully in isolation?

## Output format

Report findings as a checklist, grouped by section, each item marked ✅
(handled) or ⚠️ (gap found) with a one-line note. For every ⚠️, either fix it
directly (if small/in-scope) or flag it explicitly to the human with a
recommendation — don't silently note a gap and move on without surfacing it
per `.claude/rules/behaviors.md`.

```markdown
## Edge-Case Audit: <feature/PR name>

### Network conditions
- ✅ Timeout set (8s) on the primary fetch
- ⚠️ No handling for partial/malformed payload — `response.data.items` is
  accessed without checking `items` exists

### Memory & lifecycle
- ✅ WebSocket subscription cleaned up in effect teardown
- ⚠️ `setInterval` polling loop has no `clearInterval` on unmount

### Fallback UI
- ✅ Loading skeleton present
- ✅ Error boundary present
- ⚠️ No distinct empty state — empty results render as a blank area
```

## Anti-patterns this skill prevents

- A feature that works perfectly in local dev (fast network, fresh state)
  and breaks under real-world conditions the first week it's live.
- Memory leaks from listeners/timers that only show up after extended usage,
  long after the PR that introduced them has been forgotten.
- Blank or broken screens that look like the app crashed, when the real
  cause was an unhandled error or empty-data case.
