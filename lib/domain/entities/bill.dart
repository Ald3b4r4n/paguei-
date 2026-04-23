import 'package:paguei/core/errors/exceptions.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

final class Bill {
  const Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.isRecurring,
    required this.reminderDaysBefore,
    required this.createdAt,
    required this.updatedAt,
    this.accountId,
    this.categoryId,
    this.barcode,
    this.pixCode,
    this.beneficiary,
    this.issuer,
    this.documentType,
    this.recurrenceRule,
    this.paidAt,
    this.paidAmount,
    this.notes,
    this.attachmentPath,
  });

  factory Bill.create({
    required String id,
    required String title,
    required Money amount,
    required DateTime dueDate,
    String? accountId,
    String? categoryId,
    Barcode? barcode,
    PixCode? pixCode,
    String? beneficiary,
    String? issuer,
    BillDocumentType? documentType,
    bool isRecurring = false,
    String? recurrenceRule,
    int reminderDaysBefore = 3,
    String? notes,
    String? attachmentPath,
  }) {
    if (title.trim().isEmpty) {
      throw const ValidationException(
          message: 'Título do boleto não pode ser vazio.');
    }
    if (title.length > 150) {
      throw const ValidationException(
        message: 'Título do boleto não pode ter mais de 150 caracteres.',
      );
    }
    if (!amount.isPositive) {
      throw const ValidationException(
          message: 'Valor do boleto deve ser maior que zero.');
    }

    final now = DateTime.now().toUtc();
    return Bill(
      id: id,
      title: title.trim(),
      amount: amount,
      dueDate: dueDate,
      status: BillStatus.pending,
      accountId: accountId,
      categoryId: categoryId,
      barcode: barcode,
      pixCode: pixCode,
      beneficiary: beneficiary,
      issuer: issuer,
      documentType: documentType,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes,
      attachmentPath: attachmentPath,
      createdAt: now,
      updatedAt: now,
    );
  }

  final String id;
  final String? accountId;
  final String? categoryId;
  final String title;
  final Money amount;
  final DateTime dueDate;
  final BillStatus status;
  final Barcode? barcode;
  final PixCode? pixCode;
  final String? beneficiary;
  final String? issuer;
  final BillDocumentType? documentType;
  final bool isRecurring;
  final String? recurrenceRule;
  final DateTime? paidAt;
  final Money? paidAmount;
  final int reminderDaysBefore;
  final String? notes;
  final String? attachmentPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed status: pending bills past their due date are considered overdue.
  BillStatus get effectiveStatus {
    if (status == BillStatus.pending &&
        dueDate.isBefore(DateTime.now().toUtc())) {
      return BillStatus.overdue;
    }
    return status;
  }

  bool get isPaid => status == BillStatus.paid;
  bool get isCancelled => status == BillStatus.cancelled;
  bool get isPending => effectiveStatus == BillStatus.pending;
  bool get isOverdue => effectiveStatus == BillStatus.overdue;

  Bill copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? title,
    Money? amount,
    DateTime? dueDate,
    BillStatus? status,
    Barcode? barcode,
    PixCode? pixCode,
    String? beneficiary,
    String? issuer,
    BillDocumentType? documentType,
    bool? isRecurring,
    String? recurrenceRule,
    DateTime? paidAt,
    Money? paidAmount,
    int? reminderDaysBefore,
    String? notes,
    String? attachmentPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      pixCode: pixCode ?? this.pixCode,
      beneficiary: beneficiary ?? this.beneficiary,
      issuer: issuer ?? this.issuer,
      documentType: documentType ?? this.documentType,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      paidAt: paidAt ?? this.paidAt,
      paidAmount: paidAmount ?? this.paidAmount,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Bill && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Bill(id: $id, title: $title, amount: $amount, status: $status)';
}
