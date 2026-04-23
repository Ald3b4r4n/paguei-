# Tasks: Corrigir erro ao registrar receita

**Input**: Design documents from `/specs/001-planeje-corrigir-o/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/transaction-form-ui-contract.md, quickstart.md
**Tests**: Required. This feature follows TDD and must add failing regression tests before implementation.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks
- **[Story]**: Maps to the user story from `spec.md`
- Each task includes exact repository file paths

---

## Phase 1: Setup (Shared Context)

**Purpose**: Confirm the current form, provider, and test seams before writing failing tests.

- [X] T001 Review the current create transaction form state and submit path in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T002 Review the existing account dropdown pattern in `lib/presentation/transactions/transfer_form_screen.dart`
- [X] T003 Review current widget-test provider overrides and helper gaps in `test/presentation/transactions/transaction_form_screen_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add reusable test seams needed by every create-transaction journey.

**CRITICAL**: Complete this phase before user story tasks.

- [X] T004 Add configurable account-list, navigation, and create-use-case spy helpers in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T005 Add repository/use-case spy support for empty `accountId` validation in `test/application/transactions/create_transaction_use_case_test.dart`

**Checkpoint**: Widget and application tests can express account-selection scenarios without touching production code.

---

## Phase 3: User Story 1 - Registrar receita com sucesso (Priority: P1) MVP

**Goal**: The user can create an income transaction with a valid visible account selection, and the create use case receives `TransactionType.income` plus a valid `accountId`.

**Independent Test**: Open the form with active accounts, select Receita, fill required fields, select an account, tap Registrar, and verify `CreateTransactionUseCase.execute` is called exactly once with income and the selected account.

### Tests for User Story 1

> Write these tests first and confirm they fail before implementation.

- [X] T006 [US1] Add failing widget test reproducing income save failure with account selection in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T007 [US1] Add failing widget regression test for switching Despesa to Receita while preserving selected account payload in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T008 [US1] Add failing widget test proving exactly one active account is auto-selected for income submit in `test/presentation/transactions/transaction_form_screen_test.dart`

### Implementation for User Story 1

- [X] T009 [US1] Watch `accountsStreamProvider` and render loading/error/data states in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T010 [US1] Add an account selector component based on `DropdownButtonFormField<Account>` in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T011 [US1] Insert the account selector into `TransactionFormScreen` before category/notes fields in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T012 [US1] Auto-select the only active account when `accountsStreamProvider` returns exactly one account in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T013 [US1] Preserve `existingTransaction.accountId` during edit mode and clear it only when it is no longer available in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T014 [US1] Submit the selected account id to `createTransactionUseCaseProvider.execute` for income and expense creation in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T015 [US1] Run focused P1 tests in `test/presentation/transactions/transaction_form_screen_test.dart`

**Checkpoint**: User Story 1 is independently functional and income creation no longer fails because of an invisible account requirement.

---

## Phase 4: User Story 2 - Entender claramente a exigencia de conta (Priority: P2)

**Goal**: With multiple active accounts, the form makes account selection mandatory, shows `Selecione uma conta` on the account field, and does not call the create use case until a valid account is chosen.

**Independent Test**: Open the form with two active accounts, fill other required fields, do not select an account, tap Registrar, and verify field-level validation plus zero create-use-case calls.

### Tests for User Story 2

> Write these tests first and confirm they fail before implementation.

- [X] T016 [P] [US2] Add failing use case test for empty `accountId` / missing account selection in `test/application/transactions/create_transaction_use_case_test.dart`
- [X] T017 [US2] Add failing widget test for multiple accounts without selection showing `Selecione uma conta` and blocking save in `test/presentation/transactions/transaction_form_screen_test.dart`

### Implementation for User Story 2

- [X] T018 [US2] Add minimal empty `accountId` guard in `lib/application/transactions/create_transaction_use_case.dart`
- [X] T019 [US2] Move missing-account feedback into the account selector validator with message `Selecione uma conta` in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T020 [US2] Ensure `_save` returns before setting saving state or calling create/update use cases when account validation fails in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T021 [US2] Run focused P2 tests in `test/application/transactions/create_transaction_use_case_test.dart` and `test/presentation/transactions/transaction_form_screen_test.dart`

