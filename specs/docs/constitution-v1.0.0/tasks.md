# Tasks: Paguei? — Backlog Completo de Implementação

**Input**: Documentos de design em `specs/docs/constitution-v1.0.0/`
**Pré-requisitos**: plan.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**TDD**: Ativado. Testes são escritos ANTES da implementação. Todo task de feature inclui
o passo de escrever o teste que FALHA primeiro.

**Organização**: Tarefas agrupadas por fase e história de usuário para permitir
implementação e validação independentes de cada incremento.

---

## Formato: `[ID] [P?] [US?] Descrição — caminho/do/arquivo`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependências)
- **[US]**: História de usuário associada (US1, US2, …)
- Caminhos de arquivo são relativos à raiz do repositório (`paguei/`)

---

## Fase 1 — Fundação (Semanas 1–3)

**Propósito**: Infraestrutura técnica que bloqueia todas as fases seguintes.
Nenhuma tarefa de feature pode começar até esta fase ser concluída.

**⚠ CRÍTICO**: Sem esta fase 100% completa, nenhuma história de usuário avança.

- [x] T001 Criar projeto Flutter com flavors `development`, `staging`, `production` — `lib/main.dart`, `lib/main_development.dart`, `lib/main_staging.dart`
- [x] T002 [P] Criar estrutura de pastas Clean Architecture conforme plano — `lib/core/`, `lib/domain/`, `lib/application/`, `lib/data/`, `lib/presentation/`
- [x] T003 [P] Configurar `pubspec.yaml` com todos os pacotes aprovados (Riverpod, Drift, go_router, flutter_animate, lottie, fl_chart, etc.) — `pubspec.yaml`
- [x] T004 [P] Configurar `analysis_options.yaml` com `flutter_lints` + regras de camadas (importações cruzadas proibidas) — `analysis_options.yaml`
- [x] T005 [P] Configurar formatação Dart + `dart format` no pre-commit hook — `.git/hooks/pre-commit`
- [x] T006 Configurar CI mínimo: `flutter analyze` + `flutter test` + cobertura — `.github/workflows/ci.yml`
- [x] T007 [P] Configurar `flutter_riverpod` + `ProviderScope` no `main.dart` + teste de provider raiz — `lib/core/di/providers.dart`, `test/core/di/providers_test.dart`
- [x] T008 Configurar `go_router` com shell route + bottom navigation (5 abas: Dashboard, Boletos, Transações, Resumo, Ajustes) — `lib/presentation/router/app_router.dart`, `lib/presentation/app.dart`
- [x] T009 [P] Escrever testes de navegação para todas as rotas registradas — `test/presentation/router/app_router_test.dart`
- [x] T010 Criar hierarquia de erros/falhas do domínio (`sealed class Failure`) — `lib/core/errors/failures.dart`, `lib/core/errors/exceptions.dart`
- [x] T011 [P] Escrever testes unitários para todas as subclasses de `Failure` — `test/core/errors/failures_test.dart`
- [x] T012 Criar abstração de logging (`AppLogger`) com níveis e sem dados sensíveis — `lib/core/logging/app_logger.dart`
- [x] T013 [P] Criar `CurrencyFormatter` com formatação pt-BR obrigatória (`R$ 1.234,56`) + testes — `lib/core/utils/currency_formatter.dart`, `test/core/utils/currency_formatter_test.dart`
- [x] T014 [P] Criar `DateFormatter` com formatação pt-BR (`dd/MM/yyyy`) + testes — `lib/core/utils/date_formatter.dart`, `test/core/utils/date_formatter_test.dart`
- [x] T015 Configurar `AppTheme` com tema claro e escuro (tokens de cor, tipografia, espaçamento) — `lib/presentation/theme/app_theme.dart`, `lib/presentation/theme/app_colors.dart`, `lib/presentation/theme/app_typography.dart`, `lib/presentation/theme/app_spacing.dart`
- [ ] T016 [P] Escrever testes golden do tema claro e escuro para garantir consistência visual — `test/golden/theme_goldens_test.dart`
- [x] T017 Configurar Drift: definir `AppDatabase` com `LazyDatabase` + `sqlite3_flutter_libs` — `lib/data/database/app_database.dart`
- [x] T018 [P] Criar estratégia de migrações Drift (`MigrationStrategy`) com versão v1 + testes de migração em banco de dados em memória — `lib/data/database/migrations/migration_v1.dart`, `test/data/database/migrations/migration_v1_test.dart`
- [x] T019 Configurar harness de testes: fábrica de mocks (`mocktail`), helpers de banco em memória Drift, provider overrides para testes — `test/helpers/test_helpers.dart`, `test/helpers/mock_factories.dart`, `test/helpers/drift_test_helpers.dart`
- [x] T020 Escrever `docs/architecture.md` inicial + ADRs 001–004 — `docs/architecture.md`, `docs/adr/001-riverpod-over-bloc.md`, `docs/adr/002-drift-over-isar.md`, `docs/adr/003-offline-first-architecture.md`, `docs/adr/004-syncfusion-community-license.md`

**Checkpoint**: Fundação pronta. `flutter analyze` limpo. `flutter test` passando. Estrutura de pastas criada. Banco de dados em memória funcional. Navegação testada. Pronto para Fase 2.

---

## Fase 2 — Finanças Core (Semanas 4–8)

**Propósito**: CRUD completo das entidades financeiras centrais; dashboard funcional.
**Dependência**: Fase 1 100% completa.

---

### Fase 2.1 — História US1: Gerenciamento de Contas (P1) 🎯 MVP Mínimo

**Objetivo**: Usuário pode criar, visualizar, editar e excluir contas/carteiras financeiras.
**Teste Independente**: Criar conta "Nubank" com saldo inicial R$ 1.000,00 e visualizá-la no app.

