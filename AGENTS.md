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
