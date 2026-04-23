# Modelo de Dados: Paguei?

**Data**: 2026-04-19
**Branch**: `docs/constitution-v1.0.0`
**Banco de dados**: Drift (SQLite) — schema v1

---

## Entidades Principais

### 1. `Account` (Conta / Carteira)

Representa uma conta ou carteira de dinheiro do usuário.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `name` | text | NOT NULL, max 100 | Nome da conta (ex.: "Nubank", "Dinheiro") |
| `type` | text | NOT NULL | Enum: `checking`, `savings`, `wallet`, `investment` |
| `initialBalance` | real | NOT NULL, default 0 | Saldo inicial ao criar a conta |
| `currentBalance` | real | NOT NULL | Saldo atual calculado |
| `currency` | text | NOT NULL, default 'BRL' | ISO 4217 |
| `color` | integer | NOT NULL | ARGB color int para identificação visual |
| `icon` | text | NOT NULL | Nome do ícone do sistema |
| `isActive` | boolean | NOT NULL, default true | Soft delete |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |
| `updatedAt` | datetime | NOT NULL | Timestamp UTC |

**Invariantes**:
- `currentBalance` deve ser recalculado a partir das transações, nunca editado diretamente.
- Uma conta só pode ser desativada se não tiver saldo pendente em boletos.

---

### 2. `Transaction` (Transação)

Representa um movimento financeiro (receita, despesa ou transferência).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `accountId` | UUID (text) | FK → Account, NOT NULL | Conta de origem |
| `categoryId` | UUID (text) | FK → Category, NULL | Categoria (opcional) |
| `billId` | UUID (text) | FK → Bill, NULL | Boleto vinculado (se houver) |
| `type` | text | NOT NULL | Enum: `income`, `expense`, `transfer` |
| `amount` | real | NOT NULL, > 0 | Valor absoluto em BRL |
| `description` | text | NOT NULL, max 255 | Descrição da transação |
| `date` | date | NOT NULL | Data da transação (sem hora) |
| `isRecurring` | boolean | NOT NULL, default false | É recorrente? |
| `recurrenceGroupId` | UUID (text) | NULL | Agrupa transações recorrentes |
| `notes` | text | NULL | Observações livres |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |
| `updatedAt` | datetime | NOT NULL | Timestamp UTC |

**Invariantes**:
- `amount` é sempre positivo; o `type` determina direção.
- Transações de `transfer` requerem `toAccountId` na tabela `Transfer`.
- Exclusão de transação DEVE recalcular `Account.currentBalance`.

---

### 3. `Bill` (Boleto / Conta a Pagar)

Representa uma conta a pagar, com ou sem leitura de barcode.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `accountId` | UUID (text) | FK → Account, NULL | Conta para débito planejado |
| `categoryId` | UUID (text) | FK → Category, NULL | Categoria |
| `title` | text | NOT NULL, max 150 | Título descritivo |
| `amount` | real | NOT NULL, > 0 | Valor do boleto |
| `dueDate` | date | NOT NULL | Data de vencimento |
| `status` | text | NOT NULL | Enum: `pending`, `paid`, `overdue`, `cancelled` |
| `barcode` | text | NULL, max 100 | Linha digitável / código de barras |
| `pixCode` | text | NULL | Código PIX Copia e Cola |
| `beneficiary` | text | NULL, max 150 | Nome do beneficiário |
| `issuer` | text | NULL, max 150 | Emissor do documento |
| `documentType` | text | NULL | Enum: `boleto`, `pix`, `other` |
| `isRecurring` | boolean | NOT NULL, default false | Conta recorrente? |
| `recurrenceRule` | text | NULL | JSON: `{freq, interval, endDate}` |
| `paidAt` | datetime | NULL | Quando foi marcado como pago |
| `paidAmount` | real | NULL | Valor efetivamente pago |
| `reminderDaysBefore` | integer | NULL, default 3 | Dias antes para lembrar |
| `notes` | text | NULL | Observações |
| `attachmentPath` | text | NULL | Caminho local do arquivo (PDF/imagem) |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |
| `updatedAt` | datetime | NOT NULL | Timestamp UTC |