- [X] T021 [P] [US1] Escrever testes unitários para entidade `Account` (validações, invariantes) — `test/domain/entities/account_test.dart`
- [X] T022 [P] [US1] Escrever testes unitários para value object `Money` (aritmética, formatação pt-BR, invariante > 0) — `test/domain/value_objects/money_test.dart`
- [X] T023 [US1] Criar entidade `Account` + value object `Money` (imutáveis via Freezed) — `lib/domain/entities/account.dart`, `lib/domain/value_objects/money.dart`
- [X] T024 [US1] Criar interface `AccountRepository` no domínio — `lib/domain/repositories/account_repository.dart`
- [X] T025 [P] [US1] Escrever testes para `CreateAccountUseCase` e `GetAccountsUseCase` com mock do repositório — `test/application/accounts/create_account_use_case_test.dart`, `test/application/accounts/get_accounts_use_case_test.dart`
- [X] T026 [US1] Implementar `CreateAccountUseCase` e `GetAccountsUseCase` — `lib/application/accounts/create_account_use_case.dart`, `lib/application/accounts/get_accounts_use_case.dart`
- [X] T027 [P] [US1] Escrever testes para `UpdateAccountUseCase` e `DeactivateAccountUseCase` — `test/application/accounts/update_account_use_case_test.dart`, `test/application/accounts/deactivate_account_use_case_test.dart`
- [X] T028 [US1] Implementar `UpdateAccountUseCase` e `DeactivateAccountUseCase` — `lib/application/accounts/update_account_use_case.dart`, `lib/application/accounts/deactivate_account_use_case.dart`
- [X] T029 [US1] Criar tabela Drift `AccountsTable` + DAO `AccountsDao` com CRUD + Stream reativo — `lib/data/database/tables/accounts_table.dart`, `lib/data/database/daos/accounts_dao.dart`
- [X] T030 [P] [US1] Escrever testes de integração para `AccountsDao` usando banco Drift em memória — `test/data/database/daos/accounts_dao_test.dart`
- [X] T031 [US1] Implementar `AccountRepositoryImpl` + `AccountModel` (DTO) — `lib/data/repositories/account_repository_impl.dart`, `lib/data/models/account_model.dart`
- [X] T032 [P] [US1] Escrever testes do repositório com mock do DAO — `test/data/repositories/account_repository_impl_test.dart`
- [X] T033 [US1] Criar provider Riverpod `accountsProvider` + `accountNotifier` (estado imutável Freezed) — `lib/presentation/accounts/providers/accounts_provider.dart`
- [X] T034 [US1] Criar `AccountListScreen` + `AccountCard` widget — `lib/presentation/accounts/account_list_screen.dart`, `lib/presentation/accounts/widgets/account_card.dart`
- [X] T035 [US1] Criar `AccountFormScreen` (criar + editar) com validação + `ConfirmationDialog` na exclusão — `lib/presentation/accounts/account_form_screen.dart`
- [X] T036 [P] [US1] Escrever testes de widget para `AccountCard` + `AccountListScreen` — `test/presentation/accounts/account_card_test.dart`, `test/presentation/accounts/account_list_screen_test.dart`
- [X] T037 [US1] Criar widget `MoneyText` com formatação pt-BR + animação de update — `lib/presentation/shared/widgets/money_text.dart`, `test/presentation/shared/widgets/money_text_test.dart`

**Checkpoint**: Contas funcionais. Criar/editar/desativar conta. Saldo exibido em R$.

---

### Fase 2.2 — História US2: Categorias (P1)

**Objetivo**: Sistema de categorias padrão + customizáveis para classificar transações e boletos.
**Teste Independente**: Categorias padrão (Alimentação, Transporte, etc.) disponíveis ao abrir o app.

- [X] T038 [P] [US2] Escrever testes unitários para entidade `Category` — `test/domain/entities/category_test.dart`
- [X] T039 [US2] Criar entidade `Category` + interface `CategoryRepository` — `lib/domain/entities/category.dart`, `lib/domain/repositories/category_repository.dart`
- [X] T040 [P] [US2] Escrever testes para `SeedDefaultCategoriesUseCase` e `GetCategoriesUseCase` — `test/application/categories/seed_default_categories_use_case_test.dart`, `test/application/categories/get_categories_use_case_test.dart`
- [X] T041 [US2] Implementar `SeedDefaultCategoriesUseCase` (14 categorias padrão) + `GetCategoriesUseCase` — `lib/application/categories/seed_default_categories_use_case.dart`, `lib/application/categories/get_categories_use_case.dart`
- [X] T042 [US2] Criar tabela `CategoriesTable` + `CategoriesDao` + seeder no `AppDatabase.beforeOpen` — `lib/data/database/tables/categories_table.dart`, `lib/data/database/daos/categories_dao.dart`
- [X] T043 [P] [US2] Testes de DAO de categorias com banco em memória — `test/data/database/daos/categories_dao_test.dart`
- [X] T044 [US2] Implementar `CategoryRepositoryImpl` + provider Riverpod `categoriesProvider` — `lib/data/repositories/category_repository_impl.dart`, `lib/presentation/categories/providers/categories_provider.dart`
- [X] T045 [US2] Criar widget `CategoryPickerSheet` (bottom sheet de seleção de categoria) — `lib/presentation/shared/widgets/category_picker_sheet.dart`, `test/presentation/shared/widgets/category_picker_sheet_test.dart`

**Checkpoint**: 14 categorias padrão disponíveis; picker funcional para uso em outros módulos.

---

### Fase 2.3 — História US3: Transações (P1)

**Objetivo**: CRUD de receitas, despesas e transferências com classificação por categoria.
**Teste Independente**: Registrar despesa de R$ 50,00 em "Alimentação" e ver no extrato do mês.

- [X] T046 [P] [US3] Escrever testes unitários para entidade `Transaction` (todos os tipos: income, expense, transfer) — `test/domain/entities/transaction_test.dart`
- [X] T047 [US3] Criar entidade `Transaction` + interface `TransactionRepository` — `lib/domain/entities/transaction.dart`, `lib/domain/repositories/transaction_repository.dart`
- [X] T048 [P] [US3] Escrever testes para `CreateTransactionUseCase`, `GetMonthlyTransactionsUseCase`, `DeleteTransactionUseCase` — `test/application/transactions/`
- [X] T049 [US3] Implementar os três use cases de transação — `lib/application/transactions/create_transaction_use_case.dart`, `lib/application/transactions/get_monthly_transactions_use_case.dart`, `lib/application/transactions/delete_transaction_use_case.dart`
- [X] T050 [US3] Criar tabela `TransactionsTable` + `TransactionsDao` (com índices em `date`, `accountId`, `categoryId`) — `lib/data/database/tables/transactions_table.dart`, `lib/data/database/daos/transactions_dao.dart`
- [X] T051 [P] [US3] Testes de DAO de transações incluindo queries de agregação mensal — `test/data/database/daos/transactions_dao_test.dart`
- [X] T052 [US3] Implementar `TransactionRepositoryImpl` + `TransactionModel` — `lib/data/repositories/transaction_repository_impl.dart`, `lib/data/models/transaction_model.dart`
- [X] T053 [US3] Criar provider Riverpod `transactionsProvider` (stream reativo do mês) — `lib/presentation/transactions/providers/transactions_provider.dart`
- [X] T054 [US3] Criar `TransactionListScreen` com filtros de mês e tipo — `lib/presentation/transactions/transaction_list_screen.dart`
- [X] T055 [US3] Criar `TransactionFormScreen` (receita/despesa) com seletor de conta, categoria e data — `lib/presentation/transactions/transaction_form_screen.dart`
- [X] T056 [US3] Criar `TransferFormScreen` (transferência entre contas) — `lib/presentation/transactions/transfer_form_screen.dart`
- [X] T057 [P] [US3] Testes de widget para `TransactionListScreen` e `TransactionFormScreen` — `test/presentation/transactions/`

