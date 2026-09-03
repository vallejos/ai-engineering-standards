# AI Engineering Guardrails & Skills Toolkit

> Production-grade rules, skills, and guardrails for Claude Code, Cursor, and AI agents. Portably externalizes engineering principles, spec-driven development, and verification checks into reusable `.claude` standards inspired by industry AI engineering best practices.

AI tools can generate endless output, but human engineers own the ultimate outcome. This repository provides a drop-in, portable set of agent rules (`AGENTS.md`), custom Claude Code skills, and modular guidelines (`.claude/`) to prevent cognitive surrender, enforce plan-first architecture, and maintain long-term codebase health across personal and enterprise environments.

---

## 💡 Core Philosophy

* **Outcome over Output:** AI generates code; humans verify, test, and own production reliability.
* **Plan-First Architecture:** Shift left by requiring clear specs and explicit trade-offs before touching production code.
* **Context & Memory Preservation:** Prevent context loss by updating state records and capturing architectural decisions in explicit project logs.
* **Portable Engineering Standards:** Bring the exact same high-bar rules to any workplace, personal machine, or developer CLI environment without lock-in.

---

## 📁 Repository Structure

```text
.
├── AGENTS.md                  # Root agent instructions (Claude Code, Cursor, Gemini CLI)
├── install.sh                 # Deployment script to symlink rules into target repos
├── .claude/
│   ├── CLAUDE.md              # Global Claude Code configuration & quality gates
│   ├── rules/
│   │   ├── spec-first.md      # Mandates plan mode before code execution
│   │   ├── testing.md         # Verification gates & test execution standards
│   │   ├── git-workflow.md    # PR sizing, commit hygiene, & rationale tracking
│   │   ├── resilience.md      # Failure recovery, Web Vitals, & DAMP testing standards
│   │   └── behaviors.md       # Non-negotiable agent behavioral guardrails
│   └── skills/
│       ├── spec-first/        # Skill to convert vague prompts into structured specs
│       ├── anti-surrender/    # Skill to enforce trade-off analysis & verification
│       ├── edge-case-audit/   # Skill to audit network, memory, & fallback-UI edge cases
│       └── code-simplify/     # Skill for post-build dead-code cleanup & verification
└── guidelines/                # Curated AI engineering principles & transcript insights
```

---

## 📦 What's Included

Every file in `.claude/rules/` and `.claude/skills/` targets a specific,
recurring failure mode in AI-assisted engineering — the goal is that an
engineer (or an org) can drop this repo into any project and immediately get
the same accountability guardrails, regardless of which AI tool they're
using or how experienced they are at prompting one.

### Rules (`.claude/rules/`)

Rules are loaded at session start with the same priority as `CLAUDE.md`, so
they're always in effect. None of them are path-scoped — they describe
*behavior* (plan first, verify before claiming done, handle the unhappy
path), not file types, so scoping them to a glob would just make them
silently miss cases. They set the standard; skills below give you the
executable workflow to actually meet it.

| Rule | What it enforces | Why it matters |
|---|---|---|
| `spec-first.md` | Requires a short spec (goal, non-goals, constraints, edge cases, plan) before non-trivial production code gets written. | Catches misunderstandings while they're a paragraph to edit, not a shipped feature to migrate — see "intent debt" in `guidelines/ai-engineering-principles.md`. |
| `testing.md` | Mandates real test execution and pasted output — not just a claim — before a change is reported as complete, plus deliberate boundary-condition coverage. | Confidence is cheap for a model to produce regardless of whether it's warranted. Verification evidence is the only thing that actually de-risks AI output. |
| `git-workflow.md` | Small, coherent commits; semantic commit/PR titles; ~150-line bounded PRs; ADRs for durable decisions; `state.md` for cross-session context handoff. | Keeps every PR small enough that human review is genuine evaluation, not a rubber stamp on a diff nobody could actually hold in their head. |
| `resilience.md` | Explicit timeouts/retries/fallbacks on network calls; no silently-swallowed async errors; critical-path (LCP-first) rendering over heavy client abstractions; DAMP over DRY in tests; an anti-rationalization table for common excuses to skip tests/specs/docs. | Most production incidents come from the unhappy path being unhandled, not the happy path being wrong. Directly inspired by Addy Osmani's performance and resilience engineering principles. |
| `behaviors.md` | Non-negotiable agent behaviors: surface assumptions before coding, stop on requirement conflicts, push back on bad patterns/security risks/tech debt, prefer simple solutions over clever abstractions, strict file-scope bounding. | Defines the baseline posture an agent should hold on *every* task — the always-on counterpart to the deliberate `anti-surrender` checkpoint below. |

