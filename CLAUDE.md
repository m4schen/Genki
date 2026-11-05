@AGENTS.md

# Claude Code specifics

`AGENTS.md` above is the source of truth. This file adds only what is specific to Claude Code.

- **Skills.** This repo doesn't include them (D-003). If you installed them yourself, start non-trivial work with `/ub-mode` or `pstack:poteto-mode`. They are optional because `AGENTS.md` already contains the rules. If a skill and `AGENTS.md` disagree, `AGENTS.md` wins.
- **Git.** Before your first commit in a session, create a feature branch if you are on `main`. Ask before pushing or opening a PR.
- **Design work (M4).** Present design directions as clickable mockups the human can open, such as an Artifact, not as prose descriptions.
- **Plan mode first** for SwiftData model or migration changes, anything near `HealthDataIntegration`, and any change that touches more than three files.
- **Prove UI changes yourself.** Build, launch in the iOS Simulator, and take a screenshot. Do not ask the human to check something you can check.
- **Subagents.** Use `Explore` for broad code searches. Code-writing subagents work in their own worktree. Verify a subagent's claims before you report them.
- **Memory.** Project decisions go in `docs/DECISIONS.md`, not in Claude memory. Memory is only for preferences about how this human likes to work.
- **Task list.** Keep the session task list in sync with the `docs/TODO.md` item you are working on.
