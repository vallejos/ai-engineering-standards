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

Rules are lazy-loaded — Claude Code pulls them in automatically when the
context matches (editing tests, opening a plan, making a commit, touching
async code). They set the standard; skills below give you the executable
workflow to actually meet it.

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
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/ai-engineering-standards
```

### 2. Apply Standards to Any Target Codebase
Navigate to any local project directory and run the install script to symlink the guardrails into place:

```bash
cd /path/to/your-target-project
~/ai-engineering-standards/install.sh
```

This symlinks `AGENTS.md` and `.claude/` directly into your target project so your AI tools adopt your rules instantly.

---

## 🛠️ Usage with AI Developer Tools

### **Claude Code CLI**
Claude Code automatically detects `AGENTS.md`, `.claude/CLAUDE.md`, `.claude/rules/`, and `.claude/skills/`.

* **Triggering Rules:** Rules inside `.claude/rules/` are lazy-loaded when editing relevant files.
* **Using Custom Skills:** Invoke custom skills in chat:
  ```bash
  claude "Use the spec-first skill to outline the auth refactor"
  ```

### **Cursor / Copilot / Gemini CLI**
All modern agent tools parse `AGENTS.md` at the project root to respect boundaries, testing mandates, and verification gates.

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
