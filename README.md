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
│   │   └── git-workflow.md    # PR sizing, commit hygiene, & rationale tracking
│   └── skills/
│       ├── spec-first/        # Skill to convert vague prompts into structured specs
│       └── anti-surrender/    # Skill to enforce trade-off analysis & verification
└── guidelines/                # Curated AI engineering principles & transcript insights
```

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