### Skills (`.claude/skills/`)

Skills are invokable, structured workflows — call them by name in Claude
Code, or trigger them proactively when the task matches their description.

| Skill | What it does | When it triggers |
|---|---|---|
| `spec-first/` | Converts a vague, informal request into a structured spec/PRD: goals, non-goals, constraints, edge cases, an ordered implementation plan, and open questions flagged rather than silently guessed at. | New features, non-trivial fixes, or any request that leaves obvious gaps (unclear scope, no acceptance criteria). |
| `anti-surrender/` | Forces a structured trade-off analysis — name the easy path, generate real alternatives, make an actual recommendation, checkpoint with the human — before proceeding on ambiguous or irreversible decisions. | Before deleting/skipping a failing test, removing a guardrail, taking an irreversible action, or when requirements admit multiple valid interpretations. |
| `edge-case-audit/` | A DevTools-inspired audit pass across three areas: network conditions (high latency, offline, partial/malformed payloads), memory & lifecycle (leaked listeners, uncleared timers, stale state), and fallback UI (loading/error/empty states). | After implementing any feature that fetches data or subscribes to events, and before any PR touching async code is marked complete. |
| `code-simplify/` | Post-implementation cleanup: eliminates dead code, unused imports, and orphaned variables; refactors nested conditionals into guard clauses; then re-runs the test suite to prove zero behavioral regressions. | After an implementation is functionally complete, as the last pass before opening a PR. |

### Supporting documents

| File | Purpose |
|---|---|
| `AGENTS.md` | The portable, tool-agnostic baseline every rule and skill above builds on — respected by Claude Code, Cursor, Copilot, and Gemini CLI alike. |
| `.claude/CLAUDE.md` | Claude Code-specific configuration: code style, terminal execution safety, and the quality-gate checklist a task must clear before it's "done." |
| `guidelines/ai-engineering-principles.md` | The human-readable *why* behind every rule — accountability, product taste, intent debt, and context preservation, explained for the humans who own the outcome. |

### How this keeps engineers accountable

None of these rules and skills work by trusting an AI agent's self-reported
confidence — they work by replacing "trust me, it works" with structural
requirements: a spec before code, evidence before "done," a bounded diff a
human can actually review, and an explicit checkpoint before anything
irreversible happens. The AI agent can move fast; these guardrails make sure
speed doesn't quietly transfer accountability risk onto whoever approves the
PR without really being able to evaluate it.

---