**Invariantes**:
- `status` = `overdue` é calculado: `dueDate < hoje AND status = 'pending'`.
- Marcar como pago cria automaticamente uma `Transaction` vinculada.
- `barcode` DEVE ser validado contra algoritmo módulo 10/11 antes de salvar.

---

### 4. `Category` (Categoria)

Categorias de receitas e despesas.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `name` | text | NOT NULL, max 80 | Nome da categoria |
| `type` | text | NOT NULL | Enum: `income`, `expense`, `both` |
| `icon` | text | NOT NULL | Nome do asset do ícone |
| `color` | integer | NOT NULL | ARGB color int |
| `isDefault` | boolean | NOT NULL, default false | Categoria padrão do sistema |
| `parentId` | UUID (text) | FK → Category, NULL | Subcategoria |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |

**Categorias padrão de despesas**: Alimentação, Transporte, Moradia, Saúde, Educação,
Lazer, Vestuário, Assinaturas, Impostos, Outros.
**Categorias padrão de receitas**: Salário, Freelance, Investimentos, Outros.

---

### 5. `Fund` (Fundo / Reserva)

Representa reservas de emergência e metas de poupança.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `name` | text | NOT NULL, max 100 | Nome do fundo |
| `type` | text | NOT NULL | Enum: `emergency`, `goal`, `savings` |
| `targetAmount` | real | NOT NULL, > 0 | Meta em BRL |
| `currentAmount` | real | NOT NULL, default 0 | Valor acumulado |
| `targetDate` | date | NULL | Data alvo (para goals) |
| `color` | integer | NOT NULL | ARGB color int |
| `icon` | text | NOT NULL | Ícone visual |
| `isCompleted` | boolean | NOT NULL, default false | Meta atingida? |
| `notes` | text | NULL | Observações |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |
| `updatedAt` | datetime | NOT NULL | Timestamp UTC |

---

### 6. `Debt` (Dívida)

Controle de dívidas com credores externos.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `creditorName` | text | NOT NULL, max 150 | Nome do credor |
| `totalAmount` | real | NOT NULL, > 0 | Valor total da dívida |
| `remainingAmount` | real | NOT NULL | Saldo devedor |
| `installments` | integer | NULL | Total de parcelas (NULL = sem prazo) |
| `installmentsPaid` | integer | NOT NULL, default 0 | Parcelas pagas |
| `installmentAmount` | real | NULL | Valor de cada parcela |
| `interestRate` | real | NULL | Taxa de juros mensal (%) |
| `startDate` | date | NOT NULL | Data de início |
| `expectedEndDate` | date | NULL | Data prevista de quitação |
| `status` | text | NOT NULL | Enum: `active`, `paid`, `renegotiated` |
| `notes` | text | NULL | Observações |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |
| `updatedAt` | datetime | NOT NULL | Timestamp UTC |

---

### 7. `Subscription` (Assinatura Recorrente)

Rastreamento de assinaturas (streaming, SaaS, etc.).

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `name` | text | NOT NULL, max 100 | Nome da assinatura |
| `amount` | real | NOT NULL, > 0 | Valor mensal/anual |
| `billingCycle` | text | NOT NULL | Enum: `monthly`, `yearly`, `weekly` |
| `nextBillingDate` | date | NOT NULL | Próxima cobrança |
| `categoryId` | UUID (text) | FK → Category, NULL | Categoria |
| `color` | integer | NOT NULL | ARGB color int |
| `icon` | text | NOT NULL | Ícone |
| `isActive` | boolean | NOT NULL, default true | Ativa ou cancelada |
| `reminderEnabled` | boolean | NOT NULL, default true | Lembrete habilitado |
| `reminderDaysBefore` | integer | NOT NULL, default 3 | Dias antes para lembrar |
| `notes` | text | NULL | Observações |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |

