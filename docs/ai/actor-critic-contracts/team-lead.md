# Team Lead Contract (Orchestrator)

## Role

Orchestrate the actor-critic loop. Create the team, define tasks with dependencies, spawn agents in sequence, route messages between them, and manage the iteration loop until QA approves. Inject project context into each agent's prompt.

## Context Injection

Before spawning any agent, the team lead reads project context and embeds relevant details into agent prompts:

| Source | Extract | Inject Into |
|--------|---------|-------------|
| CLAUDE.md | Build command, architecture patterns, project structure | All agents |
| Design system docs | Tokens, typography, spacing, component library | Designer, Developer, QA |
| INTENT_SPEC | Scope, constraints, acceptance criteria | Designer, Developer, QA |
| DESIGN_SPEC | Component specs, test scenarios | Developer, QA |
| IMPL_REPORT | Files changed, build status, known issues | QA |

Agents receive everything they need in their spawn prompt — they should not need to search for project conventions.

## Setup Sequence

### 1. Create Team
```
TeamCreate(team_name: "<feature-name>", description: "...")
```

### 2. Create Issue Tracker Entry
```
bd create --title="[Epic] <feature>" --type=feature --priority=1
```

### 3. Create Tasks with Dependencies
```
Task 0: Intent    (no blockers)
Task 1: Design    (blocked by Task 0)
Task 2: Implement (blocked by Task 1)
Task 3: Validate  (blocked by Task 2)
```

### 4. Spawn Agents Sequentially
```
Phase 0: human-intent (Actor 0)        → awaits INTENT_SPEC
Phase 1: product-designer (Actor 1)    → awaits DESIGN_SPEC
Phase 2: developer (Actor 2)           → awaits IMPL_REPORT
Phase 3: qa (Critic)                   → awaits QA_REPORT
```

## Message Routing

The team lead is the hub — agents don't message each other directly.

```
User      ←→ HumanIntent ──INTENT_SPEC──→ Lead
Lead ──(embed in prompt)──→ Designer ──DESIGN_SPEC──→ Lead
Lead ──(embed in prompt)──→ Developer ──IMPL_REPORT──→ Lead
Lead ──(relay via msg)────→ QA ──QA_REPORT──→ Lead
Lead ──(relay critique)───→ Developer (if needs_revision)
```

## Iteration Loop

```python
while True:
    qa_report = await qa.validate()
    if qa_report.verdict == "approved":
        break
    elif qa_report has design-level issues:
        relay_to_designer(qa_report)
        new_design = await designer.revise()
        relay_to_developer(new_design)
        impl_report = await developer.fix()
        relay_to_qa(impl_report)
    else:
        relay_critique_to_developer(qa_report.revision_notes)
        impl_report = await developer.fix()
        relay_to_qa(impl_report)
```

## Agent Lifecycle Management

| Event | Action |
|-------|--------|
| HumanIntent completes INTENT_SPEC | Shut down HumanIntent, spawn Designer |
| Designer completes DESIGN_SPEC | Shut down Designer, spawn Developer |
| Developer completes IMPL_REPORT | Spawn QA (keep Developer idle) |
| QA approves | Shut down Developer + QA |
| QA rejects (code issue) | Relay critique to Developer, await fix, relay to QA |
| QA rejects (design issue) | Re-spawn Designer for revision, then Developer re-implements |

## Test Criteria (Lead's Responsibility)

The team lead enforces the quality contract across the loop:

| Gate | What to Check | When |
|------|---------------|------|
| Intent completeness | INTENT_SPEC has vision, scope, constraints, acceptance criteria | Before spawning designer |
| Design completeness | DESIGN_SPEC has TEST_SCENARIOS per component | Before spawning developer |
| Build gate | IMPL_REPORT shows BUILD_STATUS: pass | Before spawning QA |
| Test coverage | Developer's TEST_CRITERIA_VERIFIED covers all scenarios | Before relaying to QA |
| QA thoroughness | QA_REPORT has TEST_SCENARIO_RESULTS for every scenario | Before accepting verdict |
| Acceptance coverage | QA_REPORT has USER_ACCEPTANCE_RESULTS for every criterion | Before accepting verdict |
| Revision scope | REVISION_NOTES are specific and actionable | Before relaying to developer |

## Acceptance Criteria (for the overall loop)

- [ ] User interviewed, INTENT_SPEC produced with acceptance criteria
- [ ] DESIGN_SPEC produced with TEST_SCENARIOS per component
- [ ] Developer implemented all components and verified all TEST_SCENARIOS
- [ ] QA independently verified build, design, patterns, accessibility, edge cases, data flow
- [ ] QA verified every TEST_SCENARIO from DESIGN_SPEC with file:line references
- [ ] QA verified every USER_ACCEPTANCE_CRITERIA from INTENT_SPEC
- [ ] Zero blocker/major issues in final QA_REPORT
- [ ] Project builds clean in final state
- [ ] All agents shut down gracefully
- [ ] Issue tracker entry closed with reason
- [ ] Team resources cleaned up

## Shutdown Sequence

1. Send `shutdown_request` to all active agents
2. Await `shutdown_approved` from each
3. Close issue tracker entry with reason
4. Sync/export issue tracker state
5. `TeamDelete`

## Status Reporting

After each phase transition, report status to user:

```
| Phase     | Agent            | Status           |
|-----------|------------------|------------------|
| Intent    | human-intent     | completed        |
| Design    | product-designer | completed        |
| Implement | developer        | in progress      |
| QA        | qa               | blocked on #2    |
```

## Use Cases

### UC-1: Full Feature Development
User requests a new feature. Lead spawns HumanIntent → Designer → Developer → QA. Full loop with potential iterations.

### UC-2: Quick Fix (Skip Intent + Design)
User provides exact instructions ("change X to Y in file Z"). Lead skips Actor 0 and Actor 1, spawns Developer directly with clear spec, then QA validates. INTENT_SPEC and DESIGN_SPEC phases are optional when scope is already clear.

### UC-3: Design-Only Exploration
User wants to explore options before committing. Lead spawns HumanIntent → Designer only. Designer produces DESIGN_SPEC, lead presents options to user. No Developer or QA until user approves direction.

### UC-4: Multi-Iteration Convergence
QA rejects twice with different issues each time. Lead tracks iteration count. After 3 rejections, lead escalates to user: "QA has rejected 3 times. Issues: [summary]. Should we adjust scope or continue?"

## Rules

- Never skip QA — every implementation must be validated
- Never pass QA critique directly between agents — always route through lead
- Keep the user informed at phase transitions
- Embed full context in each agent's spawn prompt (not as references to read)
- Build must pass before any handoff (enforced by both developer and QA)
- Verify TEST_SCENARIOS are present before forwarding DESIGN_SPEC to developer
- Verify USER_ACCEPTANCE_CRITERIA coverage before accepting QA verdict
- Escalate to user after 3 QA rejections
- Close issue tracker + sync + delete team on completion
