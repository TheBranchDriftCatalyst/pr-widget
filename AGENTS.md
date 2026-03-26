# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Agent Contracts

This project uses a structured multi-agent development loop. Each agent role has a formal contract defining inputs, outputs, and quality gates.

### Actor-Critic Loop

The core development pattern. Contracts live at the workspace level.

| Role | Type | Contract |
|------|------|----------|
| Overview | Pattern | [overview.md](../../docs/ai/actor-critic-contracts/overview.md) |
| Human Intent | Actor 0 | [human-intent.md](../../docs/ai/actor-critic-contracts/human-intent.md) |
| Product Designer | Actor 1 | [product-designer.md](../../docs/ai/actor-critic-contracts/product-designer.md) |
| Developer | Actor 2 | [developer.md](../../docs/ai/actor-critic-contracts/developer.md) |
| QA Critic | Critic | [qa-critic.md](../../docs/ai/actor-critic-contracts/qa-critic.md) |
| Team Lead | Orchestrator | [team-lead.md](../../docs/ai/actor-critic-contracts/team-lead.md) |

Issue tracking integration: [beads-integration.md](../../docs/ai/actor-critic-contracts/beads-integration.md)

### Utility Agents

Standalone agents for CI/CD, security, and repo maintenance.

| Agent | Purpose | Definition |
|-------|---------|------------|
| secrets-scanner | Scan git history for leaked credentials | [secrets-scanner.md](../../docs/agents/secrets-scanner.md) |
| code-auditor | Audit codebase for sensitive data and PII | [code-auditor.md](../../docs/agents/code-auditor.md) |
| repo-hygiene | Review .gitignore, permissions, public readiness | [repo-hygiene.md](../../docs/agents/repo-hygiene.md) |

## Landing the Plane (Session Completion)

**When ending a work session**, complete ALL steps below. Work is NOT complete until `git push` succeeds.

1. **File issues for remaining work** — `bd create` for anything needing follow-up
2. **Run quality gates** (if code changed) — `task build`, `task test`
3. **Update issue status** — `bd close` finished work, update in-progress items
4. **Push to remote**:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Verify** — All changes committed AND pushed

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
