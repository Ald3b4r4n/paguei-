# Arquitetura do Paguei?

**Versão**: 1.0 | **Data**: 2026-04-19 | **Schema Drift**: v1

---

## Visão Geral

O Paguei? implementa **Clean Architecture** em 5 camadas com fluxo de dependência estritamente unidirecional (de fora para dentro):

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation                         │
│       (Widgets, Screens, Providers Riverpod)            │
├─────────────────────────────────────────────────────────┤
│                    Application                          │
│              (Use Cases, Orchestration)                 │
├─────────────────────────────────────────────────────────┤
│                      Domain                             │
│     (Entities, Value Objects, Repository Interfaces)    │
├─────────────────────────────────────────────────────────┤
│                       Data                             │
│   (Repository Impls, DAOs, Datasources, Models/DTOs)   │
├─────────────────────────────────────────────────────────┤
│                       Core                              │
│      (Errors, Logging, Utils, DI, Constants)            │
└─────────────────────────────────────────────────────────┘
```

### Regras de dependência

- `domain/` NÃO importa Flutter nem nenhum pacote de infraestrutura.
- `presentation/` NÃO acessa repositórios ou datasources diretamente.
- Lógica de negócio reside EXCLUSIVAMENTE em `domain/` e `application/`.
- Toda infraestrutura (banco de dados, APIs) é substituível sem alterar `domain/` ou `application/`.

---

## Camadas

### Core

Utilitários compartilhados sem lógica de negócio:
- `errors/` — hierarquia `Failure` (sealed) e `AppException`
- `logging/` — `AppLogger` interface + `ConsoleLogger` implementação
- `utils/` — `CurrencyFormatter` (pt-BR), `DateFormatter` (pt-BR)
- `constants/` — `AppConstants`
- `di/` — `appEnvironmentProvider`, `appLoggerProvider`, `appDatabaseProvider`

### Domain

Núcleo puro do negócio. Zero dependências externas.
- `entities/` — objetos de negócio imutáveis (Freezed)
- `value_objects/` — `Money`, `Barcode` (validação módulo 10/11), `PixCode`
- `repositories/` — interfaces abstratas (contratos)
- `failures/` — falhas específicas de domínio

### Application

Orquestração de use cases. Conhece `domain/`, não conhece Flutter.
- Um arquivo por use case
- Use case recebe repositórios via construtor (injeção)
- Retorna `Either<Failure, T>` ou simplesmente lança `AppException`

### Data

Implementações concretas de infraestrutura.
- `database/` — Drift `AppDatabase`, tabelas, DAOs, migrações
- `repositories/` — implementações de `XxxRepository`
- `datasources/` — acesso a câmera, OCR, PDF, notificações, armazenamento seguro
- `models/` — DTOs com mapeamento para/de entidades de domínio

### Presentation

UI Flutter. Conhece `application/`, não conhece `data/` diretamente.
- `theme/` — `AppTheme`, `AppColors`, `AppTypography`, `AppSpacing`
- `router/` — `app_router.dart` (go_router + ShellRoute)
- `<feature>/` — screens, widgets, providers Riverpod por feature
- `shared/` — widgets e providers compartilhados

---

## Stack Tecnológica

| Categoria | Tecnologia | Versão |
|---|---|---|
| Framework | Flutter | ≥3.22.0 |
| Linguagem | Dart | ≥3.4.0 |
| Estado | flutter_riverpod | ^3.3.1 |
| Banco de dados | drift | ^2.32.1 |
| Navegação | go_router | ^14.0.0 |
| Scanner | mobile_scanner | ^7.2.0 |
| OCR | google_mlkit_text_recognition | ^0.15.1 |
| PDF | syncfusion_flutter_pdf | ^33.1.49 |
| Notificações | flutter_local_notifications | ^21.0.0 |
| Gráficos | fl_chart | ^1.2.0 |
| Segurança | flutter_secure_storage | ^10.0.0 |
| Biometria | local_auth | ^3.0.1 |
| Animações | flutter_animate + lottie | ^4.5.2 + ^3.3.3 |

---

## Banco de Dados — Schema v1

**10 tabelas**: accounts, categories, transactions, bills, funds, debts, subscriptions, budget_limits, transfers, notification_logs

**Configuração SQLite**:
- `PRAGMA foreign_keys = ON`
- `PRAGMA journal_mode = WAL`
- `PRAGMA synchronous = NORMAL`

**Índices de performance**:
- `bills(dueDate, status)` — queries de dashboard e alertas
- `transactions(date, accountId)` — extrato mensal
- `transactions(categoryId)` — breakdown por categoria

---

## Decisões Arquiteturais

Ver `docs/adr/` para o raciocínio completo:
- [ADR-001](adr/001-riverpod-over-bloc.md): Riverpod sobre BLoC
- [ADR-002](adr/002-drift-over-isar.md): Drift sobre Isar/Hive
- [ADR-003](adr/003-offline-first-architecture.md): Arquitetura offline-first
- [ADR-004](adr/004-syncfusion-community-license.md): Licença community Syncfusion

---

## Geração de Código

Os seguintes pacotes requerem `dart run build_runner build`:
- **drift_dev** — gera `app_database.g.dart` (queries, DAOs, companions)
- **riverpod_generator** — gera providers anotados com `@riverpod`
- **freezed** — gera `copyWith`, `==`, `hashCode` para entidades imutáveis
- **json_serializable** — gera serialização JSON para DTOs

Sempre executar após qualquer mudança nos arquivos fonte:
```bash
dart run build_runner build --delete-conflicting-outputs
```
