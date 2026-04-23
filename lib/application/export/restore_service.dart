import 'package:paguei/domain/entities/account.dart';
import 'package:paguei/domain/entities/account_type.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/entities/category.dart';
import 'package:paguei/domain/entities/category_type.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/account_repository.dart';
import 'package:paguei/domain/repositories/bill_repository.dart';
import 'package:paguei/domain/repositories/category_repository.dart';
import 'package:paguei/domain/repositories/debt_repository.dart';
import 'package:paguei/domain/repositories/fund_repository.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

// ---------------------------------------------------------------------------
// RestoreMode
// ---------------------------------------------------------------------------

/// Determines how existing data is handled during a restore operation.
///
/// - [merge]: existing records (same `id`) are kept unchanged; only new
///   records from the backup are inserted.
/// - [replace]: existing records are overwritten with backup data; new records
///   are also inserted.
enum RestoreMode { merge, replace }

// ---------------------------------------------------------------------------
// RestoreResult
// ---------------------------------------------------------------------------

/// Summary of a completed restore operation.
final class RestoreResult {
  const RestoreResult({
    required this.accountsInserted,
    required this.accountsUpdated,
    required this.accountsSkipped,
    required this.transactionsInserted,
    required this.transactionsUpdated,
    required this.transactionsSkipped,
    required this.billsInserted,
    required this.billsUpdated,
    required this.billsSkipped,
    required this.fundsInserted,
    required this.fundsUpdated,
    required this.fundsSkipped,
    required this.debtsInserted,
    required this.debtsUpdated,
    required this.debtsSkipped,
    required this.categoriesInserted,
    required this.categoriesUpdated,
    required this.categoriesSkipped,
    required this.errors,
  });

  /// Convenience zero-value constructor.
  const RestoreResult.empty()
      : accountsInserted = 0,
        accountsUpdated = 0,
        accountsSkipped = 0,
        transactionsInserted = 0,
        transactionsUpdated = 0,
        transactionsSkipped = 0,
        billsInserted = 0,
        billsUpdated = 0,
        billsSkipped = 0,
        fundsInserted = 0,
        fundsUpdated = 0,
        fundsSkipped = 0,
        debtsInserted = 0,
        debtsUpdated = 0,
        debtsSkipped = 0,
        categoriesInserted = 0,
        categoriesUpdated = 0,
        categoriesSkipped = 0,
        errors = const [];

  final int accountsInserted;
  final int accountsUpdated;
  final int accountsSkipped;
  final int transactionsInserted;
  final int transactionsUpdated;
  final int transactionsSkipped;
  final int billsInserted;
  final int billsUpdated;
  final int billsSkipped;
  final int fundsInserted;
  final int fundsUpdated;
  final int fundsSkipped;
  final int debtsInserted;
  final int debtsUpdated;
  final int debtsSkipped;
  final int categoriesInserted;
  final int categoriesUpdated;
  final int categoriesSkipped;

  /// Non-fatal errors encountered during restore (entity id → error message).
  final List<String> errors;

  int get totalInserted =>
      accountsInserted +
      transactionsInserted +
      billsInserted +
      fundsInserted +
      debtsInserted +
      categoriesInserted;

  int get totalUpdated =>
      accountsUpdated +
      transactionsUpdated +
      billsUpdated +
      fundsUpdated +
      debtsUpdated +
      categoriesUpdated;

  int get totalSkipped =>
      accountsSkipped +
      transactionsSkipped +
      billsSkipped +
      fundsSkipped +
      debtsSkipped +
      categoriesSkipped;

  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() =>
      'RestoreResult(inserted: $totalInserted, updated: $totalUpdated, '
      'skipped: $totalSkipped, errors: ${errors.length})';
}

// ---------------------------------------------------------------------------
// _EntityCounts helper
// ---------------------------------------------------------------------------