**Checkpoint**: Extrato mensal completo. Receitas, despesas e transferências funcionais.

---

### Fase 2.4 — História US4: Boletos Manuais (P1)

**Objetivo**: CRUD manual de boletos a pagar com status visual claro.
**Teste Independente**: Criar boleto "Energia" R$ 120,00 vencendo amanhã; marcar como pago com confirmação.

- [X] T058 [P] [US4] Escrever testes unitários para entidade `Bill` + value objects `Barcode` e `PixCode` — `test/domain/entities/bill_test.dart`, `test/domain/value_objects/barcode_test.dart`, `test/domain/value_objects/pix_code_test.dart`
- [X] T059 [US4] Criar entidade `Bill` + value objects `Barcode` (validação módulo 10/11) + `PixCode` + interface `BillRepository` — `lib/domain/entities/bill.dart`, `lib/domain/value_objects/barcode.dart`, `lib/domain/value_objects/pix_code.dart`, `lib/domain/repositories/bill_repository.dart`
- [X] T060 [P] [US4] Escrever testes para `CreateBillUseCase`, `MarkBillAsPaidUseCase`, `DeleteBillUseCase`, `GetBillsByStatusUseCase` — `test/application/bills/`
- [X] T061 [US4] Implementar os quatro use cases de boleto — `lib/application/bills/create_bill_use_case.dart`, `lib/application/bills/mark_bill_as_paid_use_case.dart`, `lib/application/bills/delete_bill_use_case.dart`, `lib/application/bills/get_bills_by_status_use_case.dart`
- [X] T062 [US4] Criar tabela `BillsTable` + `BillsDao` (índice em `dueDate`, `status`) — `lib/data/database/tables/bills_table.dart`, `lib/data/database/daos/bills_dao.dart`
- [X] T063 [P] [US4] Testes de DAO de boletos incluindo query de vencidos (dueDate < hoje) — `test/data/database/daos/bills_dao_test.dart`
- [X] T064 [US4] Implementar `BillRepositoryImpl` + `BillModel` — `lib/data/repositories/bill_repository_impl.dart`, `lib/data/models/bill_model.dart`
- [X] T065 [US4] Criar provider Riverpod `billsProvider` com streams separados por status — `lib/presentation/bills/providers/bills_provider.dart`
- [X] T066 [US4] Criar `BillListScreen` com abas Pendentes/Vencidos/Pagos + filtros — `lib/presentation/bills/bill_list_screen.dart`
- [X] T067 [US4] Criar `BillFormScreen` (entrada manual de boleto) — `lib/presentation/bills/bill_form_screen.dart`
- [X] T068 [US4] Criar `BillCard` widget com `BillStatusChip` colorido por status + swipe para ações — `lib/presentation/bills/widgets/bill_card.dart`, `lib/presentation/bills/widgets/bill_status_chip.dart`
- [X] T069 [US4] Implementar ação "Marcar como Pago" com `ConfirmationDialog` + criação automática de `Transaction` — `lib/presentation/bills/bill_list_screen.dart`
- [X] T070 [P] [US4] Testes de widget para `BillCard`, `BillListScreen`, `BillStatusChip` — `test/presentation/bills/`

**Checkpoint**: Boletos criados manualmente. Status visual por cor. Marcar como pago gera transação. "Paguei?" respondível.

---

### Fase 2.5 — História US5: Dashboard (P1)

**Objetivo**: Tela inicial que responde "Paguei?" instantaneamente com saldo, pago/pendente e próximos vencimentos.
**Teste Independente**: Dashboard exibe saldo total correto, total pago e pendente do mês, e lista de boletos nos próximos 7 dias.

- [X] T071 [P] [US5] Escrever testes unitários para `GetDashboardSummaryUseCase` (mocks de todos repositórios) — `test/application/dashboard/get_dashboard_summary_use_case_test.dart`
- [X] T072 [US5] Implementar `GetDashboardSummaryUseCase` (agrega saldo total, pago, pendente, vencidos, próximos 7 dias) — `lib/application/dashboard/get_dashboard_summary_use_case.dart`
- [X] T073 [US5] Criar provider Riverpod `dashboardProvider` com estado `DashboardState` sealed (Loading/Loaded/Error) — `lib/presentation/dashboard/providers/dashboard_provider.dart`
- [X] T074 [US5] Criar `DashboardScreen` com `BalanceCard` (saldo 32sp Bold), `BillsSummaryCard` (pago/pendente), lista de próximos vencimentos — `lib/presentation/dashboard/dashboard_screen.dart`
- [X] T075 [US5] Criar widgets `BalanceCard`, `BillsSummaryCard`, `UpcomingBillsSection` com `LoadingSkeleton` durante carga — `lib/presentation/dashboard/widgets/balance_card.dart`, `lib/presentation/dashboard/widgets/bills_summary_card.dart`, `lib/presentation/dashboard/widgets/upcoming_bills_section.dart`
- [X] T076 [P] [US5] Testes de widget para `DashboardScreen` nos estados Loading, Loaded e Error — `test/presentation/dashboard/dashboard_screen_test.dart`
- [X] T077 [P] [US5] Testes golden do `DashboardScreen` (tema claro e escuro) — `test/golden/dashboard_goldens_test.dart`

**Checkpoint**: Dashboard responde "Paguei?" em < 2s. Nenhum estado ambíguo. Saldo sempre visível ou skeleton.

---

### Fase 2.6 — História US6: Fundos e Reservas (P2)

**Objetivo**: Controle de reserva de emergência e metas de poupança com barra de progresso.
**Teste Independente**: Criar "Reserva de Emergência" meta R$ 10.000,00 e adicionar R$ 500,00 — barra de progresso atualiza.

- [X] T078 [P] [US6] Escrever testes unitários para entidade `Fund` — `test/domain/entities/fund_test.dart`
- [X] T079 [US6] Criar entidade `Fund` + interface `FundRepository` + use cases CRUD — `lib/domain/entities/fund.dart`, `lib/domain/repositories/fund_repository.dart`, `lib/application/funds/`
- [X] T080 [US6] Criar tabela `FundsTable` + `FundsDao` + `FundRepositoryImpl` — `lib/data/database/tables/funds_table.dart`, `lib/data/database/daos/funds_dao.dart`, `lib/data/repositories/fund_repository_impl.dart`
- [X] T081 [P] [US6] Testes de DAO e repositório de fundos — `test/data/database/daos/funds_dao_test.dart`, `test/data/repositories/fund_repository_impl_test.dart`
- [X] T082 [US6] Criar `FundListScreen` + `FundCard` com barra de progresso circular + `FundFormScreen` — `lib/presentation/funds/fund_list_screen.dart`, `lib/presentation/funds/fund_form_screen.dart`, `lib/presentation/funds/widgets/fund_card.dart`
- [X] T083 [P] [US6] Testes de widget para fundos — `test/presentation/funds/`

