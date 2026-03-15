# Actor-Critic Agent Loop Contract

A domain-agnostic, reusable multi-agent development loop. All project-specific details (language, framework, design system, build commands) are injected via **context documents** — these contracts define only the communication protocol, roles, and quality gates.

## Context Injection

Before spawning agents, the team lead injects domain context into each agent's prompt from external sources:

| Context Source | What It Provides | Injected Into |
|----------------|------------------|---------------|
| `CLAUDE.md` / project docs | Tech stack, build commands, architecture patterns | All agents |
| Design system docs | Color tokens, typography, spacing, component library | Designer, Developer, QA |
| Codebase exploration | Existing code patterns, file structure | Designer (via exploration) |
| User interview | Feature scope, acceptance criteria, preferences | All agents (via INTENT_SPEC) |

Agents never assume a language, framework, or toolchain — they read it from context.

## Pattern

```
User (Prime Intellect)
        ↕ (interview)
HumanIntent (Actor 0)
        │
    INTENT_SPEC
        │
        ▼
Product Designer (Actor 1)
        │
    DESIGN_SPEC
        │
        ▼
    Team Lead (Orchestrator)
        │
    DESIGN_SPEC
        │
        ▼
   Developer (Actor 2)
        │
    IMPL_REPORT
        │
        ▼
    Team Lead
        │
    IMPL_REPORT
        │
        ▼
      QA (Critic)
        │
    QA_REPORT
        │
        ├── VERDICT: approved → Done
        │
        └── VERDICT: needs_revision
                │
            REVISION_NOTES
                │
                ▼
           Developer fixes → QA re-validates → loop
```

## Roles

| Role | Type | Responsibility |
|------|------|----------------|
| HumanIntent | Actor 0 | Interview user, produce INTENT_SPEC |
| Product Designer | Actor 1 | Explore codebase, produce DESIGN_SPEC |
| Developer | Actor 2 | Implement DESIGN_SPEC, produce IMPL_REPORT |
| QA | Critic | Validate implementation, produce QA_REPORT |
| Team Lead | Orchestrator | Route messages, enforce contract, manage lifecycle |

## Message Types

| Message | From | To | Purpose |
|---------|------|----|---------|
| `INTENT_SPEC` | HumanIntent → Lead | Lead → Designer | Scoped requirements from user interview |
| `DESIGN_SPEC` | Designer → Lead | Lead → Developer | Component-level design specification |
| `IMPL_REPORT` | Developer → Lead | Lead → QA | Implementation summary with build status |
| `QA_REPORT` | QA → Lead | Lead → Developer/Designer | Validation results with verdict |
| `REVISION_NOTES` | Lead | Developer or Designer | Specific fixes required from QA critique |

## Acceptance Criteria (per phase)

| Phase | Acceptance Criteria |
|-------|--------------------|
| Intent | User interviewed (max 6 questions). INTENT_SPEC has vision, scope, constraints, acceptance criteria, test scenarios. User confirmed. |
| Design | DESIGN_SPEC covers all components, states (default, empty, error, edge), design tokens, interactions. Each component specifies test scenarios. Satisfies INTENT_SPEC scope. |
| Implement | Project builds clean. All DESIGN_SPEC components implemented. IMPL_REPORT includes test criteria verification. |
| QA | All test criteria exercised (build, design, pattern, accessibility, edge cases, data flow). QA_REPORT includes per-criteria pass/fail. |

## Test Criteria (embedded in loop)

Each phase carries forward test criteria that the next phase must verify:

```
INTENT_SPEC includes:
  USER_ACCEPTANCE_CRITERIA:
    - Verifiable conditions the user will check
  TEST_SCENARIOS (user-defined):
    - High-level behavior expectations from user perspective

DESIGN_SPEC includes:
  TEST_SCENARIOS per component:
    - Expected behavior for each interaction
    - Edge case inputs and expected outputs
    - Visual/behavioral states to verify

IMPL_REPORT includes:
  TEST_CRITERIA_VERIFIED:
    - Build: pass/fail
    - Each TEST_SCENARIO from DESIGN_SPEC: implemented/skipped + reason

QA_REPORT includes:
  TEST_RESULTS:
    - Build verification: pass/fail
    - Design consistency: pass/fail per category
    - Pattern consistency: pass/fail per pattern
    - Accessibility: pass/fail per element
    - Edge cases: pass/fail per scenario
    - Data flow: pass/fail per model/type
    - USER_ACCEPTANCE_CRITERIA: pass/fail per criterion
```

## Termination Condition

QA issues `VERDICT: approved` with zero blocker-severity issues, all test criteria passed, and all USER_ACCEPTANCE_CRITERIA verified.

## Task Dependencies

```
Task 0: Intent    (no blockers)
Task 1: Design    (blocked by Task 0)
Task 2: Implement (blocked by Task 1)
Task 3: Validate  (blocked by Task 2)
```

## Agent Lifecycle

1. HumanIntent spawns → interviews user → produces INTENT_SPEC → shuts down
2. Designer spawns → explores codebase + INTENT_SPEC → produces DESIGN_SPEC → shuts down
3. Developer spawns → implements → stays idle during QA
4. QA spawns → validates → issues verdict
5. If `needs_revision`: Lead relays critique to Developer → Developer fixes → Lead relays to QA → QA re-validates
6. If `approved`: All agents shut down, team dissolved

## Project Conventions (injected, not hardcoded)

Agents derive all project-specific rules from context injection:
- **Build command**: from CLAUDE.md or Taskfile (e.g., `swift build`, `npm run build`, `cargo build`)
- **Design system**: from project design docs or codebase exploration
- **Architecture patterns**: from CLAUDE.md and existing code
- **File conventions**: from codebase exploration (prefer edit over create)

No contract references a specific language, framework, or tool.
