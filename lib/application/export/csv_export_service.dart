import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';

/// Pure static service that converts domain lists into RFC-4180 CSV strings.
///
/// All CSV values are properly escaped:
/// - Values containing commas, newlines, or double-quotes are enclosed in `"`.
/// - Double-quotes inside values are doubled (`"` → `""`).
///
/// The caller is responsible for writing the returned string to a file or
/// sharing it. Use [AppConstants.csvExportIsolateThreshold] to decide whether
/// to run in an isolate for large datasets.
abstract final class CsvExportService {
  // ── Transactions ─────────────────────────────────────────────────────────

  static const _transactionHeader =
      'Data,Descrição,Tipo,Valor (R\$),Categoria,Conta,Notas';

  /// Converts [transactions] to a UTF-8 CSV string.
  ///
  /// Column order: Data, Descrição, Tipo, Valor, Categoria, Conta, Notas
  static String transactionsToCsv(
    List<Transaction> transactions, {
    Map<String, String> categoryNames = const {},
    Map<String, String> accountNames = const {},
  }) {
    final buf = StringBuffer(_transactionHeader);
    for (final tx in transactions) {
      buf.write('\n');
      buf.write(_field(_isoDate(tx.date)));
      buf.write(',');
      buf.write(_field(tx.description));
      buf.write(',');
      buf.write(_field(_txType(tx.type)));
      buf.write(',');
      buf.write(_field(_amount(tx.amount.amount)));
      buf.write(',');
      buf.write(_field(categoryNames[tx.categoryId] ?? ''));
      buf.write(',');
      buf.write(_field(accountNames[tx.accountId] ?? ''));
      buf.write(',');
      buf.write(_field(tx.notes ?? ''));
    }
    return buf.toString();
  }

  // ── Bills ─────────────────────────────────────────────────────────────────

  static const _billHeader =
      'Título,Valor (R\$),Vencimento,Status,Beneficiário,Código de Barras';

  /// Converts [bills] to a UTF-8 CSV string.
  static String billsToCsv(List<Bill> bills) {
    final buf = StringBuffer(_billHeader);
    for (final bill in bills) {
      buf.write('\n');
      buf.write(_field(bill.title));
      buf.write(',');
      buf.write(_field(_amount(bill.amount.amount)));
      buf.write(',');
      buf.write(_field(_isoDate(bill.dueDate)));
      buf.write(',');
      buf.write(_field(_billStatus(bill.status)));
      buf.write(',');
      buf.write(_field(bill.beneficiary ?? ''));
      buf.write(',');
      buf.write(_field(bill.barcode?.value ?? bill.pixCode?.value ?? ''));
    }
    return buf.toString();
  }

  // ── Debts ─────────────────────────────────────────────────────────────────

  static const _debtHeader =
      'Credor,Valor Total (R\$),Saldo Restante (R\$),Parcelas,Parcelas Pagas,Data de Início,Status';

  /// Converts [debts] to a UTF-8 CSV string.
  static String debtsToCsv(List<Debt> debts) {
    final buf = StringBuffer(_debtHeader);
    for (final debt in debts) {
      buf.write('\n');
      buf.write(_field(debt.creditorName));
      buf.write(',');
      buf.write(_field(_amount(debt.totalAmount.amount)));
      buf.write(',');
      buf.write(_field(_amount(debt.remainingAmount.amount)));
      buf.write(',');
      buf.write(_field(debt.installments?.toString() ?? ''));
      buf.write(',');
      buf.write(_field(debt.installmentsPaid.toString()));
      buf.write(',');
      buf.write(_field(_isoDate(debt.startDate)));
      buf.write(',');
      buf.write(_field(_debtStatus(debt.status)));
    }
    return buf.toString();
  }

  // ── Monthly report ────────────────────────────────────────────────────────

  static const _monthlyHeader = 'Categoria,Tipo,Valor (R\$),Nº Transações';

  /// Generates a category-aggregated monthly summary CSV.
  ///
  /// Groups [transactions] by [categoryId] (resolved via [categoryNames])
  /// and sums income/expense amounts.
  static String monthlyReportToCsv(
    List<Transaction> transactions, {
    required Map<String, String> categoryNames,
    required int year,
    required int month,
  }) {
    // Filter to given month
    final filtered = transactions.where((t) {
      final d = t.date.toLocal();
      return d.year == year && d.month == month;
    }).toList();

    // Aggregate per category + type
    final Map<String, _CategorySum> sums = {};
    for (final tx in filtered) {
      if (tx.type == TransactionType.transfer) continue;
      final key = '${tx.categoryId ?? "__none__"}:${tx.type.name}';
      final label = categoryNames[tx.categoryId] ?? 'Sem categoria';
      sums.putIfAbsent(key, () => _CategorySum(label, tx.type));
      sums[key]!.add(tx.amount.amount);
    }

    final buf = StringBuffer(_monthlyHeader);
    for (final entry in sums.values) {
      buf.write('\n');
      buf.write(_field(entry.categoryName));
      buf.write(',');
      buf.write(_field(_txType(entry.type)));
      buf.write(',');
      buf.write(_field(_amount(entry.total)));
      buf.write(',');
      buf.write(_field(entry.count.toString()));
    }
    return buf.toString();
  }

  // ── RFC-4180 helpers ──────────────────────────────────────────────────────

  /// Wraps [value] in double-quotes if it contains a comma, quote, or newline.
  /// Double-quotes within the value are doubled.
  static String _field(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _isoDate(DateTime d) {
    final utc = d.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}';
  }

  static String _amount(double v) => v.toStringAsFixed(2);

  static String _txType(TransactionType type) => switch (type) {
        TransactionType.income => 'Receita',
        TransactionType.expense => 'Despesa',
        TransactionType.transfer => 'Transferência',
      };

  static String _billStatus(BillStatus status) => switch (status) {
        BillStatus.pending => 'Pendente',
        BillStatus.paid => 'Pago',
        BillStatus.overdue => 'Vencido',
        BillStatus.cancelled => 'Cancelado',
      };

  static String _debtStatus(DebtStatus status) => switch (status) {
        DebtStatus.active => 'Ativo',
        DebtStatus.paid => 'Pago',
        DebtStatus.renegotiated => 'Renegociado',
      };
}

class _CategorySum {
  _CategorySum(this.categoryName, this.type);

  final String categoryName;
  final TransactionType type;
  double total = 0;
  int count = 0;

  void add(double amount) {
    total += amount;
    count++;
  }
}