---

### Fase 2.7 — História US7: Dívidas e Parcelas (P2)

**Objetivo**: Rastrear dívidas por credor com progresso de quitação e projeção de data de término.
**Teste Independente**: Criar dívida "Cartão Visa" 12x R$ 200,00 — progress bar e data de quitação exibidos.

- [X] T084 [P] [US7] Escrever testes unitários para entidade `Debt` (cálculo de saldo devedor, progresso) — `test/domain/entities/debt_test.dart`
- [X] T085 [US7] Criar entidade `Debt` + interface `DebtRepository` + use cases CRUD + `RegisterDebtPaymentUseCase` — `lib/domain/entities/debt.dart`, `lib/domain/repositories/debt_repository.dart`, `lib/application/debts/`
- [X] T086 [US7] Criar tabela `DebtsTable` + `DebtsDao` + `DebtRepositoryImpl` — `lib/data/database/tables/debts_table.dart`, `lib/data/database/daos/debts_dao.dart`, `lib/data/repositories/debt_repository_impl.dart`
- [X] T087 [P] [US7] Testes de DAO e repositório de dívidas — `test/data/database/daos/debts_dao_test.dart`
- [x] T088 [US7] Criar `DebtListScreen` + `DebtCard` (progresso + parcelas restantes) + `DebtFormScreen` — `lib/presentation/debts/debt_list_screen.dart`, `lib/presentation/debts/debt_form_screen.dart`, `lib/presentation/debts/widgets/debt_card.dart`
- [ ] T089 [P] [US7] Testes de widget para dívidas — `test/presentation/debts/`

---

### Fase 2.8 — História US8: Assinaturas Recorrentes (P2)

**Objetivo**: Rastrear assinaturas (Netflix, Spotify) com próxima cobrança e alerta.
**Teste Independente**: Criar assinatura "Netflix" R$ 45,90/mês — próxima data de cobrança exibida.

- [ ] T090 [P] [US8] Escrever testes unitários para entidade `Subscription` — `test/domain/entities/subscription_test.dart`
- [ ] T091 [US8] Criar entidade `Subscription` + interface `SubscriptionRepository` + use cases CRUD + `GenerateBillFromSubscriptionUseCase` — `lib/domain/entities/subscription.dart`, `lib/domain/repositories/subscription_repository.dart`, `lib/application/subscriptions/`
- [ ] T092 [US8] Criar tabela `SubscriptionsTable` + `SubscriptionsDao` + `SubscriptionRepositoryImpl` — `lib/data/database/tables/subscriptions_table.dart`, `lib/data/database/daos/subscriptions_dao.dart`, `lib/data/repositories/subscription_repository_impl.dart`
- [ ] T093 [P] [US8] Testes de DAO e repositório de assinaturas — `test/data/database/daos/subscriptions_dao_test.dart`
- [ ] T094 [US8] Criar `SubscriptionListScreen` + `SubscriptionCard` + `SubscriptionFormScreen` — `lib/presentation/subscriptions/subscription_list_screen.dart`, `lib/presentation/subscriptions/subscription_form_screen.dart`, `lib/presentation/subscriptions/widgets/subscription_card.dart`
- [ ] T095 [P] [US8] Testes de widget para assinaturas — `test/presentation/subscriptions/`

---

### Fase 2.9 — História US9: Resumo Financeiro / Net Worth (P2)

**Objetivo**: Tela consolidada com patrimônio líquido, total de ativos, dívidas e obrigações mensais.
**Teste Independente**: Tela exibe networth = ativos - dívidas com breakdown por conta/dívida.

- [ ] T096 [P] [US9] Escrever testes para `GetFinancialSummaryUseCase` — `test/application/summary/get_financial_summary_use_case_test.dart`
- [ ] T097 [US9] Implementar `GetFinancialSummaryUseCase` (agrega accounts + debts + funds + monthly obligations) — `lib/application/summary/get_financial_summary_use_case.dart`
- [ ] T098 [US9] Criar `FinancialSummaryScreen` com `NetWorthCard`, listas de contas/dívidas/fundos — `lib/presentation/summary/financial_summary_screen.dart`, `lib/presentation/summary/widgets/`
- [ ] T099 [P] [US9] Testes de widget para `FinancialSummaryScreen` — `test/presentation/summary/`

---

### Fase 2.10 — História US10: Exportação CSV (P3)

**Objetivo**: Exportar transações do período para CSV compatível com Excel pt-BR.
**Teste Independente**: Exportar janeiro/2026 → arquivo CSV com separador `;`, datas `DD/MM/YYYY`, valores `1.234,56`.

- [ ] T100 [P] [US10] Escrever testes unitários para `ExportTransactionsCsvUseCase` (formato, encoding UTF-8 BOM) — `test/application/export/export_transactions_csv_use_case_test.dart`
- [ ] T101 [US10] Implementar `ExportTransactionsCsvUseCase` (executar em `compute()` para não bloquear main thread) — `lib/application/export/export_transactions_csv_use_case.dart`
- [ ] T102 [US10] Criar botão de exportação CSV na `TransactionListScreen` com seletor de período — `lib/presentation/transactions/transaction_list_screen.dart`

---

## Fase 3 — Leitor de Boletos / OCR (Semanas 9–12)

**Propósito**: Módulo completo de leitura de boletos via câmera, galeria, PDF e TXT.
**Dependência**: Fase 2.4 (entidade `Bill` e repositório) 100% completa.

---

### Fase 3.1 — História US11: Permissões e Scanner de Câmera (P1)

**Objetivo**: Usuário concede permissão de câmera e escaneia barcode/QR de boleto diretamente.
**Teste Independente**: App solicita permissão de câmera com explicação; ao negar, oferece fallback de upload.

