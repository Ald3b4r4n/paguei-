import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

abstract interface class TransactionRepository {
  Future<List<Transaction>> getByMonth({required int year, required int month});

  Future<List<Transaction>> getByAccount(String accountId);

  Future<List<Transaction>> getByCategory(String categoryId);

  Future<List<Transaction>> getByDateRange({
    required DateTime start,
    required DateTime end,
  });

  Future<Transaction?> getById(String id);

  Stream<List<Transaction>> watchByMonth(
      {required int year, required int month});

  Future<Transaction> create({
    required String id,
    required String accountId,
    required TransactionType type,
    required Money amount,
    required String description,
    required DateTime date,
    String? categoryId,
    String? billId,
    bool isRecurring,
    String? recurrenceGroupId,
    String? notes,
  });

  /// Creates a transfer: debits [fromAccountId], credits [toAccountId], inserts Transfer record.
  Future<Transaction> createTransfer({
    required String id,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required String description,
    required DateTime date,
    String? notes,
  });

  Future<Transaction> update(Transaction transaction);

  Future<void> delete(String id);

  Future<Money> getMonthlySummary({
    required int year,
    required int month,
    TransactionType? type,
    String? accountId,
  });
}
