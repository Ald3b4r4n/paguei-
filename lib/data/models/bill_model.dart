import 'package:drift/drift.dart' show Value;
import 'package:paguei/data/database/app_database.dart';
import 'package:paguei/domain/entities/bill.dart';
import 'package:paguei/domain/entities/bill_document_type.dart';
import 'package:paguei/domain/entities/bill_status.dart';
import 'package:paguei/domain/value_objects/barcode.dart';
import 'package:paguei/domain/value_objects/money.dart';
import 'package:paguei/domain/value_objects/pix_code.dart';

extension BillModelMapper on BillsTableData {
  Bill toDomain() {
    return Bill(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      title: title,
      amount: Money.fromDouble(amount),
      dueDate: dueDate,
      status: BillStatus.fromString(status),
      barcode: barcode != null ? Barcode(barcode!) : null,
      pixCode: pixCode != null ? PixCode(pixCode!) : null,
      beneficiary: beneficiary,
      issuer: issuer,
      documentType: documentType != null
          ? BillDocumentType.fromString(documentType!)
          : null,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      paidAt: paidAt,
      paidAmount: paidAmount != null ? Money.fromDouble(paidAmount!) : null,
      reminderDaysBefore: reminderDaysBefore,
      notes: notes,
      attachmentPath: attachmentPath,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension BillToCompanion on Bill {
  BillsTableCompanion toCompanion() {
    return BillsTableCompanion(
      id: Value(id),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      title: Value(title),
      amount: Value(amount.amount),
      dueDate: Value(dueDate),
      status: Value(status.name),
      barcode: Value(barcode?.value),
      pixCode: Value(pixCode?.value),
      beneficiary: Value(beneficiary),
      issuer: Value(issuer),
      documentType: Value(documentType?.name),
      isRecurring: Value(isRecurring),
      recurrenceRule: Value(recurrenceRule),
      paidAt: Value(paidAt),
      paidAmount: Value(paidAmount?.amount),
      reminderDaysBefore: Value(reminderDaysBefore),
      notes: Value(notes),
      attachmentPath: Value(attachmentPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