- [X] T103 Configurar `permission_handler` + solicitação de permissão de câmera com UX de onboarding (explicação antes de pedir) — `lib/data/datasources/permissions/camera_permission_datasource.dart`, `lib/presentation/scanner/widgets/camera_permission_explainer.dart`
- [X] T104 [P] [US11] Escrever testes para `CameraPermissionDatasource` (mock de `permission_handler`) — `test/data/datasources/permissions/camera_permission_datasource_test.dart`
- [X] T105 [US11] Criar `BarcodeScannerDatasource` usando `mobile_scanner` (suporte ITF, Code 128, QR Code) — `lib/data/datasources/scanner/barcode_scanner_datasource.dart`
- [X] T106 [P] [US11] Escrever testes unitários para `ScanBarcodeUseCase` — `test/application/scanner/scan_barcode_use_case_test.dart`
- [X] T107 [US11] Implementar `ScanBarcodeUseCase` com validação de módulo 10/11 para linha digitável de boleto — `lib/application/scanner/scan_barcode_use_case.dart`
- [X] T108 [US11] Criar `BillScanScreen` com viewfinder de câmera ao vivo + detecção de barcode em tempo real — `lib/presentation/scanner/bill_scan_screen.dart`
- [X] T109 [P] [US11] Testes de widget para `BillScanScreen` nos estados Idle, Scanning, Error (permissão negada) — `test/presentation/scanner/bill_scan_screen_test.dart`

**Checkpoint**: Scanner de câmera funcional. Barcode e QR detectados. Fallback quando permissão negada.

---

### Fase 3.2 — História US12: OCR de Imagem e PDF (P1)

**Objetivo**: Extrair dados de boleto a partir de imagem da galeria ou arquivo PDF.
**Teste Independente**: Upload de imagem de boleto → campos pré-preenchidos (valor, vencimento, beneficiário) com >75% de precisão.

- [X] T110 [P] [US12] Escrever testes unitários para heurísticas de extração de boleto (regex para linha digitável, data, valor) — `test/application/scanner/bill_extraction_heuristics_test.dart`
- [X] T111 [US12] Implementar `BillExtractionHeuristics` (regex e parsing de texto bruto para campos de boleto pt-BR) — `lib/application/scanner/bill_extraction_heuristics.dart`
- [X] T112 [US12] Criar `OcrDatasource` usando `google_mlkit_text_recognition` para processar imagens — `lib/data/datasources/scanner/ocr_datasource.dart`
- [ ] T113 [P] [US12] Escrever testes para `ExtractBillFromImageUseCase` — `test/application/scanner/extract_bill_from_image_use_case_test.dart`
- [ ] T114 [US12] Implementar `ExtractBillFromImageUseCase` (OCR → heurísticas → `BillScanResult` com `confidence`) — `lib/application/scanner/extract_bill_from_image_use_case.dart`
- [ ] T115 [US12] Criar `PdfExtractorDatasource` usando `syncfusion_flutter_pdf` para extração de texto de PDF — `lib/data/datasources/scanner/pdf_extractor_datasource.dart`
- [ ] T116 [P] [US12] Escrever testes para `ExtractBillFromPdfUseCase` — `test/application/scanner/extract_bill_from_pdf_use_case_test.dart`
- [ ] T117 [US12] Implementar `ExtractBillFromPdfUseCase` (PDF → texto → heurísticas → `BillScanResult`) — `lib/application/scanner/extract_bill_from_pdf_use_case.dart`
- [ ] T118 [US12] Implementar parser de TXT (`ExtractBillFromTxtUseCase`) — `lib/application/scanner/extract_bill_from_txt_use_case.dart`, `test/application/scanner/extract_bill_from_txt_use_case_test.dart`
- [ ] T119 [US12] Configurar `file_picker` para upload de PDF/TXT/imagem da galeria — `lib/data/datasources/scanner/file_picker_datasource.dart`

---

### Fase 3.3 — História US13: Tela de Revisão e Ações do Boleto (P1)

**Objetivo**: Após scan/OCR, usuário revisa, corrige e executa ações (copiar, abrir banco, salvar, criar lembrete).
**Teste Independente**: Resultado de scan com `confidence < 0.85` abre formulário de revisão com campos pré-preenchidos editáveis.

- [ ] T120 [US13] Criar `BillReviewScreen` (formulário pré-preenchido editável; `confidence < 0.85` → revisão obrigatória) — `lib/presentation/scanner/bill_review_screen.dart`
- [ ] T121 [P] [US13] Testes de widget para `BillReviewScreen` (estados: alta confiança, baixa confiança, sem dados) — `test/presentation/scanner/bill_review_screen_test.dart`
- [ ] T122 [US13] Implementar `CopyBarcodeUseCase` (copiar linha digitável/PIX para clipboard + toast "Código copiado") — `lib/application/bills/copy_barcode_use_case.dart`, `test/application/bills/copy_barcode_use_case_test.dart`
- [ ] T123 [US13] Implementar `OpenInBankAppUseCase` (intent/share com código do boleto via `url_launcher` + `share_plus`) — `lib/application/bills/open_in_bank_app_use_case.dart`
- [ ] T124 [US13] Integrar ações no `BillReviewScreen`: copiar código, compartilhar, salvar boleto, criar lembrete rápido — `lib/presentation/scanner/bill_review_screen.dart`
- [ ] T125 [P] [US13] Escrever teste de integração completo do fluxo de scan: câmera → detecção → revisão → salvar — `integration_test/bill_scan_flow_test.dart`

---

## Fase 4 — Alertas e Automação (Semanas 13–15)

**Propósito**: Sistema de notificações que garante que o usuário nunca perca um vencimento.
**Dependência**: Fase 2.4 (Boletos) e Fase 2.8 (Assinaturas) completas.

---

### Fase 4.1 — História US14: Notificações Locais (P1)

**Objetivo**: App agenda notificações automáticas ao salvar boletos; usuário nunca é surpreendido por vencimento.
**Teste Independente**: Salvar boleto vencendo em 3 dias → notificação agendada para hoje às 20:00 e no dia do vencimento às 09:00.

- [ ] T126 Criar entidade de domínio `NotificationRule` + interface `NotificationRepository` — `lib/domain/entities/notification_rule.dart`, `lib/domain/repositories/notification_repository.dart`
- [ ] T127 [P] [US14] Escrever testes para `ScheduleBillRemindersUseCase` e `CancelBillRemindersUseCase` — `test/application/notifications/schedule_bill_reminders_use_case_test.dart`
- [ ] T128 [US14] Implementar `ScheduleBillRemindersUseCase` (agenda notificações: N dias antes às 20:00, no dia às 09:00, vencido às 08:00 do dia seguinte) — `lib/application/notifications/schedule_bill_reminders_use_case.dart`
- [ ] T129 [US14] Implementar `CancelBillRemindersUseCase` (cancela ao marcar como pago) — `lib/application/notifications/cancel_bill_reminders_use_case.dart`
- [ ] T130 [US14] Criar `NotificationDatasource` usando `flutter_local_notifications` + `timezone` — `lib/data/datasources/notifications/notification_datasource.dart`
- [ ] T131 [P] [US14] Testes do `NotificationDatasource` com mock de `flutter_local_notifications` — `test/data/datasources/notifications/notification_datasource_test.dart`
- [ ] T132 [US14] Criar tabela `NotificationLogsTable` + `NotificationLogsDao` (audit trail de notificações) — `lib/data/database/tables/notification_logs_table.dart`, `lib/data/database/daos/notification_logs_dao.dart`
- [ ] T133 [US14] Integrar `ScheduleBillRemindersUseCase` no `CreateBillUseCase` e `MarkBillAsPaidUseCase` — `lib/application/bills/create_bill_use_case.dart`, `lib/application/bills/mark_bill_as_paid_use_case.dart`
- [ ] T134 [US14] Configurar deep links de notificação → rota `/bills/{id}` via go_router — `lib/presentation/router/app_router.dart`

