import 'package:drift/drift.dart' show Value;
import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/data/database/daos/accounts_dao.dart';
import 'package:paguei/data/database/daos/transactions_dao.dart';
import 'package:paguei/data/models/transaction_model.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/repositories/transaction_repository.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:uuid/uuid.dart';

final class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._dao, this._accountsDao);

  final TransactionsDao _dao;
  final AccountsDao _accountsDao;

  @override
  Future<List<Transaction>> getByMonth({
    required int year,
    required int month,
  }) async {
    final rows = await _dao.getByMonth(year: year, month: month);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Transaction>> getByAccount(String accountId) async {
    final rows = await _dao.getByAccount(accountId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Transaction>> getByCategory(String categoryId) async {
    final rows = await _dao.getByCategory(categoryId);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<List<Transaction>> getByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _dao.getByDateRange(start: start, end: end);
    return rows.map((r) => r.toDomain()).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final row = await _dao.getById(id);
    return row?.toDomain();
  }

  @override
  Stream<List<Transaction>> watchByMonth({
    required int year,
    required int month,
  }) {
    return _dao
        .watchByMonth(year: year, month: month)
        .map((rows) => rows.map((r) => r.toDomain()).toList());
  }

  @override
  Future<Transaction> create({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? billId,
    bool isRecurring = false,
    String? recurrenceGroupId,
    String? notes,
  }) async {
    final transaction = Transaction.create(
      id: id,
      accountId: accountId,
      type: type,
      amount: amount,
      description: description,
      date: date,
      categoryId: categoryId,
      billId: billId,
      isRecurring: isRecurring,
      recurrenceGroupId: recurrenceGroupId,
      notes: notes,
    );

    await _dao.attachedDatabase.transaction(() async {
      await _dao.insertTransaction(transaction.toCompanion());
      await _applyBalanceEffect(accountId, transaction.balanceEffect);
    });

    return transaction;
  }

  @override
  Future<Transaction> createTransfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  }) async {
    if (fromAccountId == toAccountId) {
      throw const ValidationException(
        message: 'Conta de origem e destino devem ser diferentes.',
      );
    }

    final transaction = Transaction.create(
      id: id,
      accountId: fromAccountId,
      type: TransactionType.transfer,
      amount: amount,
      description: description,
      date: date,
      notes: notes,
    );

    await _dao.attachedDatabase.transaction(() async {
      await _dao.insertTransaction(transaction.toCompanion());

      await _dao.attachedDatabase
          .into(_dao.attachedDatabase.transfersTable)
          .insert(
            TransfersTableCompanion.insert(
              id: const Uuid().v4(),
              fromAccountId: fromAccountId,
              toAccountId: toAccountId,
              transactionId: id,
              amount: amount.amount,
              date: date,
              notes: Value(notes),
              createdAt: DateTime.now().toUtc(),
            ),
          );

      // Debit from source, credit to destination
      await _applyBalanceEffect(fromAccountId, -amount);
      await _applyBalanceEffect(toAccountId, amount);
    });

    return transaction;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final existing = await _dao.getById(transaction.id);
    if (existing == null) {
      throw NotFoundException(
        message: 'Transação não encontrada: ${transaction.id}',
      );
    }

    final oldTransaction = existing.toDomain();
    final deltaEffect =
        transaction.balanceEffect - oldTransaction.balanceEffect;

    await _dao.attachedDatabase.transaction(() async {
      await _dao.updateTransaction(transaction.toCompanion());
      if (deltaEffect != Money.zero) {
        await _applyBalanceEffect(transaction.accountId, deltaEffect);
      }
    });

    return transaction;
  }

  @override
  Future<void> delete(String id) async {
    final existing = await _dao.getById(id);
    if (existing == null) return;

    final transaction = existing.toDomain();

    await _dao.attachedDatabase.transaction(() async {
      await _dao.deleteTransaction(id);
      // Reverse the balance effect
      await _applyBalanceEffect(
          transaction.accountId, -transaction.balanceEffect);
    });
  }

  @override
  Future<Money> getMonthlySummary({
    required int year,
    required int month,
    TransactionType? type,
    String? accountId,
  }) async {
    if (type == null) {
      final income = await _dao.sumByType(
        year: year,
        month: month,
        type: TransactionType.income.name,
        accountId: accountId,
      );
      final expense = await _dao.sumByType(
        year: year,
        month: month,
        type: TransactionType.expense.name,
        accountId: accountId,
      );
      return Money.fromDouble(income - expense);
    }
    final total = await _dao.sumByType(
      year: year,
      month: month,
      type: type.name,
      accountId: accountId,
    );
    return Money.fromDouble(total);
  }

  Future<void> _applyBalanceEffect(String accountId, Money delta) async {
    if (delta == Money.zero) return;
    final account = await _accountsDao.getById(accountId);
    if (account == null) {
      throw NotFoundException(
        message: 'Local do dinheiro não encontrado: $accountId',
      );
    }
    final newBalance = account.currentBalanceCents + delta.cents;
    await _accountsDao.adjustBalanceCents(accountId, newBalance);
  }
}
