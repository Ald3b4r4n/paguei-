import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/debt_status.dart';
import 'package:paguei/domain/value_objects/money.dart';

final class Debt {
  const Debt({
    required this.id,
    required this.creditorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.installments,
    required this.installmentsPaid,
    required this.installmentAmount,
    required this.interestRate,
    required this.startDate,
    required this.expectedEndDate,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Debt.create({
    required String id,
    required String creditorName,
    required Money totalAmount,
    int? installments,
    Money? installmentAmount,
    double? interestRate,
    DateTime? expectedEndDate,
    String? notes,
  }) {
    if (creditorName.trim().isEmpty) {
      throw const ValidationException(
          message: 'Nome do credor não pode ser vazio.');
    }
    if (creditorName.length > 150) {
      throw const ValidationException(
          message: 'Nome do credor não pode ter mais de 150 caracteres.');
    }
    if (!totalAmount.isPositive) {
      throw const ValidationException(
          message: 'Valor total da dívida deve ser maior que zero.');
    }
    if (installmentAmount != null && installmentAmount.isNegative) {
      throw const ValidationException(
          message: 'Valor da parcela não pode ser negativo.');
    }

    final now = DateTime.now().toUtc();
    return Debt(
      id: id,
      creditorName: creditorName,
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      installments: installments,
      installmentsPaid: 0,
      installmentAmount: installmentAmount,
      interestRate: interestRate,
      startDate: now,
      expectedEndDate: expectedEndDate,
      status: DebtStatus.active,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String creditorName;
  final Money totalAmount;
  final Money remainingAmount;
  final int? installments;
  final int installmentsPaid;
  final Money? installmentAmount;
  final double? interestRate;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final DebtStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get dueDay => startDate.day;

  int? get installmentsRemaining {
    if (installments == null) return null;
    return (installments! - installmentsPaid).clamp(0, installments!);
  }

  double get progressRate {
    if (totalAmount.isZero) return 0.0;
    final paid = (totalAmount - remainingAmount).cents;
    return (paid / totalAmount.cents).clamp(0.0, 1.0);
  }

  Debt registerPayment(Money amount) {
    if (!amount.isPositive) {
      throw const ValidationException(
          message: 'Valor do pagamento deve ser maior que zero.');
    }
    if (amount > remainingAmount) {
      throw const ValidationException(
          message: 'Valor do pagamento não pode exceder o saldo devedor.');
    }

    final newRemaining = remainingAmount - amount;
    final newPaid = installmentsPaid + 1;
    final isFullyPaid = newRemaining.isZero;

    return copyWith(
      remainingAmount: newRemaining,
      installmentsPaid: newPaid,
      status: isFullyPaid ? DebtStatus.paid : status,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Debt copyWith({
    String? id,
    String? creditorName,
    Money? totalAmount,
    Money? remainingAmount,
    int? installments,
    int? installmentsPaid,
    Money? installmentAmount,
    double? interestRate,
    DateTime? startDate,
    DateTime? expectedEndDate,
    DebtStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Debt(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      installments: installments ?? this.installments,
      installmentsPaid: installmentsPaid ?? this.installmentsPaid,
      installmentAmount: installmentAmount ?? this.installmentAmount,
      interestRate: interestRate ?? this.interestRate,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Debt && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Debt(id: $id, creditor: $creditorName, status: $status)';
}