---

### Fase 4.2 — História US15: Limites de Orçamento (P2)

**Objetivo**: Usuário define limite mensal por categoria e recebe alerta ao atingir 80%.
**Teste Independente**: Criar limite "Alimentação" R$ 500,00 → adicionar R$ 400,00 em transações → notificação de 80% disparada.

- [ ] T135 [P] [US15] Escrever testes para entidade `BudgetLimit` + `CheckBudgetExceededUseCase` — `test/domain/entities/budget_limit_test.dart`, `test/application/budgets/check_budget_exceeded_use_case_test.dart`
- [ ] T136 [US15] Criar entidade `BudgetLimit` + interface `BudgetRepository` + use cases CRUD + `CheckBudgetExceededUseCase` — `lib/domain/entities/budget_limit.dart`, `lib/domain/repositories/budget_repository.dart`, `lib/application/budgets/`
- [ ] T137 [US15] Criar tabela `BudgetLimitsTable` + `BudgetLimitsDao` + `BudgetRepositoryImpl` — `lib/data/database/tables/budget_limits_table.dart`, `lib/data/database/daos/budget_limits_dao.dart`, `lib/data/repositories/budget_repository_impl.dart`
- [ ] T138 [US15] Integrar `CheckBudgetExceededUseCase` no `CreateTransactionUseCase` (dispara alerta ao ultrapassar threshold) — `lib/application/transactions/create_transaction_use_case.dart`
- [ ] T139 [US15] Criar `BudgetScreen` com lista de limites por categoria + barras de progresso — `lib/presentation/budgets/budget_screen.dart`, `lib/presentation/budgets/widgets/budget_progress_card.dart`
- [ ] T140 [P] [US15] Testes de widget para `BudgetScreen` — `test/presentation/budgets/`

---

### Fase 4.3 — História US16: Automação de Boletos Recorrentes (P2)

**Objetivo**: Boletos recorrentes são gerados automaticamente na data certa (aluguel, plano de saúde).
**Teste Independente**: Criar boleto recorrente mensal → próximo mês gerado automaticamente ao abrir o app.

- [ ] T141 [P] [US16] Escrever testes para `GenerateRecurringBillsUseCase` (lógica de recorrência mensal/semanal/anual) — `test/application/bills/generate_recurring_bills_use_case_test.dart`
- [ ] T142 [US16] Implementar `GenerateRecurringBillsUseCase` (parseia `recurrenceRule` JSON + gera próximo boleto) — `lib/application/bills/generate_recurring_bills_use_case.dart`
- [ ] T143 [US16] Invocar `GenerateRecurringBillsUseCase` no startup do app (após banco inicializado) — `lib/core/startup/app_startup.dart`

---

### Fase 4.4 — História US17: Alertas por E-mail (P3)

**Objetivo**: Usuário pode configurar alertas de boleto vencido por e-mail via Formspree/Resend.
**Teste Independente**: Configurar e-mail → boleto vencido → e-mail recebido (verificado via log/API).

- [ ] T144 [P] [US17] Escrever testes para `EmailAlertDatasource` com mock de cliente HTTP — `test/data/datasources/remote/email_alert_datasource_test.dart`
- [ ] T145 [US17] Criar `EmailAlertDatasource` com adapter para Formspree (HTTP POST isolado na camada `data/`) — `lib/data/datasources/remote/email_alert_datasource.dart`
- [ ] T146 [US17] Criar tela de configuração de e-mail de alertas em `SettingsScreen` — `lib/presentation/settings/settings_screen.dart`

---

## Fase 5 — UX Premium (Semanas 16–19)

**Propósito**: App que parece e responde como um produto fintech de alto nível.
**Dependência**: Fases 2 e 3 completas; design tokens finalizados.

- [ ] T147 [P] Definir e documentar design system completo (tokens finais, guia de componentes, exemplos) — `docs/design-system.md`
- [ ] T148 [P] Implementar sistema de animações com `flutter_animate`: transições de rota, slide-in de cards, fade de saldo — `lib/presentation/theme/app_animations.dart`
- [ ] T149 [P] Adicionar microinterações ao `MoneyText`: animação de contador ao mudar valor (roll-up/roll-down) — `lib/presentation/shared/widgets/money_text.dart`
- [ ] T150 Implementar shimmer `LoadingSkeleton` para dashboard e lista de boletos — `lib/presentation/shared/widgets/loading_skeleton.dart`, `test/presentation/shared/widgets/loading_skeleton_test.dart`
- [ ] T151 [P] Criar `EmptyState` widgets com ilustrações Lottie para: boletos vazios, sem transações, sem dívidas — `lib/presentation/shared/widgets/empty_state.dart`
- [ ] T152 Criar gráfico de gastos por categoria no Dashboard (`fl_chart` + `SpendingTrendChart`) — `lib/presentation/dashboard/widgets/spending_trend_chart.dart`, `test/presentation/dashboard/widgets/spending_trend_chart_test.dart`
- [ ] T153 [P] Criar gráfico de cashflow mensal (linha) na `FinancialSummaryScreen` — `lib/presentation/summary/widgets/cashflow_chart.dart`
- [ ] T154 Criar fluxo de onboarding (3 telas) com ilustrações geradas via nanobana2 e animações Lottie — `lib/presentation/onboarding/`, `assets/images/onboarding/`
- [ ] T155 [P] Gerar assets de onboarding via nanobana2 skill (3 ilustrações, paleta da marca) — `assets/images/onboarding/onboarding_step_1.png`, `onboarding_step_2.png`, `onboarding_step_3.png`
- [ ] T156 [P] Gerar ícones SVG de categorias padrão (14 ícones) via nanobana2 — `assets/images/categories/`
- [ ] T157 [P] Gerar animações Lottie: `success_payment.json`, `loading_coins.json`, `empty_bills.json` — `assets/animations/`
- [ ] T158 Implementar tela de bloqueio biométrico (`local_auth`) com fallback para PIN do dispositivo — `lib/presentation/security/biometric_lock_screen.dart`, `lib/application/security/authenticate_with_biometrics_use_case.dart`
- [ ] T159 [P] Escrever testes de widget para `BiometricLockScreen` — `test/presentation/security/biometric_lock_screen_test.dart`
- [ ] T160 Implementar layouts adaptativos para tablet (two-panel layout no Dashboard e Boletos) — `lib/presentation/shared/layouts/adaptive_layout.dart`
- [ ] T161 [P] Executar auditoria de acessibilidade: labels semânticos em todos os widgets, contraste de cores, tamanhos de toque mínimos (48dp) — revisar todos os widgets em `lib/presentation/`
- [ ] T162 [P] Escrever testes golden do Dashboard, BillList, BillCard em light/dark e tamanhos de fonte grande — `test/golden/`
- [ ] T163 Executar profiling de performance: DevTools no Moto G real, corrigir rebuilds desnecessários identificados — atualizar `docs/performance-report.md`

