---
name: code-simplify
description: Runs a post-implementation cleanup pass over code just written or modified — eliminating dead code, unused imports, and orphaned variables/orphaned logic; refactoring nested conditionals into guard clauses and extracting complex boolean conditions into well-named predicates; and then running the automated test suite to verify zero behavioral regressions. Use this after any non-trivial implementation is functionally complete and before declaring the task done, or when the user asks to "clean up," "simplify," or "tidy" code. Always run this before a final PR is opened — it's the last pass between "it works" and "it's ready for review."
---

# Code Simplify

A disciplined cleanup pass for code that already works. The point isn't to
change behavior — it's to remove the accumulated residue of active
development (abandoned attempts, now-unused imports, defensive complexity
that outlived its purpose) so the diff a human reviews is the smallest,
clearest version of the actual change, then prove nothing broke.

This is a *post-implementation* skill: run it after the feature/fix works and
before it's presented as done, not as a substitute for getting the logic
right in the first place.

## When to run this

- Immediately after an implementation is functionally complete, as the last
  step before running final verification and opening a PR.
- When the user explicitly asks to "clean up," "simplify," or "tidy" code.
- On existing code you're touching anyway for an unrelated change, *if* the
  simplification is small and directly adjacent to your change — don't turn
  an unrelated cleanup into scope creep on a feature PR (see
  `.claude/rules/git-workflow.md` on bounded PRs; a real cleanup pass on
  unrelated code deserves its own small PR).

## Process

### 1. Eliminate dead code, unused imports, and orphaned logic

- Remove functions, variables, and code branches that are no longer called
  or reachable as a result of this change — including anything left over
  from an earlier approach that got superseded during implementation.
- Remove unused imports/requires introduced or left behind by the change.
  Run the project's linter (most linters flag unused imports directly) as
  the first check rather than eyeballing every file.
- Remove orphaned variables: anything assigned but never read, destructured
  but never used, or captured in a closure but never referenced.
- **Apply Chesterton's Fence before deleting anything you didn't just write**
  (per `AGENTS.md` §2): if a piece of "dead" code predates your change,
  confirm via `git blame`/history that it's actually unused and not, e.g.,
  called via reflection/dynamic dispatch, referenced from a config file, or
  part of a public API another package depends on. When in doubt, flag it
  rather than deleting it silently.

### 2. Guard clause refactoring and boolean simplification

Look for deeply nested conditionals — the classic "arrow code" shape where
each new condition adds another level of indentation — and flatten them
using guard clauses (early returns) instead:

**Before:**
```javascript
function processOrder(order) {
  if (order) {
    if (order.items.length > 0) {
      if (order.customer.isVerified) {
        // actual logic, 4 levels deep
        return fulfill(order);
      } else {
        throw new Error("Customer not verified");
      }
    } else {
      throw new Error("Order has no items");
    }
  } else {
    throw new Error("Order is required");
  }
}
```

**After:**
```javascript
function processOrder(order) {
  if (!order) throw new Error("Order is required");
  if (order.items.length === 0) throw new Error("Order has no items");
  if (!order.customer.isVerified) throw new Error("Customer not verified");

  return fulfill(order);
}
```

The same guard-clause thinking applies to a **complex boolean condition** —
one `if` with enough `&&`/`||`/negation packed into it that a reader has to
mentally evaluate the expression rather than read its intent. Extract it into
a well-named predicate (a local variable or function) instead of leaving it
inline:

**Before:**
```javascript
if (user.role === "admin" || (user.role === "editor" && !document.isLocked && document.ownerId === user.id)) {
  return allowEdit(document);
}
```

**After:**
```javascript
const isAdmin = user.role === "admin";
const isUnlockedOwnDocument =
  user.role === "editor" && !document.isLocked && document.ownerId === user.id;

if (isAdmin || isUnlockedOwnDocument) {
  return allowEdit(document);
}
```

The extracted names document *why* the condition matters, not just what it
evaluates to character-by-character — which is the same win a guard clause
gets from flattening indentation, applied to the condition itself instead of
the branching structure around it.

Guidelines for this pass:

- Invert the condition and return/throw/continue early for the failure or
  edge case, so the main logic isn't nested inside it.
- Order guard clauses from cheapest/most-likely-to-fail-fast to most
  expensive, when order doesn't otherwise matter, so the function bails out
  as early as possible.
- Don't over-apply this — a guard clause that makes a two-line function
  harder to read for the sake of the pattern isn't an improvement, and a
  boolean condition that's already a single clear comparison doesn't need a
  named variable just to have one. The goal is readability, not mechanically
  eliminating every `else` or every inline condition.
- This is a refactor, not a rewrite: the observable behavior (what errors get
  thrown, what gets returned, for which inputs) must stay identical. If
  flattening the logic reveals that the original nested version had a bug
  (e.g. a missing check, an operator-precedence mistake in a boolean
  expression), fix that as a clearly-called-out, separate concern — don't
  silently change behavior inside what's presented as a pure simplification.

### 3. Verification pass — prove zero regressions

This is the step that makes the cleanup trustworthy rather than a leap of
faith. Follow `.claude/rules/testing.md` in full:

1. Run the project's actual test suite (or the correctly-scoped subset) using
   its real test command.
2. Confirm the pass/fail counts are identical before and after the
   simplification — same tests passing, none newly failing, none newly
   skipped.
3. Run build/typecheck/lint if the project has them, and confirm they still
   pass.
4. Show the real command and output in your report — "I simplified this and
   reran the tests, still green" without showing the actual output is not
   sufficient evidence per `AGENTS.md` §4.

If anything fails after the simplification pass, that means the
"simplification" changed behavior — treat it as a bug in your own refactor,
not a pre-existing issue, and fix or revert it before proceeding.

## Output format

Report the cleanup as a short summary, not a re-explanation of the whole
diff:

```markdown
## Cleanup pass: <feature/file(s)>

- Removed: <N unused imports, M dead functions/branches — name them briefly>
- Refactored: <N nested conditionals flattened to guard clauses, M complex
  boolean conditions extracted to named predicates in <file>>
- Verification: ran `<test command>` — <pass count> passing, unchanged from
  before cleanup. `<lint/build command>` — clean.
```

## Anti-patterns this skill prevents

- PRs that include leftover debugging code, abandoned approaches, or unused
  imports from the development process.
- Deeply nested conditional logic that's hard to reason about and easy to
  introduce bugs into on the next edit.
- A sprawling `&&`/`||` boolean expression that a reader has to trace
  operator-by-operator to understand, instead of reading a named predicate.
- "Simplification" that silently changes behavior because it was never
  actually re-verified against the test suite.
- Deleting code that looks dead but was actually load-bearing, because
  Chesterton's Fence wasn't checked first.
