import 'package:flutter_test/flutter_test.dart';
import 'package:paguei/application/export/csv_export_service.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Transaction _tx({
  required String id,
  required TransactionType type,
  required double amount,
  required String description,
  required DateTime date,
  String? categoryId,
  String? notes,
}) {
  final now = DateTime.utc(2026, 4, 1);
  return Transaction(
    id: id,
    accountId: 'acc1',
    type: type,
    amount: Money.fromDouble(amount),
    description: description,
    date: date,
    categoryId: categoryId,
    isRecurring: false,
    createdAt: now,
    updatedAt: now,
    notes: notes,
  );
}

Bill _bill({
  required String id,
  required String title,
  required double amount,
  required DateTime dueDate,
  BillStatus status = BillStatus.pending,
  String? beneficiary,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Bill(
    id: id,
    title: title,
    amount: Money.fromDouble(amount),
    dueDate: dueDate,
    status: status,
    isRecurring: false,
    reminderDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
    beneficiary: beneficiary,
  );
}

Debt _debt({
  required String id,
  required String creditorName,
  required double total,
  required double remaining,
  DebtStatus status = DebtStatus.active,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Debt(
    id: id,
    creditorName: creditorName,
    totalAmount: Money.fromDouble(total),
    remainingAmount: Money.fromDouble(remaining),
    installments: 12,
    installmentsPaid: 3,
    installmentAmount: Money.fromDouble(total / 12),
    interestRate: 0.0,
    startDate: DateTime.utc(2025, 1, 15),
    expectedEndDate: DateTime.utc(2026, 1, 15),
    status: status,
    notes: '',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // ── Transactions CSV ────────────────────────────────────────────────────

  group('CsvExportService.transactionsToCsv', () {
    test('returns valid CSV with header row', () {
      final transactions = [
        _tx(
          id: '1',
          type: TransactionType.income,
          amount: 3000.0,
          description: 'Salário',
          date: DateTime.utc(2026, 4, 5),
        ),
      ];

      final csv = CsvExportService.transactionsToCsv(transactions);
      final lines = csv.split('\n');

      expect(lines.first, contains('Data')); // header row has Date column
      expect(lines.first, contains('Descrição'));
      expect(lines.first, contains('Tipo'));
      expect(lines.first, contains('Valor'));
    });

    test('encodes income row correctly', () {
      final transactions = [
        _tx(
          id: '1',
          type: TransactionType.income,
          amount: 1500.50,
          description: 'Freelance',
          date: DateTime.utc(2026, 3, 15),
        ),
      ];

      final csv = CsvExportService.transactionsToCsv(transactions);
      expect(csv, contains('Receita'));
      expect(csv, contains('1500'));
      expect(csv, contains('Freelance'));
    });

    test('encodes expense row correctly', () {
      final transactions = [
        _tx(
          id: '2',
          type: TransactionType.expense,
          amount: 89.90,
          description: 'Mercado',
          date: DateTime.utc(2026, 4, 10),
        ),
      ];

      final csv = CsvExportService.transactionsToCsv(transactions);
      expect(csv, contains('Despesa'));
      expect(csv, contains('89'));
      expect(csv, contains('Mercado'));
    });

    test('escapes commas in description', () {
      final transactions = [
        _tx(
          id: '3',
          type: TransactionType.expense,
          amount: 100.0,
          description: 'Aluguel, condomínio',
          date: DateTime.utc(2026, 4, 1),
        ),
      ];

      final csv = CsvExportService.transactionsToCsv(transactions);
      // Description with commas must be quoted
      expect(csv, contains('"Aluguel, condomínio"'));
    });

    test('escapes double-quotes in description', () {
      final transactions = [
        _tx(
          id: '4',
          type: TransactionType.expense,
          amount: 50.0,
          description: 'Produto "premium"',
          date: DateTime.utc(2026, 4, 1),
        ),
      ];

      final csv = CsvExportService.transactionsToCsv(transactions);
      // CSV double-quote escaping: " → ""
      expect(csv, contains('""premium""'));
    });

    test('empty list returns header only', () {
      final csv = CsvExportService.transactionsToCsv([]);
      final lines = csv.trim().split('\n');
      expect(lines.length, 1); // header only
    });

    test('multiple rows are all present', () {
      final transactions = List.generate(
        5,
        (i) => _tx(
          id: '$i',
          type: TransactionType.expense,
          amount: (i + 1) * 10.0,
          description: 'Tx $i',
          date: DateTime.utc(2026, 4, i + 1),
        ),
      );

      final csv = CsvExportService.transactionsToCsv(transactions);
      final lines = csv.trim().split('\n');
      // header + 5 data rows
      expect(lines.length, 6);
    });
  });

  // ── Bills CSV ────────────────────────────────────────────────────────────

  group('CsvExportService.billsToCsv', () {
    test('returns valid CSV with header', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Internet',
          amount: 99.90,
          dueDate: DateTime.utc(2026, 5, 10),
        ),
      ];

      final csv = CsvExportService.billsToCsv(bills);
      expect(csv, contains('Título'));
      expect(csv, contains('Valor'));
      expect(csv, contains('Vencimento'));
      expect(csv, contains('Status'));
    });

    test('paid bill status is localised', () {
      final bills = [
        _bill(
          id: '1',
          title: 'Aluguel',
          amount: 1200.0,
          dueDate: DateTime.utc(2026, 4, 5),
          status: BillStatus.paid,
        ),
      ];

      final csv = CsvExportService.billsToCsv(bills);
      expect(csv, contains('Pago'));
    });
  });

  // ── Debts CSV ────────────────────────────────────────────────────────────

  group('CsvExportService.debtsToCsv', () {
    test('returns header with creditor and remaining columns', () {
      final debts = [
        _debt(
            id: '1',
            creditorName: 'Banco XYZ',
            total: 12000.0,
            remaining: 9000.0),
      ];

      final csv = CsvExportService.debtsToCsv(debts);
      expect(csv, contains('Credor'));
      expect(csv, contains('Valor Total'));
      expect(csv, contains('Saldo Restante'));
    });

    test('debt amounts are present in row', () {
      final debts = [
        _debt(
            id: '1',
            creditorName: 'Financeira',
            total: 5000.0,
            remaining: 3500.0),
      ];

      final csv = CsvExportService.debtsToCsv(debts);
      expect(csv, contains('5000'));
      expect(csv, contains('3500'));
      expect(csv, contains('Financeira'));
    });
  });
}