---

## Fase 6 — Funcionalidades de IA (Semanas 20–24)

**Propósito**: Camada de inteligência que diferencia o Paguei? da concorrência.
**Dependência**: Fases 2–5 completas e estáveis.

- [ ] T164 [P] Documentar workflow completo de geração de assets com IA (prompts master, convenções de naming, processo de revisão) — `docs/ai-asset-generation-workflow.md`
- [ ] T165 [P] Criar biblioteca de prompts para geração de assets (onboarding, ícones, banners, screenshots de loja) — `.specify/prompts/assets/`
- [ ] T166 [P] Escrever testes unitários para `SmartInsightsEngine` (motor baseado em regras) — `test/application/insights/smart_insights_engine_test.dart`
- [ ] T167 [US] Implementar `SmartInsightsEngine` (regras: maior gasto do mês, categoria acima da média, projeção de saldo 30 dias) — `lib/application/insights/smart_insights_engine.dart`
- [ ] T168 [US] Criar `InsightsSection` no Dashboard com os 3 principais insights do mês — `lib/presentation/dashboard/widgets/insights_section.dart`
- [ ] T169 [P] Implementar `PixCodeManager` (histórico de códigos PIX copiados, detecção automática por clipboard) — `lib/application/pix/pix_code_manager.dart`, `lib/presentation/pix/pix_manager_screen.dart`
- [ ] T170 [US] Criar arquitetura de hooks para assistente de IA futuro: interface `AiAssistantPort` no domínio, sem implementação concreta — `lib/domain/ports/ai_assistant_port.dart`
- [ ] T171 [P] Implementar busca avançada (por valor, data, beneficiário, código de barras) via query Drift — `lib/application/search/search_use_case.dart`, `lib/presentation/search/search_screen.dart`, `test/application/search/search_use_case_test.dart`

---

## Fase 7 — Pronto para Lançamento (Semanas 25–28)

**Propósito**: Qualidade de produção. Nada sai da loja sem estes gates.

- [ ] T172 Executar auditoria de segurança completa (skill `007`): OWASP Mobile Top 10, modelagem STRIDE, verificar `allowBackup=false`, verificar logs — `docs/security-audit.md`
- [ ] T173 [P] Configurar `flutter_secure_storage` para todos os dados sensíveis (tokens, chave de encryption do Drift) + verificar nenhum dado financeiro em logs — `lib/data/datasources/local/secure_storage_datasource.dart`
- [ ] T174 [P] Implementar `BackupDatasource`: exportar banco SQLite criptografado para arquivo local / `share_plus` — `lib/data/datasources/local/backup_datasource.dart`, `test/data/datasources/local/backup_datasource_test.dart`
- [ ] T175 [US] Implementar `RestoreFromBackupUseCase`: validar + restaurar banco de backup — `lib/application/backup/restore_from_backup_use_case.dart`
- [ ] T176 [US] Criar tela de Backup/Restauração em `SettingsScreen` — `lib/presentation/settings/backup_section.dart`
- [ ] T177 [P] Configurar Firebase Crashlytics (sem dados financeiros nos relatórios) — `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
- [ ] T178 [P] Configurar Firebase Analytics (eventos anônimos de uso: onboarding_completed, bill_scanned, payment_marked) — sem PII, sem dados financeiros — `lib/data/datasources/remote/analytics_datasource.dart`
- [ ] T179 [P] Criar ícone do app (1024x1024, dark/light variants) via nanobana2 + configurar `flutter_launcher_icons` — `assets/icons/app_icon.png`, `pubspec.yaml`
- [ ] T180 [P] Criar splash screen com logo animado (< 2s) via `flutter_native_splash` — `pubspec.yaml`, `assets/`
- [ ] T181 [P] Gerar screenshots da App Store (6.7", 5.5", iPad 12.9") para Google Play e App Store Connect via nanobana2 — `assets/store/`
- [ ] T182 [P] Criar `CHANGELOG.md` completo com todas as features das 7 fases + versão semântica `1.0.0` — `CHANGELOG.md`
- [ ] T183 Escrever checklist de beta: instalar em 3 dispositivos reais (Android mid-range, iPhone SE, tablet), testar 20 cenários críticos — `docs/beta-checklist.md`
- [ ] T184 Escrever checklist de release: `flutter analyze` limpo, cobertura gates passando, security audit aprovado, screenshots prontos, Syncfusion licença registrada, política de privacidade publicada — `docs/release-checklist.md`
- [ ] T185 Criar teste de integração end-to-end final: criar conta → adicionar transação → criar boleto → escanear → marcar como pago → verificar dashboard atualizado — `integration_test/app_test.dart`
- [ ] T186 [P] Escrever política de privacidade e termos de uso (pt-BR) — `docs/privacy-policy.md`, `docs/terms-of-use.md`
- [ ] T187 Executar build de produção Android + iOS e validar em TestFlight / Google Play Internal Testing — `docs/release-checklist.md`

---

## Dependências e Ordem de Execução

### Dependências por Fase

```
Fase 1 (Fundação)
  └─ Bloqueia: TUDO — nenhuma fase começa antes de T001–T020 concluídos

Fase 2.1 (Contas) → depende de: Fase 1
Fase 2.2 (Categorias) → depende de: Fase 1 [pode iniciar em paralelo com 2.1]
Fase 2.3 (Transações) → depende de: 2.1 (Account), 2.2 (Category)
Fase 2.4 (Boletos) → depende de: 2.1 (Account), 2.2 (Category)
Fase 2.5 (Dashboard) → depende de: 2.1, 2.3, 2.4
Fase 2.6 (Fundos) → depende de: Fase 1 [paralela a 2.3/2.4]
Fase 2.7 (Dívidas) → depende de: Fase 1 [paralela a 2.6]
Fase 2.8 (Assinaturas) → depende de: 2.4 (Bill)
Fase 2.9 (Net Worth) → depende de: 2.1, 2.6, 2.7
Fase 2.10 (CSV) → depende de: 2.3

