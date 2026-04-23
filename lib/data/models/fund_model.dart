import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/fund.dart';
import 'package:paguei/domain/entities/fund_type.dart';
import 'package:paguei/domain/value_objects/money.dart';

extension FundModelMapper on FundsTableData {
  Fund toDomain() {
    return Fund(
      id: id,
      name: name,
      type: FundType.fromString(type),
      targetAmount: Money.fromDouble(targetAmount),
      currentAmount: Money.fromDouble(currentAmount),
      color: color,
      icon: icon,
      isCompleted: isCompleted,
      targetDate: targetDate,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension FundToCompanion on Fund {
  FundsTableCompanion toCompanion() {
    return FundsTableCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type.name),
      targetAmount: Value(targetAmount.amount),
      currentAmount: Value(currentAmount.amount),
      color: Value(color),
      icon: Value(icon),
      isCompleted: Value(isCompleted),
      targetDate: Value(targetDate),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
