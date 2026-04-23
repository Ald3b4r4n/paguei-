import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/transaction_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class Transaction {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.billId,
    this.recurrenceGroupId,
    this.notes,
  });

  factory Transaction.create({
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
  }) {
    if (!amount.isPositive) {
      throw const ValidationException(
          message: 'Valor da transação deve ser maior que zero.');
    }
    if (description.trim().isEmpty) {
      throw const ValidationException(
          message: 'Descrição da transação não pode ser vazia.');
    }
    if (description.length > 255) {
      throw const ValidationException(
          message: 'Descrição não pode ter mais de 255 caracteres.');
    }

    final now = DateTime.now().toUtc();
    return Transaction(
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
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String accountId;
  final TransactionType type;
  final Money amount;
  final String description;
  final DateTime date;
  final String? categoryId;
  final String? billId;
  final bool isRecurring;
  final String? recurrenceGroupId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns the signed effect on balance: positive for income, negative for expense.
  /// Transfers are handled externally via the Transfer entity.
  Money get balanceEffect => switch (type) {
        TransactionType.income => amount,
        TransactionType.expense => -amount,
        TransactionType.transfer => Money.zero,
      };

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    Money? amount,
    String? description,
    DateTime? date,
    String? categoryId,
    String? billId,
    bool? isRecurring,
    String? recurrenceGroupId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      billId: billId ?? this.billId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Transaction && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Transaction(id: $id, type: $type, amount: $amount)';
}
