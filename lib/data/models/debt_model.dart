import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/debt.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

extension DebtModelMapper on DebtsTableData {
  Debt toDomain() {
    return Debt(
      id: id,
      creditorName: creditorName,
      totalAmount: Money.fromDouble(totalAmount),
      remainingAmount: Money.fromDouble(remainingAmount),
      installments: installments,
      installmentsPaid: installmentsPaid,
      installmentAmount: installmentAmount != null
          ? Money.fromDouble(installmentAmount!)
          : null,
      interestRate: interestRate,
      startDate: startDate,
      expectedEndDate: expectedEndDate,
      status: DebtStatus.fromString(status),
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension DebtToCompanion on Debt {
  DebtsTableCompanion toCompanion() {
    return DebtsTableCompanion(
      id: Value(id),
      creditorName: Value(creditorName),
      totalAmount: Value(totalAmount.amount),
      remainingAmount: Value(remainingAmount.amount),
      installments: Value(installments),
      installmentsPaid: Value(installmentsPaid),
      installmentAmount: Value(installmentAmount?.amount),
      interestRate: Value(interestRate),
      startDate: Value(startDate),
      expectedEndDate: Value(expectedEndDate),
      status: Value(status.name),
      notes: Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
