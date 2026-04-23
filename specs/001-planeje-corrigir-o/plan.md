# Implementation Plan: Corrigir erro ao registrar receita

**Branch**: `001-planeje-corrigir-o` | **Date**: 2026-04-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-planeje-corrigir-o/spec.md`

## Summary

Corrigir o bloqueio na tela de Nova Transação em que o usuário não consegue registrar receita/despesa por falta de `accountId` selecionado, apesar de não haver seletor de conta visível. A solução adotada é tornar a seleção de conta explícita no formulário, ajustar estados para conta única/ausência de contas e cobrir o fluxo com testes de regressão de widget.

## Technical Context

**Language/Version**: Dart 3.4+ / Flutter 3.22+  
**Primary Dependencies**: `flutter_riverpod`, `go_router`, `drift`, `flutter_test`  
**Storage**: SQLite local via Drift (sem alteração de schema)  
**Testing**: `flutter_test` (widget tests), `flutter analyze`  
**Target Platform**: Android e iOS
**Project Type**: aplicativo mobile Flutter  
**Performance Goals**: manter interação de formulário fluida (60 fps) e submit sem regressão perceptível  
**Constraints**: manter Clean Architecture, preservar contrato de domínio (`accountId` obrigatório), sem migração de banco, fluxo offline-first  
**Scale/Scope**: 1 tela principal (`transaction_form_screen`), 1 suíte de testes de widget, sem novos módulos de domínio/dados

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Pre-Phase 0 Gate

- **I. Test-Driven Development**: PASS. O plano prevê testes de regressão de widget para reproduzir e prevenir o bug antes da implementação final.
- **II. Clean Architecture**: PASS. Mudanças concentradas em `presentation/`, com uso de casos de uso já existentes.
- **V. Financial UX Clarity**: PASS. A conta obrigatória deixa de ser implícita e passa a ser visível/acionável.
- **VI. Offline First**: PASS. Fluxo continua local com Drift; sem dependências remotas.
- **VIII. State Management Discipline**: PASS. Continuidade do padrão Riverpod com estado imutável de formulário.
- **X. Delivery Governance**: PASS. Sequência especificação -> plano -> (próximo) tarefas respeitada.

**Gate Status**: PASS

## Project Structure

### Documentation (this feature)

```text
specs/001-planeje-corrigir-o/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── transaction-form-ui-contract.md
└── tasks.md   # gerado posteriormente por /speckit.tasks
```

### Source Code (repository root)

```text
lib/
├── presentation/
│   ├── transactions/
│   │   └── transaction_form_screen.dart
│   └── accounts/
│       └── providers/accounts_provider.dart   # reutilizado como fonte de contas
├── application/
│   └── transactions/create_transaction_use_case.dart   # contrato existente, sem mudanças
└── domain/
    └── entities/transaction.dart   # validações existentes, sem mudanças

test/
└── presentation/
    └── transactions/
        └── transaction_form_screen_test.dart
```

**Structure Decision**: Manter a estrutura atual em projeto Flutter único, com mudanças de comportamento e validação na camada de apresentação e cobertura de regressão em testes de widget.

## Phase 0: Outline & Research

### Unknowns identificados no início

- Estratégia de conta padrão em criação de transação.
- Comportamento esperado quando não houver contas ativas.
- Padrão de componente para seleção de conta consistente com o app.

### Resultado da pesquisa

Todas as clarificações foram resolvidas em [research.md](./research.md):

1. Seletor de conta obrigatório e visível no formulário.
2. Pré-seleção automática somente quando houver exatamente uma conta ativa.
3. Estado orientativo com submit bloqueado quando não houver contas.
4. Reuso de padrão de dropdown já presente em transferências/boletos.
5. Estratégia de regressão via testes de widget específicos para receita.

## Phase 1: Design & Contracts

- Modelo de dados de apresentação e transições documentados em [data-model.md](./data-model.md).
- Contrato de interação de UI e payload de submissão documentado em [contracts/transaction-form-ui-contract.md](./contracts/transaction-form-ui-contract.md).
- Passo a passo de validação manual e automatizada documentado em [quickstart.md](./quickstart.md).

## Phase 2: Planning Readiness

Feature pronta para geração de `tasks.md` com foco em:

1. Testes de regressão primeiro (receita com conta, sem conta, zero contas).
2. Implementação de seletor e estados de conta no formulário.
3. Ajustes de UX e mensagens de erro.
4. Execução de análise e suíte de testes.

## Constitution Check (Post-Design Re-check)

- **I. Test-Driven Development**: PASS. Critérios de sucesso e quickstart exigem testes de regressão explícitos.
- **II. Clean Architecture**: PASS. Design não introduz dependências cruzadas indevidas.
- **V. Financial UX Clarity**: PASS. Requisito de conta ficou visível e rastreável no contrato de UI.
- **VI. Offline First**: PASS. Nenhuma dependência de rede adicionada.
- **VIII. State Management Discipline**: PASS. Fluxo permanece orientado a providers Riverpod.
- **X. Delivery Governance**: PASS. Artefatos de pesquisa/design gerados antes de tarefas/implementação.

**Post-Design Gate Status**: PASS

## Complexity Tracking

Sem violações de constituição que exijam justificativa adicional.
