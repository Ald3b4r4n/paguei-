<!--
SYNC IMPACT REPORT
==================
Version change: [unversioned] → 1.0.0
Modified principles: N/A (initial authoring — template placeholders replaced)
Added sections:
  - Core Principles (I through X)
  - Product Mission
  - Quality Gates for Merge
  - Delivery Governance
  - Governance
Templates reviewed:
  ✅ .specify/templates/plan-template.md — Constitution Check section aligns with principles below
  ✅ .specify/templates/spec-template.md — Functional Requirements and Success Criteria patterns compatible
  ✅ .specify/templates/tasks-template.md — TDD task ordering (tests-first pattern) compatible with Principle I
  ⚠  .specify/templates/commands/*.md — No commands/ directory found; no updates required at this time
Deferred items:
  - None. All fields resolved.
-->

# Paguei? Constitution

## Core Principles

### I. Test-Driven Development (NON-NEGOTIABLE)

Every feature MUST begin with failing tests before any implementation code is written.
The Red → Green → Refactor cycle is strictly enforced without exception.

- Tests MUST be written and reviewed before implementation begins.
- Bug fixes MUST include a regression test that reproduces the defect.
- Minimum coverage thresholds are enforced at merge time:
  - Domain layer: **95%**
  - Application layer: **90%**
  - Data layer: **80%**
- Widget tests MUST cover all critical UI flows.
- Integration tests MUST cover all user-facing feature journeys.
- No test — no merge. No exception.

### II. Clean Architecture

The codebase MUST enforce strict layered separation. Dependencies flow inward only.

```
lib/
├── presentation/   # Widgets, pages, UI state
├── application/    # Use cases, orchestration
├── domain/         # Entities, value objects, repository interfaces
├── data/           # Repository implementations, datasources, DTOs
└── core/           # Shared utilities, failures, extensions
```

- `domain/` MUST NOT import from Flutter or any infrastructure package.
- `presentation/` MUST NOT access repositories or datasources directly.
- Business logic MUST reside exclusively in `domain/` or `application/`.
- Infrastructure components (databases, APIs, storage) MUST be replaceable
  without modifying domain or application code.
- Cross-layer violations are defects and MUST be resolved before merge.

### III. Clean Code Standards

All code MUST be written for the next reader, not the original author.

- Names MUST be explicit and self-documenting. Abbreviations are forbidden.
- Functions MUST do one thing. If a function requires a comment to explain
  what it does, its name is wrong or it does too much.
- Classes MUST have a single, clearly stated responsibility.
- Dead code MUST NOT be committed. Delete it; version control remembers.
- Duplication MUST be eliminated. Three instances of the same logic require
  extraction.
- Cyclomatic complexity per function MUST be kept low (target ≤ 5).
- Refactoring is continuous, not scheduled. Leave code cleaner than found.
- Readability beats cleverness. If it needs a comment to be understood,
  rewrite it.

### IV. Documentation as Living Artifact

Documentation is not optional and is never "done later."

Maintained artifacts:
- `docs/architecture.md` — current system overview, layer responsibilities
- `docs/adr/` — Architecture Decision Records for every significant decision
- `CHANGELOG.md` — human-readable release history
- `specs/<feature>/spec.md` — feature specification before implementation

Rules:
- Every significant architectural decision MUST produce an ADR in `docs/adr/`
  before implementation begins.
- Any implementation change MUST be accompanied by corresponding doc updates
  in the same pull request.
- Outdated documentation is treated as a defect with the same priority as a
  failing test.
- Specifications in `.specify/` are the source of truth. Implementation MUST
  derive from them, not the reverse.

### V. Financial UX Clarity

The user MUST be able to answer "Paguei?" (Did I pay?) instantly from any
relevant screen.

The interface MUST make immediately visible:
- Current available balance
- What has been paid (this period)
- What is pending payment
- Upcoming bills and their due dates
- Spending trends and category breakdowns

Rules:
- Currency values MUST use `pt-BR` locale formatting (e.g., `R$ 1.234,56`).
- Typography for monetary amounts MUST be prominent and legible.
- Every user action MUST produce immediate visual feedback (loading states,
  confirmations, or errors).
- Ambiguous balance states (e.g., "unknown" or empty) are forbidden — the app
  MUST always show a clear, accurate figure or an explicit loading indicator.
- Destructive actions (delete expense, clear history) MUST require explicit
  user confirmation before execution.

### VI. Offline First

The app MUST be fully functional without network connectivity.

- All core features MUST operate using local persistence alone.
- Local storage MUST be the primary data source; remote sync is additive.
- The data layer MUST be architected to support future cloud sync without
  domain or application layer changes.
- Network errors MUST never crash or block the user from accessing their
  financial data.

### VII. Performance Standards

The app MUST feel fast and responsive on mid-range Android and iOS devices.

- Cold start time MUST be perceptually fast (target: < 2 seconds to first
  meaningful frame).
- List scrolling MUST maintain 60 fps without jank.
- Widget rebuilds MUST be minimized. Use `const` constructors, scoped
  providers, and selective rebuilds.
- Memory usage MUST be profiled before each release; leaks are defects.
- Heavy operations (file I/O, DB queries) MUST be executed off the main
  isolate.

### VIII. State Management Discipline

**Riverpod** is the mandated state management solution unless a written
architectural decision (ADR) specifies otherwise.

- Application state MUST be immutable. Use `copyWith` patterns or
  sealed/freezed classes.
- Side effects MUST be isolated to providers or use-case invocations.
  They MUST NOT live inside build methods or widgets.
- UI MUST react to state changes only — no imperative mutations from the
  presentation layer.
- Global mutable singletons are forbidden.
- Provider scope MUST be as narrow as the feature requires.

### IX. Security and Privacy

User financial data is sensitive. The app MUST handle it with care.

- Sensitive data (balances, account details) MUST NOT appear in logs,
  crash reports, or analytics events.
- Local storage of sensitive data MUST use encrypted storage
  (e.g., `flutter_secure_storage`).
- The architecture MUST be ready for biometric authentication without
  structural changes.
- Privacy-first decisions are the default: collect no data that is not
  strictly necessary.
- Third-party SDKs MUST be audited for data collection before adoption.

### X. Delivery Governance

No meaningful implementation work begins without an approved specification.

Every feature MUST follow this pipeline without skipping steps:

```
constitution → specify → clarify → plan → tasks → implement → test → document
```

- `specify`: Feature spec written and approved in `.specify/specs/`
- `clarify`: Open questions resolved before design begins
- `plan`: Technical plan written and approved in `specs/<feature>/plan.md`
- `tasks`: Atomic task list derived from plan in `specs/<feature>/tasks.md`
- `implement`: Code written test-first per Principle I
- `test`: All coverage thresholds met; widget and integration tests green
- `document`: Docs, ADRs, and CHANGELOG updated in the same PR

Skipping any step requires written justification and explicit approval.

## Product Mission

**If the user asks "Paguei?" — the app answers instantly.**

Paguei? is a personal finance management application for Brazilian users,
focused on expense tracking, bill reminders, cashflow visibility, budgeting,
and financial organization. Every product decision MUST serve this mission.

Features that do not directly improve the user's understanding of their
financial position require explicit justification.

## Quality Gates for Merge

A pull request MUST NOT be merged unless all of the following pass:

- [ ] All tests passing (unit, widget, integration)
- [ ] Coverage thresholds met (Domain ≥ 95%, Application ≥ 90%, Data ≥ 80%)
- [ ] `flutter analyze` clean — zero warnings, zero errors
- [ ] `flutter lint` clean per project lint rules
- [ ] Documentation updated (docs, ADR if applicable, CHANGELOG)
- [ ] At least one peer review approval
- [ ] No unresolved critical TODOs in changed files
- [ ] Architecture compliance verified (no cross-layer violations)
- [ ] Specification approved prior to implementation start

Any gate failure blocks merge. There are no exceptions for deadlines.

## Governance

This constitution supersedes all other project practices, conventions, and
preferences. When a conflict exists between this document and any other
guideline, this document prevails.

**Amendment procedure**:
1. Propose the amendment in a pull request modifying this file.
2. State the rationale, affected principles, and migration impact.
3. Obtain at least one additional approval beyond the author.
4. Increment the version per semantic versioning rules:
   - **MAJOR**: Backward-incompatible removal or redefinition of a principle.
   - **MINOR**: New principle or materially expanded guidance added.
   - **PATCH**: Clarifications, wording, or non-semantic refinements.
5. Update `LAST_AMENDED_DATE` to the merge date.
6. Propagate changes to affected templates and specs in the same PR.

**Compliance review**: Constitution compliance MUST be verified on every PR
via the Constitution Check section of the plan template. Reviewers are
responsible for enforcing it; authors are responsible for self-certifying it.

**Runtime guidance**: Refer to `.specify/` for spec templates, plan templates,
and task templates that operationalize these principles into daily workflow.

---

**Version**: 1.0.0 | **Ratified**: 2026-04-19 | **Last Amended**: 2026-04-19
