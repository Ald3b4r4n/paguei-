# Contratos de Interface: Paguei?

**Data**: 2026-04-19
**Branch**: `docs/constitution-v1.0.0`
**Tipo de projeto**: Mobile App (Flutter)

---

## Contrato: Tela Principal — Dashboard

**Rota**: `/` (home)
**Propósito**: Responder "Paguei?" em menos de 3 segundos após abertura.

### Estado da UI

```dart
sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Money totalBalance;           // saldo total de todas as contas
  final Money paidThisMonth;          // total pago no mês corrente
  final Money pendingThisMonth;       // total pendente no mês corrente
  final List<BillSummary> upcoming;   // próximos boletos (7 dias)
  final List<SpendingTrend> trends;   // gastos por categoria (mês atual)
  final bool hasOverdueBills;         // flag de vencido (badge visual)
}

class DashboardError extends DashboardState {
  final String message;
}
```

### Requisitos Visuais Obrigatórios
- Saldo total em tipografia 32sp, peso Bold, cor principal da marca.
- "Pago" em verde; "Pendente" em âmbar; "Vencido" em vermelho.
- Boletos vencidos exibem badge vermelho no ícone da aba.
- Sem estado de saldo ambíguo — exibir loading skeleton durante carga.

---

## Contrato: Listagem de Boletos

**Rota**: `/bills`

### Estado da UI

```dart
sealed class BillListState {
  const BillListState();
}

class BillListLoaded extends BillListState {
  final List<BillItem> pending;
  final List<BillItem> overdue;
  final List<BillItem> paid;
  final BillFilter activeFilter;
  final BillSortOrder sortOrder;
}

enum BillFilter { all, pending, overdue, paid, thisMonth }
enum BillSortOrder { dueDateAsc, dueDateDesc, amountDesc, amountAsc }
```

### Ações (Use Cases invocados pela UI)
- `MarkBillAsPaidUseCase` — exige confirmação de diálogo.
- `DeleteBillUseCase` — exige confirmação de diálogo com texto do boleto.
- `CopyBarcodeUseCase` — copia para clipboard + toast "Código copiado".
- `OpenInBankAppUseCase` — intent/share com o código do boleto.

---

## Contrato: Leitor de Boleto (OCR/Scanner)

**Rota**: `/bills/scan`

### Estado da UI

```dart
sealed class BillScanState {
  const BillScanState();
}

class BillScanIdle extends BillScanState {}
class BillScanScanning extends BillScanState {}

class BillScanResult extends BillScanState {
  final String? barcode;
  final String? pixCode;
  final Money? amount;
  final DateTime? dueDate;
  final String? beneficiary;
  final String? issuer;
  final double confidence;    // 0.0–1.0 — determina se confirmação é necessária
}

class BillScanError extends BillScanState {
  final BillScanErrorType type;
}

enum BillScanErrorType {
  cameraPermissionDenied,
  unrecognizedFormat,
  pdfExtractionFailed,
}
```

### Fontes de Entrada
1. Câmera ao vivo (barcode + QR)
2. Galeria (imagem → OCR)
3. Upload de PDF → extração de texto
4. Upload de TXT → parsing

### Regra de Confirmação
- `confidence < 0.85`: exibir formulário de revisão com campos pré-preenchidos.
- `confidence ≥ 0.85`: ir diretamente para tela de salvar/lembrete.

---

## Contrato: Resumo Financeiro (Net Worth)

**Rota**: `/summary`

### Estado da UI

```dart
class FinancialSummaryState {
  final Money netWorth;                 // ativos − dívidas
  final Money totalAssets;             // soma de todas as contas
  final Money totalDebts;              // soma de dívidas ativas
  final Money totalFundsSaved;         // soma de fundos/reservas
  final List<AccountBalance> accounts;
  final List<DebtProgress> debts;
  final List<FundProgress> funds;
  final List<MonthlyObligation> obligations;  // parcelas mensais
}
```

---

## Contrato: Notificações Agendadas

### Schema de Payload

```json
{
  "notificationId": "uuid",
  "type": "bill_due | overdue | budget_exceeded | reminder",
  "referenceId": "uuid",
  "referenceType": "bill | subscription | budget",
  "title": "string (max 60 chars)",
  "body": "string (max 120 chars)",
  "scheduledAt": "ISO 8601",
  "deepLink": "/bills/{id}"
}
```

### Regras de Agendamento
- Notificação "vence hoje" às 09:00 do dia do vencimento.
- Notificação "X dias antes" às 20:00 do dia calculado.
- Notificação "vencido" às 08:00 do dia seguinte ao vencimento.
- Alerta de orçamento ao atingir `alertThreshold` (default 80%).
- Máximo de 64 notificações agendadas simultâneas (limite Android).

---

## Contrato: Exportação CSV

### Formato do Arquivo

```
Arquivo: paguei_transacoes_YYYY-MM.csv
Encoding: UTF-8 com BOM (para compatibilidade com Excel PT-BR)
Separador: ; (ponto-e-vírgula)

Colunas:
Data;Descrição;Categoria;Tipo;Valor;Conta;Status
```

### Regras
- Datas no formato `DD/MM/YYYY`.
- Valores em formato `1.234,56` (sem símbolo de moeda).
- Tipo: `Receita` | `Despesa` | `Transferência`.
- Status (boletos): `Pago` | `Pendente` | `Vencido` | `Cancelado`.