---

### 8. `BudgetLimit` (Limite de Orçamento)

Limites mensais por categoria.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `categoryId` | UUID (text) | FK → Category, NOT NULL | Categoria |
| `limitAmount` | real | NOT NULL, > 0 | Limite em BRL |
| `month` | integer | NOT NULL | Mês (1–12) |
| `year` | integer | NOT NULL | Ano (ex.: 2026) |
| `alertThreshold` | real | NOT NULL, default 0.8 | Alertar em % do limite |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |

**Constraint única**: `(categoryId, month, year)` — um limite por categoria por mês.

---

### 9. `Transfer` (Transferência entre Contas)

Registro de movimentos entre contas internas.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `fromAccountId` | UUID (text) | FK → Account, NOT NULL | Conta de origem |
| `toAccountId` | UUID (text) | FK → Account, NOT NULL | Conta de destino |
| `transactionId` | UUID (text) | FK → Transaction, NOT NULL | Transação de débito |
| `amount` | real | NOT NULL, > 0 | Valor transferido |
| `date` | date | NOT NULL | Data da transferência |
| `notes` | text | NULL | Observações |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |

---

### 10. `NotificationLog` (Log de Notificações)

Registro de notificações enviadas para debug e controle.

| Campo | Tipo | Restrições | Descrição |
|---|---|---|---|
| `id` | UUID (text) | PK, NOT NULL | Identificador único |
| `type` | text | NOT NULL | Enum: `bill_due`, `overdue`, `budget_exceeded`, `reminder` |
| `referenceId` | UUID (text) | NOT NULL | ID da entidade relacionada |
| `referenceType` | text | NOT NULL | Enum: `bill`, `subscription`, `budget` |
| `scheduledAt` | datetime | NOT NULL | Quando foi agendada |
| `sentAt` | datetime | NULL | Quando foi enviada |
| `title` | text | NOT NULL | Título da notificação |
| `body` | text | NOT NULL | Corpo da notificação |
| `createdAt` | datetime | NOT NULL | Timestamp UTC |

---

## Relacionamentos

```
Account (1) ──────────────── (N) Transaction
Account (1) ──────────────── (N) Bill
Category (1) ─────────────── (N) Transaction
Category (1) ─────────────── (N) Bill
Category (1) ─────────────── (N) BudgetLimit
Category (1) ─────────────── (N) Category (self-ref subcategoria)
Bill (1) ─────────────────── (0..1) Transaction
Debt (1) ─────────────────── (N) Transaction (pagamentos parciais)
Transfer (1) ─────────────── (1) Transaction
Subscription (1) ─────────── (N) Bill (geração automática)
```

---

## Schema de Versões (Drift)

```
Schema v1 (2026-04-19):
  - Tabelas: accounts, transactions, bills, categories,
             funds, debts, subscriptions, budget_limits,
             transfers, notification_logs
  - Índices: bills(dueDate, status), transactions(date, accountId),
             transactions(categoryId), budget_limits(categoryId, month, year)
```

---

## Regras de Negócio Críticas

1. **Saldo nunca pode ser ambíguo**: `Account.currentBalance` é calculado via view Drift
   (`SELECT SUM(amount) FROM transactions WHERE accountId = ?` por tipo).

2. **Boleto vencido**: calculado dinamicamente, nunca armazenado — evita inconsistência
   após falha de sincronização.

3. **Exclusão suave**: entidades financeiras usam `isActive = false` em vez de DELETE para
   preservar histórico e consistência de totais históricos.

4. **Recorrência**: `Bill.isRecurring = true` com `recurrenceRule` dispara geração automática
   de boletos futuros via use case `GenerateRecurringBillsUseCase`.

5. **Audit trail leve**: `createdAt` e `updatedAt` em todas as tabelas mutáveis.