Fase 3 (OCR) → depende de: 2.4 (Bill entity + repositório)
Fase 4 (Alertas) → depende de: 2.4 (Bills), 2.8 (Subscriptions)
Fase 5 (UX) → depende de: Fases 2 e 3 estáveis
Fase 6 (IA) → depende de: Fases 2–5 completas
Fase 7 (Launch) → depende de: Fase 6 completa
```

### Dependências dentro de cada história

Para cada história (US1–US20):
1. Testes de domínio PRIMEIRO (Red) → entidade + interfaces
2. Use cases (ainda Red) → implementação (Green)
3. DAO Drift → implementação de repositório
4. Providers Riverpod → telas de UI → testes de widget
5. Commit após cada grupo verde + refatorado

---

## Caminho Crítico

Estas tarefas desbloqueiam o máximo progresso e DEVEM ser priorizadas:

```
T001 → T002 → T003 → T004         # Bootstrap e configuração
T017 → T018 → T019                 # Drift + harness de testes
T007 → T008                        # Riverpod + Navegação
T023 → T029 → T031                 # Account entity → DAO → repository
T059 → T062 → T064                 # Bill entity → DAO → repository (desbloqueia OCR + Alertas)
T072 → T073 → T074                 # Dashboard use case → provider → tela
T107 → T114 → T120                 # Scanner → OCR → Tela de revisão
T128 → T130 → T133                 # Notifications use case → datasource → integração
```

---

## Workstreams Paralelos

Após a Fase 1 completa, os seguintes workstreams podem avançar em paralelo:

| Workstream A | Workstream B | Workstream C |
|---|---|---|
| US1 (Contas) | US2 (Categorias) | — |
| US3 (Transações) | US4 (Boletos) | US6 (Fundos) |
| US5 (Dashboard) | US7 (Dívidas) | US8 (Assinaturas) |
| US11 (Scanner câmera) | US12 (OCR) | — |
| US14 (Notificações) | US15 (Orçamentos) | US16 (Recorrência) |
| T147–T151 (Animações) | T152–T153 (Gráficos) | T154–T157 (Assets IA) |

---

## Tarefas de Risco (Fazer Cedo)

Estas tarefas têm maior probabilidade de revelar problemas bloqueantes:

| Prioridade | Tarefa | Risco Mitigado |
|---|---|---|
| 🔴 Crítico | T018 (Migrações Drift) | Schema errado em produção = perda de dados |
| 🔴 Crítico | T107 (Validação de boleto módulo 10/11) | Boleto inválido aceito = falha de pagamento |
| 🔴 Crítico | T103 (Permissões câmera) | UX de permissão mal feita = negação em massa |
| 🟡 Alto | T112 (OCR datasource) | Qualidade de extração abaixo do esperado |
| 🟡 Alto | T115 (PDF datasource Syncfusion) | Licença não registrada = watermark em produção |
| 🟡 Alto | T158 (Biometria) | Configuração de plataforma iOS/Android complexa |
| 🟠 Médio | T152 (fl_chart performance) | Lento com histórico longo — benchmarkar cedo |
| 🟠 Médio | T166 (InsightsEngine) | Regras de negócio financeiras sutis — testar exaustivamente |

---

## Definition of Done

### Por Tarefa
- [ ] Código escrito (implementação mínima que passa nos testes)
- [ ] Testes passando (Red→Green confirmado)
- [ ] `flutter analyze` limpo no arquivo alterado
- [ ] Sem `print()` com dados financeiros ou sensíveis
- [ ] Sem código morto ou TODOs críticos

### Por História de Usuário
- [ ] Todos os testes da história passando
- [ ] Cobertura mínima da camada respeitada
- [ ] Widget tests cobrem estados Loading, Loaded e Error
- [ ] `ConfirmationDialog` em todas as ações destrutivas
- [ ] Saldo nunca ambíguo (skeleton ou valor)
- [ ] Formatação pt-BR em todos os valores monetários
- [ ] Revisão de par aprovada

### Por Fase
- [ ] Todos os testes da fase passando
- [ ] `flutter analyze` limpo no repositório inteiro
- [ ] Cobertura gates atendidos (Domain ≥ 95%, Application ≥ 90%, Data ≥ 80%)
- [ ] `docs/architecture.md` atualizado se houve mudança arquitetural
- [ ] ADR escrito para cada decisão arquitetural nova
- [ ] `CHANGELOG.md` atualizado

### Para Release v1.0.0
- [ ] Todas as 7 fases completas
- [ ] `flutter analyze` limpo — zero warnings
- [ ] Cobertura gates passando em CI
- [ ] Security audit (`007`) aprovado
- [ ] Testes de integração passando em dispositivo Android real
- [ ] Testes de integração passando em simulador iOS
- [ ] Performance: cold start < 2s em Moto G, 60fps em listas
- [ ] Backup/restore funcional
- [ ] Política de privacidade publicada
- [ ] Licença Syncfusion registrada
- [ ] Screenshots de loja aprovados
- [ ] TestFlight beta testado

---

## Recomendação Final: Primeiras 10 Tarefas para Iniciar Agora

Execute estas tarefas nesta ordem. Elas são sequencialmente dependentes e desbloqueiam todo o backlog:

```
1. T001 — Criar projeto Flutter com flavors (base de tudo)
2. T002 — Criar estrutura de pastas Clean Architecture
3. T003 — Configurar pubspec.yaml com pacotes aprovados
4. T004 — Configurar analysis_options.yaml com regras de camadas
5. T017 — Configurar Drift (AppDatabase + LazyDatabase)
6. T018 — Criar schema v1 + testes de migração em memória
7. T019 — Configurar harness de testes (mocks, helpers, overrides)
8. T007 — Configurar Riverpod + ProviderScope + teste de provider raiz
9. T008 — Configurar go_router com shell route e bottom navigation
10. T020 — Escrever docs/architecture.md + ADRs 001–004
```

**Após T001–T020 completos**: iniciar T021 (Account entity) e T038 (Category entity) em paralelo — são as fundações de todo o módulo financeiro.

---

**Total de tarefas**: 187
**Fase 1**: T001–T020 (20 tarefas)
**Fase 2**: T021–T102 (82 tarefas)
**Fase 3**: T103–T125 (23 tarefas)
**Fase 4**: T126–T146 (21 tarefas)
**Fase 5**: T147–T163 (17 tarefas)
**Fase 6**: T164–T171 (8 tarefas)
**Fase 7**: T172–T187 (16 tarefas)