## 🚀 Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/vallejos/ai-engineering-standards.git ~/ai-engineering-standards
```

### 2. Apply Standards to Any Target Codebase
Navigate to any local project directory and run the install script:

```bash
cd /path/to/your-target-project
~/ai-engineering-standards/install.sh --dry-run   # preview first — recommended
~/ai-engineering-standards/install.sh             # apply
```

The script is safe to run on a project that already has its own AI config —
it never overwrites or deletes anything you have:

| What you already have | What the script does |
|---|---|
| Nothing | Symlinks `AGENTS.md`, `.claude/CLAUDE.md`, `.claude/rules/`, `.claude/skills/` into place |
| Your own `.claude/rules/` or `.claude/skills/` | Leaves them alone; links each of our rules/skills in individually alongside yours |
| A rule or skill with the same name as one of ours (e.g. `rules/testing.md`) | Keeps yours untouched; adds ours as `ai-engineering-standards-testing.md` so both load |
| Your own `AGENTS.md` or `.claude/CLAUDE.md` | Keeps your content in place; appends ours below it as a clearly marked block that stays in sync on re-run |

It's idempotent — re-run it any time to pick up updates. Use `--dry-run` to
see exactly what it would do first. The script is POSIX `sh` and works on
macOS, Linux, and WSL; on native Windows, run it from WSL or Git Bash (with
Developer Mode enabled for symlinks).

### 3. Or Install Once, Machine-Wide (Recommended)

If you use Claude Code across many repos, install into your personal profile
instead of running the script per-project:

```bash
~/ai-engineering-standards/install.sh --user --dry-run   # preview first
~/ai-engineering-standards/install.sh --user              # apply
```

This installs only `.claude/CLAUDE.md`, `.claude/rules/`, and
`.claude/skills/` into `~/.claude/` — Claude Code applies personal rules in
`~/.claude/rules/` to every project on the machine automatically, so this is
a one-time setup rather than something you repeat per repo. `AGENTS.md` is
deliberately skipped in this mode: it's a project-root convention file that
Cursor, Copilot, and Gemini CLI look for per-repo, so a copy sitting in
`$HOME` would just be inert clutter nothing reads. Run the script without
`--user` inside a specific project if you also want the shared `AGENTS.md`
baseline there for those other tools.

The same non-destructive merge/coexist behavior from the table above applies
here too — safe to run against a `~/.claude/` that already has plenty of
your own rules and skills in it.

---

## 🛠️ Usage with AI Developer Tools

### **Claude Code**
Claude Code reads `.claude/CLAUDE.md`, `.claude/rules/`, and `.claude/skills/`.
It does **not** read `AGENTS.md` directly — which is why `.claude/CLAUDE.md`
starts with an `@../AGENTS.md` import line that pulls the shared baseline into
context automatically. Run `/context` in a session and confirm both appear
under **Memory files**.

* **Rules:** every file in `.claude/rules/` loads at session start with the
  same priority as `CLAUDE.md`, so they're always in effect.
* **Skills:** Claude uses them automatically when your request matches their
  description, or invoke one directly by name:
  ```bash
  claude "Use the spec-first skill to outline the auth refactor"
  ```
* If the first session shows a one-time approval dialog for an external
  import, that's the symlinked `CLAUDE.md` resolving `@../AGENTS.md` through
  the standards repo — approve it once and it won't ask again.

### **Cursor / Copilot / Gemini CLI / Codex**
These tools read `AGENTS.md` at the project root natively, so they pick up the
shared baseline (planning, verification gates, bounded PRs, Chesterton's
Fence) with no extra setup. They don't read `.claude/`, so the Claude-specific
rules and skills won't apply there — `AGENTS.md` is written to stand on its
own for exactly that reason. If Gemini CLI is configured to look only for
`GEMINI.md` in your environment, symlink it: `ln -s AGENTS.md GEMINI.md`.

---

## 📜 Rule Design & Best Practices

1. **Outer-Loop Accountability:** AI agents must provide verification evidence (e.g., passing test output or build logs) before declaring a task complete.
2. **Chesterton's Fence:** Before removing or heavily refactoring existing logic, agents must inspect git blame/history and state why the logic was originally written.
3. **Bounded Tasks:** Large features are broken down into small, verifiable pull requests under ~150 lines of code.

---

## 🤝 Contributing

Contributions are welcome! If you have additional rules, custom skills, or transcript summaries that improve AI-human collaboration, feel free to open a Pull Request.

1. Fork the repo.
2. Add your rule or skill under `.claude/rules/` or `.claude/skills/`.
3. Submit a PR with a brief rationale of the workflow problem it solves.

---

## 📄 License

Distributed under the [MIT License](LICENSE). Free for personal, open-source, and commercial engineering use.
