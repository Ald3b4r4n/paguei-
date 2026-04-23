import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class Fund {
  const Fund({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.currentAmount,
    required this.color,
    required this.icon,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.targetDate,
    this.notes,
  });

  factory Fund.create({
    required String id,
    required String name,
    required FundType type,
    required Money targetAmount,
    required int color,
    required String icon,
    DateTime? targetDate,
    String? notes,
  }) {
    if (name.trim().isEmpty) {
      throw const ValidationException(
          message: 'Nome do fundo não pode ser vazio.');
    }
    if (name.length > 100) {
      throw const ValidationException(
          message: 'Nome do fundo não pode ter mais de 100 caracteres.');
    }
    if (!targetAmount.isPositive) {
      throw const ValidationException(
          message: 'Meta do fundo deve ser maior que zero.');
    }

    final now = DateTime.now().toUtc();
    return Fund(
      id: id,
      name: name,
      type: type,
      targetAmount: targetAmount,
      currentAmount: Money.zero,
      color: color,
      icon: icon,
      isCompleted: false,
      targetDate: targetDate,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String name;
  final FundType type;
  final Money targetAmount;
  final Money currentAmount;
  final int color;
  final String icon;
  final bool isCompleted;
  final DateTime? targetDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progressRate {
    if (targetAmount.isZero) return 0.0;
    final rate = currentAmount.cents / targetAmount.cents;
    return rate.clamp(0.0, 1.0);
  }

  Money get remainingToGoal {
    final remaining = targetAmount - currentAmount;
    return remaining.isNegative ? Money.zero : remaining;
  }

  Fund contribute(Money amount) {
    if (!amount.isPositive) {
      throw const ValidationException(
          message: 'Valor de aporte deve ser maior que zero.');
    }
    final newAmount = currentAmount + amount;
    return copyWith(
      currentAmount: newAmount,
      isCompleted: newAmount >= targetAmount,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Fund withdraw(Money amount) {
    if (!amount.isPositive) {
      throw const ValidationException(
          message: 'Valor de retirada deve ser maior que zero.');
    }
    if (amount > currentAmount) {
      throw const ValidationException(
          message: 'Valor de retirada não pode exceder o saldo do fundo.');
    }
    final newAmount = currentAmount - amount;
    return copyWith(
      currentAmount: newAmount,
      isCompleted: newAmount >= targetAmount,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Fund copyWith({
    String? id,
    String? name,
    FundType? type,
    Money? targetAmount,
    Money? currentAmount,
    int? color,
    String? icon,
    bool? isCompleted,
    DateTime? targetDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Fund(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      targetDate: targetDate ?? this.targetDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Fund && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Fund(id: $id, name: $name, type: $type)';
}
