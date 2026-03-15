# Beads Integration in Actor-Critic Loop

## Overview

Beads replaces TaskCreate/TaskUpdate as the issue tracker for the actor-critic loop. Each agent creates, updates, and closes beads issues as part of their workflow. This provides persistent, dependency-aware tracking that survives session compaction.

## Issue Type Mapping

| Agent | Creates | Issue Type | Purpose |
|-------|---------|------------|---------|
| HumanIntent | Requirements | `epic` | Top-level feature scope from user interview |
| Product Designer | Design specs | `feature` | Component-level design specifications |
| Developer | Discoveries | `task` or `chore` | Implementation findings, refactor opportunities |
| QA | Bugs | `bug` | Defects found during validation |
| Team Lead | Coordination | `task` | Meta-tasks for loop management |

## Beads Fields Used

| Field | Who Sets It | When |
|-------|-------------|------|
| `title` | Creator | On create |
| `description` | Creator | On create |
| `issue_type` | Creator | On create (bug/feature/task/epic/chore) |
| `priority` | Creator / QA | On create; QA may escalate |
| `design` | Designer | Design spec notes for the component |
| `acceptance` | HumanIntent / QA | User acceptance criteria; QA adds test criteria |
| `status` | Any agent | open → in_progress → closed |
| `assignee` | Team Lead | Routes work to agents |
| `deps` | Any agent | Dependency chain between issues |
| `labels` | Any agent | Categorization (e.g., "design", "qa", "iteration-2") |

## Workflow: Beads Per Phase

### Phase 0: HumanIntent

```
bd create --type=epic --title="[Epic] <feature name>"
  --description="<INTENT_SPEC summary>"
  --acceptance="<USER_ACCEPTANCE_CRITERIA as checklist>"
  --priority=1
```

All subsequent issues created by other agents get `deps` pointing to this epic.

### Phase 1: Product Designer

For each component in the DESIGN_SPEC:
```
bd create --type=feature --title="<ComponentName> design"
  --description="<LAYOUT + INTERACTIONS>"
  --design="<DESIGN_TOKENS + PROPS>"
  --acceptance="<TEST_SCENARIOS for this component>"
  --deps=["<epic-id>"]
```

### Phase 2: Developer

On implementation:
```
bd update <feature-id> --status=in_progress --assignee=developer
```

If developer discovers something unexpected:
```
bd create --type=task --title="[Discovery] <finding>"
  --description="<what was discovered, impact, recommendation>"
  --deps=["<feature-id>"]
  --labels=["discovery"]
```

Discoveries route back to Product Designer for spec revision if they affect design.

On completion:
```
bd close <feature-id> --reason="Implemented per DESIGN_SPEC"
```

### Phase 3: QA

On finding a defect:
```
bd create --type=bug --title="[QA] <defect description>"
  --description="<file:line, expected vs actual, severity>"
  --priority=<0-4 based on severity>
  --deps=["<feature-id>"]
  --labels=["qa", "iteration-<N>"]
  --assignee=developer
```

Bug severity → beads priority mapping:
| QA Severity | Beads Priority | Meaning |
|-------------|---------------|---------|
| blocker | P0 | Must fix before approval |
| major | P1 | Must fix before approval |
| minor | P3 | Note but doesn't block |

On approval:
```
bd close <all-bug-ids> --reason="Verified fixed"
bd update <epic-id> --notes="QA approved, all test scenarios pass"
```

## Dependency Graph

```
Epic (HumanIntent)
  ├── Feature: Component A (Designer)
  │     ├── Bug: Double opacity (QA) → assigned to Developer
  │     └── Discovery: Shared utility (Developer) → assigned to Designer
  ├── Feature: Component B (Designer)
  │     └── Bug: Missing plural (QA) → assigned to Developer
  └── Task: Cleanup duplicated code (Developer)
```

## Cross-Agent Issue Flow

```
Designer creates feature → Developer claims → Developer discovers issue
                                                     │
                                              creates discovery task
                                                     │
                                            deps on original feature
                                                     │
                                     Team Lead routes to Designer
                                                     │
                                          Designer revises spec
                                                     │
                                     Developer re-implements
                                                     │
                                          QA validates
                                                     │
                                    ┌─── finds bug → creates bug issue
                                    │                      │
                                    │              Developer fixes
                                    │                      │
                                    │              QA re-validates
                                    │                      │
                                    └─── approved → closes all issues
```

## Beads Commands for Agents

Each agent has access to beads via CLI (`bd`) or MCP tools. Prefer MCP tools when available:

| Action | CLI | MCP Tool |
|--------|-----|----------|
| Create issue | `bd create --title="..." --type=bug` | `mcp__plugin_beads_beads__create` |
| Update status | `bd update <id> --status=in_progress` | `mcp__plugin_beads_beads__update` |
| Close issue | `bd close <id>` | `mcp__plugin_beads_beads__close` |
| Add dependency | `bd dep add <child> <parent>` | `mcp__plugin_beads_beads__dep` |
| View issue | `bd show <id>` | `mcp__plugin_beads_beads__show` |
| List open | `bd list --status=open` | `mcp__plugin_beads_beads__list` |
| Find ready work | `bd ready` | `mcp__plugin_beads_beads__blocked` (inverse) |
| Project stats | `bd stats` | `mcp__plugin_beads_beads__stats` |

## Session Resilience

Beads issues survive session compaction. If context is lost:
1. `bd prime` re-injects beads context
2. Agents can read their assigned issues to resume work
3. Dependency graph shows what's blocked and what's ready
4. The epic's acceptance criteria defines the overall quality gate

## Closing Protocol

When the loop terminates (QA approved):
```
1. Close all remaining open issues (features, tasks)
2. Close the epic with summary reason
3. bd sync --flush-only  (export to JSONL)
4. TeamDelete
```
