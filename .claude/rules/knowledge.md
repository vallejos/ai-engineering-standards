# Rule: Knowledge Store

## When this rule applies

This rule applies at the start of any non-trivial task, and again whenever
you learn something worth keeping beyond the current task. It is portable:
it describes what to read and what to write back, not where the store lives
or which tool reads it. The location is wiring, set up per machine outside
this repo.

The "knowledge store" is a private collection of plain notes about the
human's people, projects, topics, decisions and preferences. The "knowledge
index" is its single entry-point note: a short map that says what exists and
where. It is private to the human and is never part of any codebase.

## 1. Read the index before non-trivial work

- If a knowledge index is available, read it before planning or editing.
  It is deliberately short.
- Open only the notes the index points to for the task at hand. Do not load
  the whole store.
- If the index and a codebase disagree, the codebase wins for facts about
  the code. Flag the stale note instead of silently trusting either.

## 2. Write back only durable facts

Record a note only if it will still be true and useful in a later session:

- **Decisions** and the reason for them.
- **Constraints** that are not obvious from the code.
- **Preferences** the human has stated or corrected you on.
- **Gotchas** that cost real time to find.

Never record task progress, status, to-do lists, or a log of what you did.
That belongs in the PR, the issue tracker, or a session handoff file
(see `.claude/rules/git-workflow.md`), and goes stale within days.

## 3. One subject per note; update, don't duplicate

- Before creating a note, search the store for an existing one on the same
  subject and edit it.
- Keep one subject per note. Split a note when it covers two.
- Keep the index current: add a line for a new note, fix a line when a note
  is renamed or removed. Keep the index short enough to read in one pass.
- When a fact changes, replace the old one. Do not leave both.

## 4. Decide where a fact belongs

| The fact is about... | It goes to... |
|---|---|
| A decision about a specific codebase | An ADR in that repo (see `.claude/rules/git-workflow.md`) |
| The human personally, or spans several projects | The knowledge store |
| Task progress | Nowhere durable; use the PR or handoff file |

A project note in the store may link to a repo's ADR but should not copy it.

## 5. Never store secrets

Do not write credentials, tokens, keys, private keys, recovery codes, or
personal identifiers (government, financial, health) into the store. If a
note needs to refer to one, name where it is kept, not the value. If you find
a secret already in the store, tell the human instead of editing around it.

## Anti-patterns this rule prevents

- Re-asking the human for context they already gave in an earlier session.
- A store that fills with status updates until nobody trusts it.
- Three near-duplicate notes on the same subject, each partly stale.
- A codebase decision recorded only in private notes, invisible to the team.
- A credential pasted into a note that gets synced or shared.