/// Mutable accumulator used while restoring a single entity type.
final class _Tally {
  int inserted = 0;
  int updated = 0;
  int skipped = 0;
  final List<String> errors = [];
}

// ---------------------------------------------------------------------------
// RestoreService
// ---------------------------------------------------------------------------

/// Restores a decoded backup payload into the app's repositories.
///
/// Usage:
/// ```dart
/// final data = await BackupService.decodeBackup(file: file, password: pw);
/// final service = RestoreService(
///   accounts: accountRepo, transactions: transactionRepo, ...);
/// final result = await service.restore(data, mode: RestoreMode.merge);
/// ```
///
/// ## Restore modes
///
/// - **merge** — only new entities (IDs not found in the database) are
///   inserted. Existing records are left unchanged.
/// - **replace** — existing entities are overwritten with backup data;
///   new entities are inserted. Records in the database whose IDs do **not**
///   appear in the backup are left untouched.
///
/// ## Timestamp handling
///
/// When an entity must be *inserted* (no existing row), this service calls
/// `repository.create(...)` to satisfy the normal domain validation path
/// (which sets `createdAt = now`), then immediately calls `update(entity)`
/// to restore the original timestamps from the backup. Entities that are
/// *updated* (replace mode) preserve all original timestamps via `update()`.
///
/// ## Error handling
///
/// Non-fatal parse errors are collected in [RestoreResult.errors] and
/// processing continues for the remaining entities.
final class RestoreService {
  const RestoreService({
    required AccountRepository accounts,
    required TransactionRepository transactions,
    required BillRepository bills,
    required FundRepository funds,
    required DebtRepository debts,
    required CategoryRepository categories,
  })  : _accounts = accounts,
        _transactions = transactions,
        _bills = bills,
        _funds = funds,
        _debts = debts,
        _categories = categories;

  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final BillRepository _bills;
  final FundRepository _funds;
  final DebtRepository _debts;
  final CategoryRepository _categories;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Restores all entity types from [data].
  ///
  /// [data] is the decoded backup payload (result of [BackupService.decodeBackup]).
  Future<RestoreResult> restore(
    Map<String, dynamic> data, {
    required RestoreMode mode,
  }) async {
    final accountTally = _Tally();
    final categoryTally = _Tally();
    final txTally = _Tally();
    final billTally = _Tally();
    final fundTally = _Tally();
    final debtTally = _Tally();

    // Restore order matters: categories & accounts before transactions/bills.
    await _restoreCategories(data, mode, categoryTally);
    await _restoreAccounts(data, mode, accountTally);
    await _restoreFunds(data, mode, fundTally);
    await _restoreDebts(data, mode, debtTally);
    await _restoreBills(data, mode, billTally);
    await _restoreTransactions(data, mode, txTally);

    final allErrors = [
      ...categoryTally.errors,
      ...accountTally.errors,
      ...fundTally.errors,
      ...debtTally.errors,
      ...billTally.errors,
      ...txTally.errors,
    ];

    return RestoreResult(
      accountsInserted: accountTally.inserted,
      accountsUpdated: accountTally.updated,
      accountsSkipped: accountTally.skipped,
      transactionsInserted: txTally.inserted,
      transactionsUpdated: txTally.updated,
      transactionsSkipped: txTally.skipped,
      billsInserted: billTally.inserted,
      billsUpdated: billTally.updated,
      billsSkipped: billTally.skipped,
      fundsInserted: fundTally.inserted,
      fundsUpdated: fundTally.updated,
      fundsSkipped: fundTally.skipped,
      debtsInserted: debtTally.inserted,
      debtsUpdated: debtTally.updated,
      debtsSkipped: debtTally.skipped,
      categoriesInserted: categoryTally.inserted,
      categoriesUpdated: categoryTally.updated,
      categoriesSkipped: categoryTally.skipped,
      errors: allErrors,
    );
  }

  // ── Per-type restore helpers ───────────────────────────────────────────────