**Checkpoint**: User Story 2 is independently functional and missing account selection is explicit, field-level, and non-persistent.

---

## Phase 5: User Story 3 - Tratar ausencia de contas ativas (Priority: P3)

**Goal**: With zero active accounts, the form shows guided empty-state copy, offers a path to create an account, and keeps Registrar disabled.

**Independent Test**: Open the form with an empty account stream and verify the guidance, the create-account CTA route, and disabled submit state.

### Tests for User Story 3

> Write these tests first and confirm they fail before implementation.

- [X] T022 [US3] Add failing widget test for zero accounts showing guided empty state and disabled Registrar in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T023 [US3] Add failing widget test for the zero-account CTA navigating to `/contas/nova` in `test/presentation/transactions/transaction_form_screen_test.dart`

### Implementation for User Story 3

- [X] T024 [US3] Add a zero-accounts empty-state widget with action copy and CTA in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T025 [US3] Wire the empty-state CTA to `AppRoutes.accountNew` in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T026 [US3] Disable the Registrar/Salvar button while there are zero active accounts in `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T027 [US3] Run focused P3 tests in `test/presentation/transactions/transaction_form_screen_test.dart`

**Checkpoint**: User Story 3 is independently functional and users without accounts get a clear recovery path.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Regression coverage, docs, and final validation across transaction flows.

- [X] T028 Add regression widget test for expense creation with selected account in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T029 Add regression widget test for income creation after account auto-selection in `test/presentation/transactions/transaction_form_screen_test.dart`
- [X] T030 Verify transfer behavior remains unchanged by running transfer-related tests in `test/application/transactions/get_monthly_transactions_use_case_test.dart`
- [X] T031 Verify transaction entity behavior remains unchanged by running transaction domain tests in `test/domain/entities/transaction_test.dart`
- [X] T032 Update final manual validation steps for the account selector UI in `specs/001-planeje-corrigir-o/quickstart.md`
- [X] T033 Run the full focused create-transaction regression suite in `test/presentation/transactions/transaction_form_screen_test.dart` and `test/application/transactions/create_transaction_use_case_test.dart`
- [X] T034 Run static analysis for the changed Flutter files with `flutter analyze`
- [X] T035 Run the full Flutter test suite with `flutter test`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies.
- **Phase 2**: Depends on Phase 1 and blocks all user-story tests.
- **Phase 3 (US1)**: Depends on Phase 2 and is the MVP.
- **Phase 4 (US2)**: Depends on Phase 2; can run after or alongside US1 only if file ownership is coordinated.
- **Phase 5 (US3)**: Depends on Phase 2; should integrate after the account selector exists.
- **Phase 6**: Depends on desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Independent after foundational test helpers.
- **US2 (P2)**: Independent validation path, but shares `transaction_form_screen.dart`; implement sequentially with US1 in a single-developer flow.
- **US3 (P3)**: Builds on the account stream handling and selector state from US1.

### Required TDD Order

- T006-T008 must fail before T009-T014.
- T016-T017 must fail before T018-T020.
- T022-T023 must fail before T024-T026.
- T028-T029 should fail if the create journey regresses, then pass after final integration.

---

## Parallel Opportunities

- T016 and T018 touch application-layer files and can be handled separately from widget-file tasks once T005 is done.
- US1, US2, and US3 tests are conceptually independent, but most widget tasks touch `test/presentation/transactions/transaction_form_screen_test.dart`; coordinate file ownership before parallel work.
- T030 and T031 can run in parallel with documentation updates once implementation is complete.

---

## Implementation Strategy

### MVP First

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 only.
3. Validate income creation with account selection using `test/presentation/transactions/transaction_form_screen_test.dart`.

### Incremental Delivery

1. Add US1 to unblock income creation.
2. Add US2 to make the required account validation clear for multiple accounts.
3. Add US3 to handle zero-account users with guidance and disabled submit.
4. Finish Phase 6 to confirm expense, income, transfer, docs, analyze, and full tests.

### Risk Notes

- Keep changes out of Drift schema, repository contracts, and `Transaction` entity validation unless a failing test proves otherwise.
- Avoid changing `TransferFormScreen`; use it only as a visual/validation pattern reference.
- Guard against auto-selecting the first account when multiple active accounts exist.
