import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/transaction.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

extension TransactionModelMapper on TransactionsTableData {
  Transaction toDomain() {
    return Transaction(
      id: id,
      accountId: accountId,
      type: _transactionTypeFromString(type),
      amount: Money.fromDouble(amount),
      description: description,
      date: date,
      categoryId: categoryId,
      billId: billId,
      isRecurring: isRecurring,
      recurrenceGroupId: recurrenceGroupId,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension TransactionToCompanion on Transaction {
  TransactionsTableCompanion toCompanion() {
    return TransactionsTableCompanion.insert(
      id: id,
      accountId: accountId,
      type: type.name,
      amount: amount.amount, // double (store as real)
      description: description,
      date: date,
      categoryId: Value(categoryId),
      billId: Value(billId),
      isRecurring: Value(isRecurring),
      recurrenceGroupId: Value(recurrenceGroupId),
      notes: Value(notes),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

TransactionType _transactionTypeFromString(String value) {
  return TransactionType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TransactionType.expense,
  );
}