  Future<void> _restoreAccounts(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'accounts');
    for (final raw in list) {
      try {
        final entity = _AccountSerializer.fromJson(raw);
        final existing = await _accounts.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _accounts.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _accounts.create(
            id: entity.id,
            name: entity.name,
            type: entity.type,
            initialBalance: entity.currentBalance,
            currency: entity.currency,
            color: entity.color,
            icon: entity.icon,
          );
          // Restore original timestamps (create() sets now).
          await _accounts.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('account[${raw['id']}]: $e');
      }
    }
  }

  Future<void> _restoreTransactions(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'transactions');
    for (final raw in list) {
      try {
        final entity = _TransactionSerializer.fromJson(raw);
        final existing = await _transactions.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _transactions.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _transactions.create(
            id: entity.id,
            accountId: entity.accountId,
            type: entity.type,
            amount: entity.amount,
            description: entity.description,
            date: entity.date,
            categoryId: entity.categoryId,
            billId: entity.billId,
            isRecurring: entity.isRecurring,
            recurrenceGroupId: entity.recurrenceGroupId,
            notes: entity.notes,
          );
          await _transactions.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('transaction[${raw['id']}]: $e');
      }
    }
  }

  Future<void> _restoreBills(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'bills');
    for (final raw in list) {
      try {
        final entity = _BillSerializer.fromJson(raw);
        final existing = await _bills.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _bills.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _bills.create(
            id: entity.id,
            title: entity.title,
            amount: entity.amount,
            dueDate: entity.dueDate,
            accountId: entity.accountId,
            categoryId: entity.categoryId,
            barcode: entity.barcode,
            pixCode: entity.pixCode,
            beneficiary: entity.beneficiary,
            issuer: entity.issuer,
            documentType: entity.documentType,
            isRecurring: entity.isRecurring,
            recurrenceRule: entity.recurrenceRule,
            reminderDaysBefore: entity.reminderDaysBefore,
            notes: entity.notes,
            attachmentPath: entity.attachmentPath,
          );
          await _bills.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('bill[${raw['id']}]: $e');
      }
    }
  }

  Future<void> _restoreFunds(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'funds');
    for (final raw in list) {
      try {
        final entity = _FundSerializer.fromJson(raw);
        final existing = await _funds.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _funds.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _funds.create(
            id: entity.id,
            name: entity.name,
            type: entity.type,
            targetAmount: entity.targetAmount,
            color: entity.color,
            icon: entity.icon,
            targetDate: entity.targetDate,
            notes: entity.notes,
          );
          await _funds.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('fund[${raw['id']}]: $e');
      }
    }
  }

  Future<void> _restoreDebts(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'debts');
    for (final raw in list) {
      try {
        final entity = _DebtSerializer.fromJson(raw);
        final existing = await _debts.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _debts.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _debts.create(
            id: entity.id,
            creditorName: entity.creditorName,
            totalAmount: entity.totalAmount,
            installments: entity.installments,
            installmentAmount: entity.installmentAmount,
            interestRate: entity.interestRate,
            expectedEndDate: entity.expectedEndDate,
            notes: entity.notes,
          );
          await _debts.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('debt[${raw['id']}]: $e');
      }
    }
  }

  Future<void> _restoreCategories(
      Map<String, dynamic> data, RestoreMode mode, _Tally t) async {
    final list = _listOf(data, 'categories');
    for (final raw in list) {
      try {
        final entity = _CategorySerializer.fromJson(raw);
        final existing = await _categories.getById(entity.id);
        if (existing != null) {
          if (mode == RestoreMode.replace) {
            await _categories.update(entity);
            t.updated++;
          } else {
            t.skipped++;
          }
        } else {
          await _categories.create(
            id: entity.id,
            name: entity.name,
            type: entity.type,
            icon: entity.icon,
            color: entity.color,
            isDefault: entity.isDefault,
            parentId: entity.parentId,
          );
          await _categories.update(entity);
          t.inserted++;
        }
      } catch (e) {
        t.errors.add('category[${raw['id']}]: $e');
      }
    }
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _listOf(
      Map<String, dynamic> data, String key) {
    final raw = data[key];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

// ---------------------------------------------------------------------------
// Entity serializers (JSON ↔ domain entity)
// ---------------------------------------------------------------------------
//
// These are intentionally kept private to this file. The canonical backup
// JSON format is defined here; use ExportDatabaseUseCase to produce it.
//
// JSON field names intentionally mirror the entity property names so that
// debugging a raw backup file requires no additional documentation.

DateTime _parseDate(dynamic v) =>
    v is String ? DateTime.parse(v) : DateTime.fromMillisecondsSinceEpoch(0);

DateTime? _parseDateOrNull(dynamic v) => v is String ? DateTime.parse(v) : null;

double _parseDouble(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
double? _parseDoubleOrNull(dynamic v) =>
    v == null ? null : (v as num).toDouble();
int _parseInt(dynamic v) => (v as num?)?.toInt() ?? 0;
int? _parseIntOrNull(dynamic v) => v == null ? null : (v as num).toInt();
bool _parseBool(dynamic v) => v as bool? ?? false;
String _parseStr(dynamic v) => v as String? ?? '';
String? _parseStrOrNull(dynamic v) => v as String?;

// ── Account ─────────────────────────────────────────────────────────────────

abstract final class _AccountSerializer {
  static Map<String, dynamic> toJson(Account e) => {
        'id': e.id,
        'name': e.name,
        'type': e.type.name,
        'currentBalance': e.currentBalance.amount,
        'currency': e.currency,
        'isArchived': e.isArchived,
        'color': e.color,
        'icon': e.icon,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };

  static Account fromJson(Map<String, dynamic> j) => Account(
        id: _parseStr(j['id']),
        name: _parseStr(j['name']),
        type: AccountType.values.byName(_parseStr(j['type'])),
        currentBalance: Money.fromDouble(_parseDouble(j['currentBalance'])),
        currency:
            _parseStr(j['currency']).isEmpty ? 'BRL' : _parseStr(j['currency']),
        isArchived: _parseBool(j['isArchived']),
        color: _parseInt(j['color']),
        icon: _parseStr(j['icon']).isEmpty
            ? 'account_balance'
            : _parseStr(j['icon']),
        createdAt: _parseDate(j['createdAt']),
        updatedAt: _parseDate(j['updatedAt']),
      );
}

// ── Transaction ──────────────────────────────────────────────────────────────

abstract final class _TransactionSerializer {
  static Map<String, dynamic> toJson(Transaction e) => {
        'id': e.id,
        'accountId': e.accountId,
        'type': e.type.name,
        'amount': e.amount.amount,
        'description': e.description,
        'date': e.date.toUtc().toIso8601String(),
        'categoryId': e.categoryId,
        'billId': e.billId,
        'isRecurring': e.isRecurring,
        'recurrenceGroupId': e.recurrenceGroupId,
        'notes': e.notes,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };

  static Transaction fromJson(Map<String, dynamic> j) => Transaction(
        id: _parseStr(j['id']),
        accountId: _parseStr(j['accountId']),
        type: TransactionType.values.byName(_parseStr(j['type'])),
        amount: Money.fromDouble(_parseDouble(j['amount'])),
        description: _parseStr(j['description']),
        date: _parseDate(j['date']),
        categoryId: _parseStrOrNull(j['categoryId']),
        billId: _parseStrOrNull(j['billId']),
        isRecurring: _parseBool(j['isRecurring']),
        recurrenceGroupId: _parseStrOrNull(j['recurrenceGroupId']),
        notes: _parseStrOrNull(j['notes']),
        createdAt: _parseDate(j['createdAt']),
        updatedAt: _parseDate(j['updatedAt']),
      );
}

// ── Bill ─────────────────────────────────────────────────────────────────────

abstract final class _BillSerializer {
  static Map<String, dynamic> toJson(Bill e) => {
        'id': e.id,
        'title': e.title,
        'amount': e.amount.amount,
        'dueDate': e.dueDate.toUtc().toIso8601String(),
        'status': e.status.name,
        'accountId': e.accountId,
        'categoryId': e.categoryId,
        'barcode': e.barcode?.value,
        'pixCode': e.pixCode?.value,
        'beneficiary': e.beneficiary,
        'issuer': e.issuer,
        'documentType': e.documentType?.name,
        'isRecurring': e.isRecurring,
        'recurrenceRule': e.recurrenceRule,
        'paidAt': e.paidAt?.toUtc().toIso8601String(),
        'paidAmount': e.paidAmount?.amount,
        'reminderDaysBefore': e.reminderDaysBefore,
        'notes': e.notes,
        'attachmentPath': e.attachmentPath,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };

  static Bill fromJson(Map<String, dynamic> j) {
    final docTypeStr = _parseStrOrNull(j['documentType']);
    final barcodeStr = _parseStrOrNull(j['barcode']);
    final pixCodeStr = _parseStrOrNull(j['pixCode']);
    final paidAmountVal = _parseDoubleOrNull(j['paidAmount']);

    return Bill(
      id: _parseStr(j['id']),
      title: _parseStr(j['title']),
      amount: Money.fromDouble(_parseDouble(j['amount'])),
      dueDate: _parseDate(j['dueDate']),
      status: BillStatus.fromString(_parseStr(j['status'])),
      accountId: _parseStrOrNull(j['accountId']),
      categoryId: _parseStrOrNull(j['categoryId']),
      barcode: barcodeStr != null ? Barcode(barcodeStr) : null,
      pixCode: pixCodeStr != null ? PixCode(pixCodeStr) : null,
      beneficiary: _parseStrOrNull(j['beneficiary']),
      issuer: _parseStrOrNull(j['issuer']),
      documentType:
          docTypeStr != null ? BillDocumentType.fromString(docTypeStr) : null,
      isRecurring: _parseBool(j['isRecurring']),
      recurrenceRule: _parseStrOrNull(j['recurrenceRule']),
      paidAt: _parseDateOrNull(j['paidAt']),
      paidAmount:
          paidAmountVal != null ? Money.fromDouble(paidAmountVal) : null,
      reminderDaysBefore: _parseInt(j['reminderDaysBefore']),
      notes: _parseStrOrNull(j['notes']),
      attachmentPath: _parseStrOrNull(j['attachmentPath']),
      createdAt: _parseDate(j['createdAt']),
      updatedAt: _parseDate(j['updatedAt']),
    );
  }
}

// ── Fund ─────────────────────────────────────────────────────────────────────

abstract final class _FundSerializer {
  static Map<String, dynamic> toJson(Fund e) => {
        'id': e.id,
        'name': e.name,
        'type': e.type.name,
        'targetAmount': e.targetAmount.amount,
        'currentAmount': e.currentAmount.amount,
        'color': e.color,
        'icon': e.icon,
        'isCompleted': e.isCompleted,
        'targetDate': e.targetDate?.toUtc().toIso8601String(),
        'notes': e.notes,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };

  static Fund fromJson(Map<String, dynamic> j) => Fund(
        id: _parseStr(j['id']),
        name: _parseStr(j['name']),
        type: FundType.fromString(_parseStr(j['type'])),
        targetAmount: Money.fromDouble(_parseDouble(j['targetAmount'])),
        currentAmount: Money.fromDouble(_parseDouble(j['currentAmount'])),
        color: _parseInt(j['color']),
        icon: _parseStr(j['icon']).isEmpty ? 'savings' : _parseStr(j['icon']),
        isCompleted: _parseBool(j['isCompleted']),
        targetDate: _parseDateOrNull(j['targetDate']),
        notes: _parseStrOrNull(j['notes']),
        createdAt: _parseDate(j['createdAt']),
        updatedAt: _parseDate(j['updatedAt']),
      );
}

// ── Debt ─────────────────────────────────────────────────────────────────────

abstract final class _DebtSerializer {
  static Map<String, dynamic> toJson(Debt e) => {
        'id': e.id,
        'creditorName': e.creditorName,
        'totalAmount': e.totalAmount.amount,
        'remainingAmount': e.remainingAmount.amount,
        'installments': e.installments,
        'installmentsPaid': e.installmentsPaid,
        'installmentAmount': e.installmentAmount?.amount,
        'interestRate': e.interestRate,
        'startDate': e.startDate.toUtc().toIso8601String(),
        'expectedEndDate': e.expectedEndDate?.toUtc().toIso8601String(),
        'status': e.status.name,
        'notes': e.notes,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
        'updatedAt': e.updatedAt.toUtc().toIso8601String(),
      };

  static Debt fromJson(Map<String, dynamic> j) {
    final installmentAmountVal = _parseDoubleOrNull(j['installmentAmount']);
    return Debt(
      id: _parseStr(j['id']),
      creditorName: _parseStr(j['creditorName']),
      totalAmount: Money.fromDouble(_parseDouble(j['totalAmount'])),
      remainingAmount: Money.fromDouble(_parseDouble(j['remainingAmount'])),
      installments: _parseIntOrNull(j['installments']),
      installmentsPaid: _parseInt(j['installmentsPaid']),
      installmentAmount: installmentAmountVal != null
          ? Money.fromDouble(installmentAmountVal)
          : null,
      interestRate: _parseDoubleOrNull(j['interestRate']),
      startDate: _parseDate(j['startDate']),
      expectedEndDate: _parseDateOrNull(j['expectedEndDate']),
      status: DebtStatus.fromString(_parseStr(j['status'])),
      notes: _parseStrOrNull(j['notes']) ?? '',
      createdAt: _parseDate(j['createdAt']),
      updatedAt: _parseDate(j['updatedAt']),
    );
  }
}

// ── Category ─────────────────────────────────────────────────────────────────

abstract final class _CategorySerializer {
  static Map<String, dynamic> toJson(Category e) => {
        'id': e.id,
        'name': e.name,
        'type': e.type.name,
        'icon': e.icon,
        'color': e.color,
        'isDefault': e.isDefault,
        'parentId': e.parentId,
        'createdAt': e.createdAt.toUtc().toIso8601String(),
      };

  static Category fromJson(Map<String, dynamic> j) => Category(
        id: _parseStr(j['id']),
        name: _parseStr(j['name']),
        type: CategoryType.values.byName(_parseStr(j['type'])),
        icon: _parseStr(j['icon']),
        color: _parseInt(j['color']),
        isDefault: _parseBool(j['isDefault']),
        parentId: _parseStrOrNull(j['parentId']),
        createdAt: _parseDate(j['createdAt']),
      );
}

// ---------------------------------------------------------------------------
// EntitySerializers — public re-export for ExportDatabaseUseCase
// ---------------------------------------------------------------------------

/// Public façade over the private serializers for use by [ExportDatabaseUseCase].
abstract final class EntitySerializers {
  static Map<String, dynamic> accountToJson(Account e) =>
      _AccountSerializer.toJson(e);
  static Map<String, dynamic> transactionToJson(Transaction e) =>
      _TransactionSerializer.toJson(e);
  static Map<String, dynamic> billToJson(Bill e) => _BillSerializer.toJson(e);
  static Map<String, dynamic> fundToJson(Fund e) => _FundSerializer.toJson(e);
  static Map<String, dynamic> debtToJson(Debt e) => _DebtSerializer.toJson(e);
  static Map<String, dynamic> categoryToJson(Category e) =>
      _CategorySerializer.toJson(e);
}
